# Things to Look At

These are issues found while documenting the three repositories on 2026-11-11. None of them has been fixed. Each item says where it is in the code, why it matters, and what to check next. The most important items are first.

Code references are relative to this folder.

---

## 1. Nutri-Score grade boundaries may differ from the official 2024 rules

**Where:** `RimiScraper-v2/nutriscore_calculator.py:195` and `:223`. The same code is in `BarboraScraper-v1/nutriscore_calculator.py:306` and `:334`.

**What:** there are two possible differences from the official rules.

- **Grade A for general foods** (line 223) is given when the score $S \le -1$. In the published 2023/2024 algorithm, as I understand it, A covers $S \le 0$.
- **The protein rule.** Protein points are dropped when $N \ge 11$ (line 195), and the same cut-off applies to fats, oils and nuts. As I understand the official rules, that category uses $N \ge 7$. The old exception for products with high fruit/vegetable/legume content may also have been removed in the new version.

**Why it matters:** the grade is the main thing abcde.lv shows. A product with a score of exactly 0 is shown as B when it may be an A, which affects which products count as "healthier alternatives".

**Next step:** compare `calculate_nutriscore_2024` against the official Santé publique France specification for foods and beverages. I'm not certain about the official values above, so check them before changing code. If the code is wrong, fix it in **both** scrapers and recalculate stored grades with the Nutri-Score recalculation tool in each scraper's UI.

---

## 2. The two scrapers calculate NOVA differently

**Where:** `RimiScraper-v2/nova_calculator.py` and `BarboraScraper-v1/nova_calculator.py`

**What:**
- **Rimi** gives group 4 if any ingredient is flagged *avoid* or *limit*. Otherwise the product gets its category's group, which may be empty.
- **Barbora** also:
  - gives group 4 for explicit flavourings (`aromatizētāji`);
  - leaves NOVA unknown when the ingredient analysis is missing or contradictory;
  - doesn't give group 1 to products with added salt or flavouring.

**Why it matters:** the same product can show a different NOVA group on abcde.lv depending on whether Rimi or Maxima sells it. The Rimi version is also more likely to assign a low group based on incomplete analysis.

**Next step:** decide which rules are correct. The Barbora rules look more careful and cite Monteiro et al. 2019. Then make both scrapers use them and run NOVA again on the affected products.

---

## 3. Shared code has drifted between the forks

**Where:** both scrapers come from root commit `e6e7af1`. For example, `nutriscore_calculator.py` and `fiber_estimator.py` now differ between the two repos.

**What:** modules that should behave the same (Nutri-Score, fiber, ingredient processing, job queue) are kept as two separate copies.

**Why it matters:** a fix applied to one scraper doesn't reach the other. Items 1 and 2 are examples of this.

**Next step:** run `diff` on the shared modules to see what has diverged. Consider moving the scoring code into a shared Python package used by both scrapers, or at least shared tests that both must pass.

---

## 4. The Barbora worker doesn't reclaim abandoned jobs

**Where:** `BarboraScraper-v1/barbora_worker.py:106–131` (`claim_job`, which sets `status = 'processing'` at line 114)

**What:** the Barbora worker only claims jobs with `status = 'queued'`. It doesn't send heartbeats and it doesn't reclaim jobs. The Rimi worker (`RimiScraper-v2/worker.py:268`) reclaims `in_progress` jobs whose heartbeat is older than $2 \times$ `heartbeat_interval`.

**Why it matters:** if the Barbora worker crashes or is killed mid-job, which is likely on Autoscale with its 90-second limit, the job stays `processing` forever. Products waiting in that job are never scraped.

**Next step:** check `category_processing_jobs` in the Maxima database for old `processing` rows. Port the heartbeat and lease logic from the Rimi worker, or add a sweep that puts stale jobs back in the queue.

---

## 5. A hidden Maxima product can reappear until the next nightly run

**Where:**
- `BarboraScraper-v1/barbora_worker.py`: `save_price_history_from_listing` (around line 687) and `save_price_history` (around line 785)
- `BarboraScraper-v1/barbora_lightweight_updater.py:303` (`apply_hidden_overrides`)

