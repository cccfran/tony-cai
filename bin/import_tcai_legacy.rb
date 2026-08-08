#!/usr/bin/env ruby

# Imports the two long, structured collections from Tony Cai's legacy site.
# Pass local HTML files while developing, or run without arguments to fetch
# the public pages directly.

require "json"
require "nokogiri"
require "open-uri"
require "uri"

ROOT = File.expand_path("..", __dir__)
BASE_URL = "http://www-stat.wharton.upenn.edu/~tcai/"
PAPERS_URL = URI.join(BASE_URL, "Papers.html").to_s
TEAM_URL = URI.join(BASE_URL, "Research-Group.html").to_s

SECTION_TITLES = {
  "Reports" => "Technical Reports",
  "2025" => "2025+",
  "2024" => "2024",
  "2023" => "2023",
  "2022" => "2022",
  "2021" => "2021",
  "2020" => "2020",
  "2019" => "2019",
  "2018" => "2018",
  "2017" => "2017",
  "2016" => "2016",
  "2015" => "2015",
  "2014-" => "2014 & Earlier",
}.freeze

def read_source(source)
  raw = if File.file?(source)
          File.binread(source)
        else
          URI.open(source, "User-Agent" => "Tony Cai website content importer", &:read)
        end

  raw.force_encoding("UTF-8").scrub
end

def clean_text(html)
  Nokogiri::HTML.fragment(html.to_s, "UTF-8").text.gsub(/\s+/, " ").strip
end

def absolute_url(href)
  return nil if href.nil? || href.empty?

  URI.join(BASE_URL, href).to_s
end

def parse_papers(html)
  start_at = html.index("<OL>") || html.index("<ol>")
  end_at = html.rindex("</OL>") || html.rindex("</ol>")
  raise "Could not locate the papers list" unless start_at && end_at

  list_html = html[start_at..(end_at + 4)]
  marker_pattern = /<B>\s*<A\s+NAME=["']([^"']+)["'][\s\S]*?<\/B>|<LI\b/i
  markers = []
  list_html.to_enum(:scan, marker_pattern).each do
    match = Regexp.last_match
    markers << { offset: match.begin(0), section_id: match[1] }
  end

  sections = []
  current_section = nil

  markers.each_with_index do |marker, index|
    if marker[:section_id]
      current_section = {
        "id" => marker[:section_id].downcase.gsub(/[^a-z0-9]+/, "-"),
        "title" => SECTION_TITLES.fetch(marker[:section_id], marker[:section_id]),
        "papers" => [],
      }
      sections << current_section
      next
    end

    next unless current_section

    chunk_end = markers.fetch(index + 1, { offset: list_html.length })[:offset]
    chunk = list_html[marker[:offset]...chunk_end]
    item = Nokogiri::HTML.fragment("<ol>#{chunk}</ol>", "UTF-8").at_css("li")
    next unless item

    segments = item.inner_html.split(/<br\s*\/?\s*>/i)
    authors = clean_text(segments.shift)
    title_fragment = segments.shift.to_s
    title_link = Nokogiri::HTML.fragment(title_fragment, "UTF-8").at_css("a") || item.at_css("a")
    title = title_link ? title_link.text.gsub(/\s+/, " ").strip : clean_text(title_fragment)
    url = absolute_url(title_link&.[]("href"))
    venue = segments.map { |segment| clean_text(segment) }.reject(&:empty?).join(" ")

    # The legacy page accidentally links this title to the supervised-topic-
    # modeling paper. Keep the imported archive accurate.
    if title == "Optimal detection for language watermarks with pseudorandom collision."
      url = "https://arxiv.org/abs/2510.22007"
    end

    current_section["papers"] << {
      "authors" => authors,
      "title" => title,
      "url" => url,
      "venue" => venue,
    }
  end

  {
    "source_url" => PAPERS_URL,
    "source_updated" => "2026-02-09",
    "sections" => sections,
  }
end

def clean_table_cell(cell)
  copy = cell.dup
  copy.css("br").each { |line_break| line_break.replace(" · ") }
  copy.text.gsub(/\s+/, " ").strip
end

def parse_team(html)
  start_at = html.index("The research team")
  end_at = html.index("Start of StatCounter") || html.length
  raise "Could not locate the research-team content" unless start_at

  fragment = Nokogiri::HTML.fragment(html[start_at...end_at], "UTF-8")
  current_table, alumni_table = fragment.css("table").first(2)
  raise "Could not locate the research-team tables" unless current_table && alumni_table

  current_cells = current_table.at_css("tr").css("td").map { |cell| clean_table_cell(cell) }
  alumni = alumni_table.css("tr").drop(1).each_with_object([]) do |row, records|
    cells = row.css("td").map { |cell| clean_table_cell(cell) }
    next if cells.length < 3

    records << { "name" => cells[0], "role" => cells[1], "position" => cells[2] }
  end

  {
    "source_url" => TEAM_URL,
    "focus" => "The research team develops methodology and optimality theory in statistical machine learning, large-scale inference, and high-dimensional statistics, with applications in genomics and financial econometrics.",
    "current" => {
      "role" => current_cells[0].sub(/:\z/, ""),
      "members" => current_cells[1].split(/,\s*/),
    },
    "alumni" => alumni,
  }
end

papers_source = ARGV[0] || PAPERS_URL
team_source = ARGV[1] || TEAM_URL

papers = parse_papers(read_source(papers_source))
team = parse_team(read_source(team_source))

File.write(File.join(ROOT, "_data", "papers.json"), JSON.pretty_generate(papers) + "\n")
File.write(File.join(ROOT, "_data", "team.json"), JSON.pretty_generate(team) + "\n")

paper_count = papers.fetch("sections").sum { |section| section.fetch("papers").length }
warn "Imported #{paper_count} papers and #{team.fetch('alumni').length} alumni."
