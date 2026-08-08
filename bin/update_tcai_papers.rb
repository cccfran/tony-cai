#!/usr/bin/env ruby

# Refreshes the website's canonical paper list from Tony Cai's short CV and
# attaches the subject classifications from the legacy papers-by-topic page.
#
# Usage:
#   ruby bin/update_tcai_papers.rb [CV_PDF] [PAPERS_BY_TOPIC_HTML_OR_URL]

require "json"
require "nokogiri"
require "open-uri"
require "open3"
require "set"
require "uri"

ROOT = File.expand_path("..", __dir__)
DEFAULT_CV = File.join(ROOT, "assets", "pdf", "Tony-Cai-CV-short.pdf")
LEGACY_ROOT = "http://www-stat.wharton.upenn.edu/~tcai/"
DEFAULT_TOPICS = URI.join(LEGACY_ROOT, "Papers-by-Topics.html").to_s
CURRENT_DATA = File.join(ROOT, "_data", "papers.json")
OUTPUT_TOPICS = File.join(ROOT, "_data", "paper_topics.json")

VENUE_START = /(?:Advances in|Annals |Annual Review|Applied |Arthritis |Bernoulli|Biometrika|Biometrics|Electronic |IEEE |In |J\. |Journal |Probability |Proc\. |Sankhya|Science |Scientia |Statistica |Statistical |Statistics |Test |The |NeurIPS)/

CV_URL_OVERRIDES = {
  6 => "https://www.sciengine.com/doi/10.1360/SSM-2024-0229",
  40 => URI.join(LEGACY_ROOT, "paper/html/ITE.html").to_s,
  46 => URI.join(LEGACY_ROOT, "paper/html/Eigen-Density-Matrix.html").to_s,
  100 => "https://acrabstracts.org/abstract/phenome-wide-association-study-of-novel-anti-citrullinated-peptide-antibodies-in-rheumatoid-arthritis/",
  116 => URI.join(LEGACY_ROOT, "paper/Discussion-of-Significant-Test-Lasso.pdf").to_s,
  207 => "https://www.routledge.com/Combinatorial-Designs-and-Applications/Nashed-Taft-Wallis/p/book/9780824783945",
  208 => "https://rkyfz.pku.edu.cn/Article/info?aid=278177380",
}.freeze

CV_ITEMS_WITHOUT_LEGACY_URLS = [206].freeze

SECTION_ORDER = [
  ["reports", "Technical Reports"],
  ["2026-plus", "2026+"],
  ["2025", "2025"],
  ["2024", "2024"],
  ["2023", "2023"],
  ["2022", "2022"],
  ["2021", "2021"],
  ["2020", "2020"],
  ["2019", "2019"],
  ["2018", "2018"],
  ["2017", "2017"],
  ["2016", "2016"],
  ["2015", "2015"],
  ["2014-and-earlier", "2014 & Earlier"],
].freeze

def normalize(value)
  value.to_s
    .unicode_normalize(:nfkd)
    .encode("ASCII", invalid: :replace, undef: :replace, replace: "")
    .downcase
    .gsub(/[^a-z0-9]+/, " ")
    .strip
end

TOPIC_TITLE_ALIASES = {
  normalize("Optimal statistical inference for individualized treatment effects in high-dimensional models.") =>
    "Individualized treatment selection: An optimal hypothesis testing approach in high-dimensional models.",
  normalize("Optimal estimation of eigenspace of large density matrices of quantum systems based on Pauli measurements.") =>
    "Optimal sparse eigenspace and low-rank density matrix estimation for quantum systems.",
  normalize('Discussion: "A Significant Test for Lasso".') => 'Comments on “A Significance Test for the Lasso”.',
}.freeze

def title_tokens(value)
  normalize(value).split.reject { |token| token.length == 1 || %w[a an and for in of on the to with].include?(token) }.to_set
end