**What:** the site never reads `is_hidden`. A product is hidden only because its latest price row says `is_available = false`. The lightweight updater respects `is_hidden`, and `apply_hidden_overrides` re-hides products after each nightly run. The Barbora worker's two price-history writers don't check `is_hidden`.

**Why it matters:** if the worker scrapes a hidden product, for example in a product refresh or category re-scrape, it writes an "available" row. The product then shows on abcde.lv until the next nightly run hides it again.

**Next step:** make both worker methods treat `is_hidden = TRUE` as unavailable, as the lightweight updater does at line 154. Also check the Rimi side: `lightweight_updater.py` and `enhanced_database_updater.py` handle it, but confirm `suspicious_refresh` does too.

---

## 6. `rimi_category_code` has a different type in each database

**Where:** `ABCDE-Web-EU/lib/db/src/server/remote-schema.ts:17` (Rimi: `varchar`, e.g. `SH-11-9-26`) and `:53` (Maxima: `integer`, which is a Rimi `category_id`)

**What:** the same column name holds a text code in one database and a foreign key to the other database in the other.

**Why it matters:** the website places Maxima products in Rimi's category tree with this column (`storage.ts:381–444`). If Rimi's `category_id` values ever change, for example after re-importing categories, Maxima products end up in the wrong categories or disappear, and nothing reports an error.

**Next step:** rename the Maxima column (e.g. `rimi_category_id`), or at least document the difference in both schemas. Consider a periodic check that every Maxima `rimi_category_code` points to an existing Rimi category.

---

## 7. Nothing checks the website's view of the scraper schemas

**Where:** `ABCDE-Web-EU/lib/db/src/server/remote-schema.ts` against `RimiScraper-v2/schema.sql` and `BarboraScraper-v1/barbora_schema.sql`

**What:** the website hard-codes its own Drizzle definitions of tables owned by the scrapers. No shared package or test keeps them in sync.

**Why it matters:** renaming or dropping a column in a scraper breaks website queries only when they run in production.

**Next step:** add a small CI or startup check that compares the columns the website uses with `information_schema` in each database.

---

## 8. Smaller items

| Item | Where | Note |
|---|---|---|
| Hard-coded excluded categories | `ABCDE-Web-EU/artifacts/api-server/src/routes/routes.ts:423`, `:1749` | `excludedCategoryIds = [5, 40]` ("Gatavots Rimi") appears twice. Make it one shared constant. |
| Scan token secret | `routes.ts:924–925` | If `SCAN_TOKEN_SECRET` isn't set, a random secret is used. Tokens last 10 minutes, so a restart only invalidates scans in progress. Set it explicitly if more than one instance runs. |
| Unused dependency | `pyproject.toml` in both scrapers | `openai` is listed but not imported. All AI calls use `google-genai`. |
| Scheduler disabled in code | `BarboraScraper-v1/lightweight_scheduler.py:20` | `ENABLED = False`. It's enabled only through `--enable` in `combined_startup.sh`, so starting it any other way skips the daily update. |
| Barbora worker never starts automatically | `BarboraScraper-v1/combined_startup.sh` | The startup script runs only the UI and the scheduler. New SKUs queued by the nightly run wait until someone starts `barbora_worker.py`. |
| Out-of-date docs | `BarboraScraper-v1/replit.md`, `WORKER_USAGE.md` | Still titled "Maxima Product Scraper" and describe Rimi and `worker.py`. |
| Clutter at the top level | both scrapers | Many one-off `debug_sku_*`, `fix_*` and `test_*` scripts. Move them to `archive/` or `scripts/` and keep real tests under `tests/`. |
| Workers not on an always-on host | both scrapers, `RESERVED_VM_SETUP.md` | Workers are meant to run on a Reserved VM. Running on Autoscale limits throughput (`--chunk-size 3 --max-workers 1`). |
| Stale README PDFs | `*/README.pdf` (not committed) | Made before the README fixes. Re-run `spec2pdf.sh` before committing them. |
