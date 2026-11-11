# Repository Overview

The three most recently updated repositories from [yuri-ivanov1972](https://github.com/yuri-ivanov1972), cloned 2026-11-11.

## RimiScraper-v2

[RimiScraper-v2](https://github.com/yuri-ivanov1972/RimiScraper-v2) is a Python app (Streamlit UI plus a background worker) built on Replit. It crawls the Latvian Rimi supermarket website and stores product data in PostgreSQL: names, SKUs, prices, photos, ingredients and nutrition values. Prices and availability go into a separate `product_price_history` table instead of the products table. On top of the scraped data it extracts E-number additives, calculates Nutri-Score (2024 algorithm) and NOVA processing scores, estimates fiber and enriches missing nutrition from USDA data. An AI step (OpenAI/Gemini) sorts ingredients into categories and flags suspicious ones. A PostgreSQL-backed job queue with heartbeats runs category scrapes and scheduled daily price and availability updates. The repo has about 870 commits since December 2024 and a lot of one-off `debug_*`, `test_*` and `fix_*` scripts sitting at the top level.

## ABCDE-Web-EU

[ABCDE-Web-EU](https://github.com/yuri-ivanov1972/ABCDE-Web-EU) is the public website [abcde.lv](https://abcde.lv). It's a bilingual (Latvian/English) browser for Latvian supermarket food products that shows Nutri-Score grades (A–E) and nutrition info, and suggests healthier alternatives across Rimi and Maxima. It's a TypeScript pnpm monorepo. The frontend in `artifacts/abcde-lv` uses React, Vite, Tailwind and i18next. The API server in `artifacts/api-server` is an Express 5 app with server-side SEO meta and a sitemap. Drizzle ORM connects to several Postgres databases: a local one for barcode scans, plus the remote Neon databases that the two scrapers fill with Rimi and Maxima products. The repo also contains a pitch deck (`abcde-lv-deck`), a mockup sandbox, OpenAPI/Zod client libraries and a threat model. It has about 800 commits since April 2025.

## BarboraScraper-v1

[BarboraScraper-v1](https://github.com/yuri-ivanov1972/BarboraScraper-v1) is a fork of the Rimi scraper (both repos have the same root commit) adapted for Barbora.lv, Maxima's online grocery store. It's the data source behind the website's Maxima products. It keeps the same Streamlit-plus-worker design, the PostgreSQL schema with price history, and the Nutri-Score, NOVA and AI ingredient pipeline. It adds Barbora-specific modules: a parser, a worker and a lightweight daily updater. Several modules link Barbora products to Rimi data, including Rimi category codes, imported Rimi nutrition and matched fresh produce. It also has tools for photo maintenance, product refreshes and nutrition reloads. Some of its docs were never updated after the fork, so `replit.md` is still titled "Maxima Product Scraper" and still describes Rimi. It has about 915 commits.