def similarity(left, right)
  left_tokens = title_tokens(left)
  right_tokens = title_tokens(right)
  return 0.0 if left_tokens.empty? || right_tokens.empty?

  (2.0 * (left_tokens & right_tokens).length) / (left_tokens.length + right_tokens.length)
end

def slug(value)
  normalize(value).tr(" ", "-").gsub(/-+/, "-")
end

def read_source(source)
  raw = if File.file?(source)
          File.binread(source)
        else
          URI.open(source, "User-Agent" => "Tony Cai website content importer", &:read)
        end

  raw.delete("\0").force_encoding("UTF-8").scrub
end

def clean_text(html)
  Nokogiri::HTML.fragment(html.to_s, "UTF-8").text.unicode_normalize(:nfkc).gsub(/[[:space:]]+/, " ").strip
end

def extract_cv_text(pdf_path)
  stdout, stderr, status = Open3.capture3("pdftotext", "-layout", pdf_path, "-")
  raise "pdftotext failed: #{stderr}" unless status.success?

  stdout.force_encoding("UTF-8").scrub
end

def join_wrapped_lines(lines)
  lines.each_with_object("") do |line, result|
    value = line.strip
    next if value.empty?

    if result.end_with?("-")
      result << value
    else
      result << " " unless result.empty?
      result << value
    end
  end.gsub(/\s+/, " ").strip
end

