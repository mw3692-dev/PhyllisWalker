# phylliswalker-replica

Static replica of the Phyllis Walker J.Hilburn landing page for demo and consultation.

This workspace copy includes local placeholder images (SVG) so the site can be previewed offline.

Enhancements in this copy:
- SEO meta tags, OpenGraph, and JSON-LD (ProfessionalService + areaServed) including Frisco (The Star), Plano, Allen, McKinney, Carrollton, Prosper, The Colony, and Little Elm.
- Dedicated location pages for each city and `sitemap.xml` + `robots.txt` to aid indexing.
- Service schema (OfferCatalog) and optimized image assets for custom suits, tuxedo fittings, and steaming/pressing.

To preview locally:

```bash
cd phylliswalker-replica
python3 -m http.server 8000
# then open http://localhost:8000 in your browser
```

To publish to GitHub Pages (recommended):

1. Create a repository on GitHub.
2. Push this folder to the repo (commands below).
3. In the repo Settings -> Pages, enable publishing from the `main` branch `/ (root)`.

Suggested git commands:

```bash
git init
git add .
git commit -m "Initial replica site with SEO and location pages"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

Notes:
- The images in `assets/` are placeholder SVGs. Replace them with high-quality photos named with service and city keywords (e.g., `phyllis-walker-frisco-suit.jpg`) for better SEO.
- After publishing, submit `https://phylliswalker.jhilburn.com/sitemap.xml` to Google Search Console and request indexing for key pages.
