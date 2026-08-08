# frozen_string_literal: true

# Keeps PDFs copied from Tony Cai's legacy Wharton site on this website.
module LocalPdfPaths
  LEGACY_PAPER_PDF = %r{^https?://www-stat\.wharton\.upenn\.edu/~tcai/paper/(?:[^/?#]+/)*([^/?#]+\.pdf)(?:[?#].*)?$}i
  PUBLISHER_REPLACEMENTS = {
    "Discussion-of-FDR-GLM.pdf" => "https://www.tandfonline.com/doi/full/10.1080/01621459.2023.2223578",
  }.freeze

  def self.localize(url)
    return url unless url.is_a?(String)

    match = url.match(LEGACY_PAPER_PDF)
    return url unless match

    filename = match[1]
    PUBLISHER_REPLACEMENTS.fetch(filename, "/assets/pdf/papers/#{filename}")
  end
end