def split_title_and_venue(remainder, number)
  boundary = remainder.match(/\.\s+(?=#{VENUE_START})/)
  raise "Could not split title and venue for CV item #{number}: #{remainder}" unless boundary

  title = remainder[0...boundary.begin(0)].strip
  venue = remainder[(boundary.end(0))..].strip
  ["#{title}.", venue]
end

def parse_cv(pdf_path)
  text = extract_cv_text(pdf_path)
  start_at = text.index("Published/Accepted Papers:")
  end_at = text.index("Service on National/International Committees:")
  raise "Could not locate the CV publication section" unless start_at && end_at

  body = text[start_at...end_at].sub(/\APublished\/Accepted Papers:.*?\n/m, "")
  records = []
  current_number = nil
  current_lines = []

  flush = lambda do
    next unless current_number

    citation = join_wrapped_lines(current_lines)
    match = citation.match(/\A(.*?)\s+\((\d{4}\+?)\)\.\s+(.*)\z/)
    raise "Could not parse CV item #{current_number}: #{citation}" unless match

    authors = match[1].strip
    year = match[2]
    title, venue = split_title_and_venue(match[3], current_number)

    # Preserve the CV's content updates while retaining verified journal facts
    # where the August 2026 PDF has an evident typographical error.
    venue = venue.sub("The Annals of Statistic 49", "The Annals of Statistics 49") if current_number == 43
    venue = venue.sub("The Annals of Statistics 42", "The Annals of Statistics 41") if current_number == 121
    venue = venue.sub("Electronic Journal of Statistics 6", "Electronic Journal of Statistics 5") if current_number == 144
    venue = venue.sub("Statistical Science 16, 106-133", "Statistical Science 16, 101-133") if current_number == 201

    records << {
      "cv_number" => current_number,
      "year" => year,
      "authors" => "#{authors} (#{year}).",
      "title" => title,
      "venue" => venue,
    }
  end

  body.each_line do |line|
    next if line.match?(/^\s*8\/2026\s+\d+\s*$/)

    if (marker = line.match(/^\s*\[(\d+)\]\s*(.*)$/))
      flush.call
      current_number = marker[1].to_i
      current_lines = [marker[2]]
    else
      current_lines << line
    end
  end
  flush.call

  expected = (1..208).to_a
  actual = records.map { |record| record.fetch("cv_number") }
  raise "Expected CV items 1-208; found #{actual.inspect}" unless actual == expected

  records
end

def all_existing_papers(data)
  data.fetch("sections").flat_map { |section| section.fetch("papers") }
end

def canonical_url(url)
  return nil if url.nil? || url.empty?

  url.sub(%r{\Ahttps://www-stat\.wharton\.upenn\.edu}, "http://www-stat.wharton.upenn.edu")
end

def closest_paper(title, candidates, minimum: 0.58)
  exact = candidates.find { |paper| normalize(paper.fetch("title")) == normalize(title) }
  return exact if exact

  ranked = candidates.map { |paper| [similarity(title, paper.fetch("title")), paper] }.sort_by { |score, _paper| -score }
  best_score, best = ranked.first
  runner_up_score = ranked.fetch(1, [0.0]).first
  return nil if best_score < minimum || (best_score - runner_up_score < 0.05 && best_score < 0.82)

  best
end

def report_record(paper)
  cleaned = paper.transform_values do |value|
    value.is_a?(String) ? value.unicode_normalize(:nfkc).gsub(/[[:space:]]+/, " ").strip : value
  end
  year = cleaned.fetch("authors")[/\((\d{4}\+?)\)/, 1]
  cleaned.merge(
    "id" => slug(cleaned.fetch("title")),
    "year" => year,
    "url" => canonical_url(cleaned["url"]),
    "topics" => [],
  )
end

def build_canonical_data(cv_records, existing_data)
  existing = all_existing_papers(existing_data)
  reports = existing_data.fetch("sections").find { |section| section.fetch("id") == "reports" }.fetch("papers").map { |paper| report_record(paper) }

  reclassified_titles = [
    "Plugin confidence intervals in discrete distributions.",
    "On modulus of continuity and adaptability in nonparametric functional estimation.",
  ]
  reclassified_titles.each do |title|
    paper = closest_paper(title, existing, minimum: 0.9)
    reports << report_record(paper) if paper && reports.none? { |report| normalize(report.fetch("title")) == normalize(title) }
  end

  used_ids = Set.new(reports.map { |paper| paper.fetch("id") })
  matched_urls = 0
  publications = cv_records.map do |record|
    match = closest_paper(record.fetch("title"), existing)
    url = if CV_ITEMS_WITHOUT_LEGACY_URLS.include?(record.fetch("cv_number"))
            nil
          else
            CV_URL_OVERRIDES.fetch(record.fetch("cv_number"), canonical_url(match && match["url"]))
          end
    matched_urls += 1 if url
    id = slug(record.fetch("title"))
    suffix = 2
    while used_ids.include?(id)
      id = "#{slug(record.fetch('title'))}-#{suffix}"
      suffix += 1
    end
    used_ids << id

    paper = record.merge("id" => id, "url" => url, "topics" => [])
    %w[abstract pdf_url].each do |field|
      paper[field] = match[field] if match && match[field] && !match[field].empty?
    end
    paper
  end

  sections = SECTION_ORDER.map do |id, title|
    papers = if id == "reports"
               reports
             elsif id == "2014-and-earlier"
               publications.select { |paper| paper.fetch("year").to_i <= 2014 }
             elsif id == "2026-plus"
               publications.select { |paper| paper.fetch("year").to_i == 2026 }
             else
               publications.select { |paper| paper.fetch("year").to_i == id.to_i }
             end
    { "id" => id, "title" => title, "papers" => papers }
  end

  warn "Matched #{matched_urls} of #{publications.length} CV papers to legacy URLs."
  {
    "source_url" => "/assets/pdf/Tony-Cai-CV-short.pdf",
    "source_label" => "T. Tony Cai short CV",
    "source_updated" => "2026-08",
    "technical_reports_source_url" => URI.join(LEGACY_ROOT, "Papers.html").to_s,
    "publication_count" => publications.length,
    "technical_report_count" => reports.length,
    "sections" => sections,
  }
end

def parse_topic_sections(html)
  start_at = html.index("<OL>") || html.index("<ol>")
  end_at = html.rindex("</OL>") || html.rindex("</ol>")
  raise "Could not locate the topic-paper list" unless start_at && end_at

  list_html = html[start_at..(end_at + 4)]
  marker_pattern = /<B>\s*<A\s+NAME=["']?([^"'\s>]+)["']?[\s\S]*?<\/B>|<LI\b/i
  markers = []
  list_html.to_enum(:scan, marker_pattern).each do
    match = Regexp.last_match
    markers << { offset: match.begin(0), legacy_anchor: match[1] }
  end

  topics = []
  current_topic = nil
  current_parent = nil

  markers.each_with_index do |marker, index|
    chunk_end = markers.fetch(index + 1, { offset: list_html.length })[:offset]
    chunk = list_html[marker[:offset]...chunk_end]

    if marker[:legacy_anchor]
      heading = Nokogiri::HTML.fragment(chunk, "UTF-8")
      title = heading.text.unicode_normalize(:nfkc).gsub(/[[:space:]]+/, " ").strip
      title = "Applications to Genomics, Chemical Identification, & Medical Imaging" if marker[:legacy_anchor] == "Applications"
      level = chunk.match?(/#008080/i) ? 2 : 1
      id = slug(marker[:legacy_anchor].tr(".", " "))
      current_parent = id if level == 1
      current_topic = {
        "id" => id,
        "legacy_anchor" => marker[:legacy_anchor],
        "title" => title,
        "level" => level,
        "parent_id" => level == 2 ? current_parent : nil,
        "legacy_titles" => [],
      }
      topics << current_topic
      next
    end

    next unless current_topic

    item = Nokogiri::HTML.fragment("<ol>#{chunk}</ol>", "UTF-8").at_css("li")
    next unless item

    segments = item.inner_html.split(/<br\s*\/?\s*>/i)
    segments.shift
    title_fragment = segments.shift.to_s
    title_link = Nokogiri::HTML.fragment(title_fragment, "UTF-8").at_css("a") || item.at_css("a")
    next unless title_link

    current_topic.fetch("legacy_titles") << clean_text(title_link.text)
  end

  topics
end

def attach_topics!(papers_data, topic_sections)
  papers = all_existing_papers(papers_data)
  unmatched = []

  topic_sections.each do |topic|
    topic.fetch("legacy_titles").each do |title|
      title = "Optimal detection for language watermarks with pseudorandom collision." if title.start_with?("Optimal detection for language watermarks")
      canonical_title = TOPIC_TITLE_ALIASES.fetch(normalize(title), title)
      paper = closest_paper(canonical_title, papers, minimum: 0.55)
      if paper
        paper.fetch("topics") << topic.fetch("id") unless paper.fetch("topics").include?(topic.fetch("id"))
      else
        unmatched << [topic.fetch("title"), title]
      end
    end
    topic.delete("legacy_titles")
  end

  topic_sections.each do |topic|
    topic["count"] = papers.count { |paper| paper.fetch("topics").include?(topic.fetch("id")) }
  end

  warn "Unmatched topic listings: #{unmatched.length}"
  unmatched.each { |topic, title| warn "  #{topic}: #{title}" }
end

cv_path = ARGV[0] || DEFAULT_CV
topics_source = ARGV[1] || DEFAULT_TOPICS

existing_data = JSON.parse(File.read(CURRENT_DATA))
papers_data = build_canonical_data(parse_cv(cv_path), existing_data)
topic_sections = parse_topic_sections(read_source(topics_source))
attach_topics!(papers_data, topic_sections)

File.write(CURRENT_DATA, JSON.pretty_generate(papers_data) + "\n")
File.write(
  OUTPUT_TOPICS,
  JSON.pretty_generate(
    {
      "source_url" => DEFAULT_TOPICS,
      "source_updated" => "2026-02-09",
      "cross_listing_note" => "Some papers are cross-listed under multiple topics.",
      "topics" => topic_sections,
    },
  ) + "\n",
)

warn "Wrote #{papers_data.fetch('publication_count')} publications, #{papers_data.fetch('technical_report_count')} reports, and #{topic_sections.length} topic sections."
