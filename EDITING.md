# Editing tony-cai.com

This guide covers routine content updates. Work in the source files, merge changes into `main`, and let GitHub Actions publish the site. Never edit `gh-pages` or `_site/`; both contain generated output.

## Common files

| Content                        | File or folder                                                                                   |
| ------------------------------ | ------------------------------------------------------------------------------------------------ |
| Homepage                       | [`_pages/about.md`](_pages/about.md)                                                             |
| Other pages and navbar order   | [`_pages/`](_pages/) — edit `nav`, `nav_order`, and `title` in the page front matter             |
| Papers                         | [`_data/papers.json`](_data/papers.json)                                                         |
| Paper topics and counts        | [`_data/paper_topics.json`](_data/paper_topics.json)                                             |
| CV                             | [`assets/pdf/Tony-Cai-CV-short.pdf`](assets/pdf/Tony-Cai-CV-short.pdf)                           |
| Paper PDFs                     | [`assets/pdf/papers/`](assets/pdf/papers/)                                                       |
| Team and special lectures      | [`_data/team.json`](_data/team.json), [`_data/special_lectures.yml`](_data/special_lectures.yml) |
| Images and styling             | [`assets/img/`](assets/img/), [`assets/css/tony-cai.css`](assets/css/tony-cai.css)               |
| Footer and “Last updated” date | [`_includes/footer.liquid`](_includes/footer.liquid)                                             |
| Domain and site settings       | [`_config.yml`](_config.yml), [`CNAME`](CNAME)                                                   |

## Add or update a paper

For one or a few papers, edit the data manually. This preserves the curated abstracts, topics, and PDF links.

1. If hosting the PDF in this repository, copy it to `assets/pdf/papers/`. Use a short, stable filename with the exact same capitalization used in `pdf_url`.
2. Add the paper to the appropriate section of `_data/papers.json`, newest first. Use `reports` for a technical report and the appropriate year section for a published or accepted paper. If the year has no section yet, add one; the year navigation is generated from this list.
3. Update `publication_count` or `technical_report_count` at the top of the file. If moving a report to the publication list, remove the old report entry and adjust both counts.
4. Update `source_updated` using `YYYY-MM`.
5. Copy valid topic IDs from `_data/paper_topics.json` into the paper’s `topics` array. Increase `count` once for every topic used. Parent totals are calculated automatically from these topic counts.

Example record:

```json
{
  "year": "2026",
  "authors": "Cai, T. T., ... (2026).",
  "title": "Paper title.",
  "venue": "Journal or technical-report information.",
  "id": "paper-title",
  "url": "https://arxiv.org/abs/0000.00000",
  "topics": ["machine-learning", "transfer-learning"],
  "abstract": "Plain-text abstract.",
  "pdf_url": "/assets/pdf/papers/Paper-Title.pdf"
}
```

Keep `id` unique and use lowercase words separated by hyphens. `url` records the source or landing page; it is not the PDF button. A title is expandable only when `abstract` is present, and the PDF button appears only when both `abstract` and `pdf_url` are present. Published records may also retain `cv_number`; if used, it should match the item number in the current CV.

## Update the CV

1. Replace `assets/pdf/Tony-Cai-CV-short.pdf`, keeping that exact filename. The CV tab will update automatically.
2. Open the PDF to confirm it is readable. If Poppler is installed, also run:

   ```bash
   pdfinfo assets/pdf/Tony-Cai-CV-short.pdf
   ```

3. Update `source_updated` near the top of `_data/papers.json` to the date of the new CV.
4. Replacing the PDF does **not** update the Papers pages. If the CV adds, removes, or changes publications, update `_data/papers.json` and `_data/paper_topics.json` using the paper workflow above.
5. Update the date in `_includes/footer.liquid` before publishing.

## Preview and check

First-time setup:

```bash
bundle install
npm install
```

Preview the site:

```bash
bundle exec jekyll serve --livereload
```

Open <http://127.0.0.1:4000/>. For a paper update, check `/papers/`, `/papers-by-topic/`, and `/cv/`; test search, topic counts, abstract expansion, and the PDF link.

Before committing:

```bash
ruby -rjson -e 'JSON.parse(File.read("_data/papers.json")); JSON.parse(File.read("_data/paper_topics.json")); puts "JSON OK"'
npm run lint:prettier
JEKYLL_ENV=production bundle exec jekyll build
git diff --check
```

If Prettier reports only formatting changes, format the edited data files and run the checks again:

```bash
npx prettier _data/papers.json _data/paper_topics.json --write
```

## Publish

Create a branch, commit the reviewed files, push it, and merge a pull request into `main`:

```bash
git switch main
git pull --ff-only
git switch -c update-papers
# Make and validate the edits.
git add <changed-files>
git commit -m "Update papers and CV"
git push -u origin HEAD:refs/heads/update-papers
```

Merging into `main` starts `.github/workflows/deploy.yml`. It builds the site and replaces the generated `gh-pages` branch automatically.

## Advanced import scripts

The scripts in `bin/` are not a one-click routine update:

- `update_tcai_papers.rb` overwrites both paper data files and currently assumes the August 2026 CV, exactly 208 publications, fixed year sections, and the old topic page.
- `update_paper_details.rb` rewrites paper data after fetching supported legacy or arXiv pages; it does not download PDFs.
- `import_tcai_legacy.rb` is a migration/recovery tool that overwrites both papers and team data from the old website.

Run an importer only when intentionally rebuilding data, and inspect the complete `git diff` before keeping its output.
