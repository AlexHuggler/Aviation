# SoloTrack — solo-track.com

Marketing, documentation, blog, and legal site for **SoloTrack**, a free iOS flight logbook for student pilots.

Live at <https://solo-track.com/>. Hosted on GitHub Pages with a Cloudflare-managed custom domain.

## Layout

```
/                          → index.html (marketing landing page)
/privacy/                  → Privacy Policy
/terms/                    → Terms of Use
/contact/                  → Contact / Support email
/support/                  → Support page (FAQ-style)
/blog/                     → Blog index
/blog/<slug>/              → Blog posts (BlogPosting JSON-LD)
/docs/                     → Documentation hub (TechArticle JSON-LD)
/docs/getting-started/     → Getting started guide
/docs/currency-tracking/   → FAR 61.109 / 61.57 / 61.56 reference
/docs/app-store-web-checklist.md → App Store Connect URL checklist
/404.html                  → Custom 404 page
/robots.txt                → Crawl directives + sitemap reference
/sitemap.xml               → Canonical URL sitemap
/llms.txt                  → Concise LLM/AI discovery file
/llms-full.txt             → Detailed AI-citation reference
/feed.xml                  → Blog RSS feed
/CNAME                     → solo-track.com
/.nojekyll                 → Disables Jekyll on GitHub Pages
/app-icon.png              → Hero / OG / favicon image
/assets/css/page.css       → Shared styles for legal/blog/docs pages
/internal/                 → Product strategy docs (excluded via robots.txt)
```

`/internal/` holds the `01_*.md` through `05_*.md` product spec files. They live in the public repo but are blocked from indexing via `Disallow: /internal/` in `robots.txt` and are not linked from any page or sitemap.

## Deploy

GitHub Pages is configured as **Deploy from a branch**:

- Source: `Deploy from a branch`
- Branch: `main`
- Folder: `/` (root)
- Custom domain: `solo-track.com`
- Enforce HTTPS: enabled

Cloudflare (DNS / CDN in front of GitHub Pages):

- SSL/TLS encryption mode: **Full (strict)**
- Apex `solo-track.com` resolves to GitHub Pages IPs (or CNAME-flattened to `<user>.github.io`)

A push to `main` triggers a Pages build automatically. The presence of `/.nojekyll` skips the Jekyll step so files are served exactly as committed.

## Local preview

GitHub Pages serves the directory as-is — no build step. To preview locally:

```sh
python3 -m http.server 8000
```

Then visit <http://localhost:8000/>.

## Validation

- **Sitemap:** <https://www.xml-sitemaps.com/validate-xml-sitemap.html> or `xmllint --noout sitemap.xml`
- **Robots:** <https://www.google.com/webmasters/tools/robots-testing-tool>
- **Structured data:** <https://search.google.com/test/rich-results> (Schema.org validator)
- **Submit sitemap:** Google Search Console → Sitemaps; Bing Webmaster Tools → Sitemaps
- **HTML validation:** <https://validator.w3.org/>

## Contact

Support: [Contact@solo-track.com](mailto:Contact@solo-track.com)

Publisher: Huggler Holdings LLC
