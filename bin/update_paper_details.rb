#!/usr/bin/env ruby

# Enriches the canonical paper data with abstracts and direct PDF links.
#
# Legacy paper pages consistently expose an Abstract list item and a Paper
# list item, but a few pages contain malformed HTML. This importer repairs the
# known comparison-sign markup before parsing and avoids absorbing nested list
# items into an abstract. Existing enrichment is retained whenever a source
# cannot be fetched or a field cannot be extracted.

require "json"
require "nokogiri"
require "open-uri"
require "uri"

ROOT = File.expand_path("..", __dir__)
DATA_PATH = File.join(ROOT, "_data", "papers.json")
LEGACY_DETAIL_PATTERN = %r{\Ahttps?://www-stat\.wharton\.upenn\.edu/~tcai/paper/html/}i
PDF_PATTERN = /\.pdf(?:[?#]|\z)/i
ARXIV_ABSTRACT_PATTERN = %r{\Ahttps?://(?:www\.)?arxiv\.org/abs/([^/?#]+)}i
USER_AGENT = "Tony Cai website paper-details importer"
THREAD_COUNT = Integer(ENV.fetch("TCAI_PAPER_DETAIL_THREADS", "12"), 10)

PDF_URL_OVERRIDES = {
  "http://www-stat.wharton.upenn.edu/~tcai/paper/html/FL-PCA.html" => "https://arxiv.org/pdf/2411.15660",
  "http://www-stat.wharton.upenn.edu/~tcai/paper/html/Multiple-Testing-Review.html" => "http://www-stat.wharton.upenn.edu/~tcai/paper/FDR-Review.pdf",
  "http://www-stat.wharton.upenn.edu/~tcai/paper/html/Sharp-Block.html" => "https://faculty.wharton.upenn.edu/wp-content/uploads/2012/04/SharpAdaptiveEstimation.pdf",
}.freeze

ABSTRACT_URL_OVERRIDES = {
  "http://www-stat.wharton.upenn.edu/~tcai/paper/html/Wishart-Concentration.html" => "https://arxiv.org/abs/2008.12434",
}.freeze

KNOWN_UNAVAILABLE_PDF_URLS = [
  "http://www-stat.wharton.upenn.edu/~tcai/paper/Discussion-of-FDR-GLM.pdf",
].freeze

def normalize_text(value)
  value.to_s
    .unicode_normalize(:nfkc)
    .tr("\u00A0", " ")
    .gsub(/[[:space:]]+/, " ")
    .strip
end

def read_source(url)
  URI.open(
    url,
    "User-Agent" => USER_AGENT,
    open_timeout: 15,
    read_timeout: 30,
    &:read
  ).force_encoding("UTF-8").scrub
end

def parse_legacy_detail(url, html)
  # Several abstracts contain literal comparisons such as "< 1". Without
  # escaping, an HTML parser treats these as malformed opening tags and drops
  # the inequality from the extracted text.
  repaired_html = html.gsub(/<(?=\s*[+-]?(?:\d|\.\d))/, "&lt;")
  document = Nokogiri::HTML(repaired_html, url, "UTF-8")
  list_items = document.css("li")

  abstract_item = list_items.find { |item| normalize_text(item.text).match?(/\AAbstract\s*:/i) }
  abstract = if abstract_item
               copy = abstract_item.dup
               # NewRIPBounds.html nests the Paper and related-paper items
               # inside the Abstract item after Nokogiri repairs its markup.
               copy.css("li, script, style").remove
               normalize_text(copy.text).sub(/\AAbstract\s*:\s*/i, "").strip
             end
  abstract = nil if abstract&.empty?

  paper_item = list_items.find do |item|
    normalize_text(item.text).match?(/\APaper(?:\s+with\s+discussion)?\s*:/i)
  end
  pdf_anchor = paper_item&.css("a[href]")&.find { |anchor| anchor["href"].match?(PDF_PATTERN) }
  pdf_url = URI.join(url, pdf_anchor["href"]).to_s if pdf_anchor

  warnings = []
  warnings << "no text abstract (the legacy page may use an image)" unless abstract
  warnings << "no primary PDF link in the Paper item" unless pdf_url

  { abstract: abstract, pdf_url: pdf_url, warnings: warnings }
end

def parse_arxiv_abstract(url, html)
  document = Nokogiri::HTML(html, url, "UTF-8")
  metadata = document.at_css('meta[name="citation_abstract"]')&.[]("content")
  abstract = normalize_text(metadata)
  return abstract unless abstract.empty?

  block = document.at_css("blockquote.abstract")
  return nil unless block

  copy = block.dup
  copy.css(".descriptor, script, style").remove
  abstract = normalize_text(copy.text).sub(/\AAbstract\s*:\s*/i, "").strip
  abstract unless abstract.empty?
end

def enrichment_for(paper)
  source_url = paper["url"].to_s.strip
  return { kind: :missing_source, warnings: ["no source URL"] } if source_url.empty?

  if KNOWN_UNAVAILABLE_PDF_URLS.include?(source_url)
    return {
      kind: :unavailable_pdf,
      remove_pdf_url: true,
      warnings: ["the legacy PDF is missing and no open authoritative replacement is available"],
    }
  end

  if source_url.match?(PDF_PATTERN)
    return { kind: :direct_pdf, pdf_url: source_url, warnings: [] }
  end

  if (match = source_url.match(ARXIV_ABSTRACT_PATTERN))
    result = {
      kind: :arxiv,
      pdf_url: "https://arxiv.org/pdf/#{match[1]}",
      warnings: [],
    }
    begin
      result[:abstract] = parse_arxiv_abstract(source_url, read_source(source_url))
      result[:warnings] << "no abstract found on the arXiv page" unless result[:abstract]
    rescue StandardError => error
      result[:error] = "#{error.class}: #{error.message}"
    end
    return result
  end

  unless source_url.match?(LEGACY_DETAIL_PATTERN)
    return { kind: :unsupported, warnings: ["unsupported source URL: #{source_url}"] }
  end

  result = parse_legacy_detail(source_url, read_source(source_url))
  result[:pdf_url] = PDF_URL_OVERRIDES.fetch(source_url) if PDF_URL_OVERRIDES.key?(source_url)

  if !result[:abstract] && ABSTRACT_URL_OVERRIDES.key?(source_url)
    abstract_url = ABSTRACT_URL_OVERRIDES.fetch(source_url)
    result[:abstract] = parse_arxiv_abstract(abstract_url, read_source(abstract_url))
    result[:warnings].delete("no text abstract (the legacy page may use an image)") if result[:abstract]
  end

  result.merge(kind: :legacy_detail)
rescue StandardError => error
  { kind: :legacy_detail, error: "#{error.class}: #{error.message}", warnings: [] }
end

data = JSON.parse(File.read(DATA_PATH))
papers = data.fetch("sections").flat_map { |section| section.fetch("papers") }
results = Array.new(papers.length)
queue = Queue.new
papers.each_with_index { |paper, index| queue << [index, paper] }
worker_count = [[THREAD_COUNT, 1].max, papers.length].min
worker_count.times { queue << nil }

workers = worker_count.times.map do
  Thread.new do
    while (job = queue.pop)
      index, paper = job
      results[index] = enrichment_for(paper)
    end
  end
end
workers.each(&:join)

papers.zip(results).each do |paper, result|
  paper["abstract"] = result[:abstract] if result[:abstract] && !result[:abstract].empty?
  if result[:remove_pdf_url]
    paper.delete("pdf_url")
  elsif result[:pdf_url] && !result[:pdf_url].empty?
    paper["pdf_url"] = result[:pdf_url]
  end
end

File.write(DATA_PATH, JSON.pretty_generate(data) + "\n")

kind_counts = results.group_by { |result| result.fetch(:kind) }.transform_values(&:length)
error_count = results.count { |result| result[:error] }
warning_count = results.sum { |result| result.fetch(:warnings, []).length }
abstract_count = papers.count { |paper| !paper["abstract"].to_s.empty? }
pdf_count = papers.count { |paper| !paper["pdf_url"].to_s.empty? }

warn "Processed #{papers.length} papers with #{worker_count} workers."
warn "Sources: #{kind_counts.sort.map { |kind, count| "#{kind}=#{count}" }.join(', ')}."
warn "Enrichment: abstracts=#{abstract_count}, PDF links=#{pdf_count}, errors=#{error_count}, warnings=#{warning_count}."

papers.zip(results).each do |paper, result|
  prefix = "#{paper.fetch('id')}:"
  warn "#{prefix} #{result[:error]} (existing enrichment preserved)" if result[:error]
  result.fetch(:warnings, []).each { |warning| warn "#{prefix} #{warning}" }
end
