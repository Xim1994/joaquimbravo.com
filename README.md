# joaquimbravo.com

Personal CV site for Joaquim Bravo Jordana — IoT engineer and founder of Civitech.

Live at **[joaquimbravo.com](https://joaquimbravo.com)**.

## Stack

- Single static `index.html` with inline CSS + vanilla JS (no build).
- EN / ES toggle, dark / light theme, responsive.
- `favicon.svg` + generated PNG icons.
- `og-image.png` (1200×630) generated from `_build/og-source.html` via Chrome headless.
- GitHub Pages hosting with custom domain (`CNAME`).
- GitHub Actions regenerate `cv-en.pdf` and `cv-es.pdf` on every push.

## Local preview

Open `index.html` directly, or serve it:

```bash
npx http-server . -p 8080
```

## Regenerate assets

```bash
# OG image
chrome --headless --disable-gpu --hide-scrollbars \
  --window-size=1200,630 \
  --screenshot=og-image.png \
  file:///$(pwd)/_build/og-source.html
```
