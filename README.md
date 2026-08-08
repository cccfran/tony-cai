# T. Tony Cai

Source for [tony-cai.com](https://tony-cai.com), the academic website of T. Tony Cai at the Wharton School of the University of Pennsylvania.

The site is built with Jekyll and the al-folio runtime. Website content is maintained in `_pages/` and `_data/`; custom presentation and interactions live in `_layouts/`, `_includes/`, and `assets/`.

## Local preview

```bash
bundle install
npm install
bundle exec jekyll serve
```

Open <http://127.0.0.1:4000/>.

## Validation

```bash
npm run lint:prettier
JEKYLL_ENV=production bundle exec jekyll build
```

## Deployment

Changes merged into `main` are built by GitHub Actions and published from the generated `gh-pages` branch. Edit source files on `main`; do not edit or merge `gh-pages` manually.

The root `CNAME` file and `_config.yml` both identify the production domain as `tony-cai.com`.

## Updating research data

The maintenance scripts in `bin/` refresh legacy content and paper metadata. Review generated changes in `_data/` before committing them.
