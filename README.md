# ABCDE documentation

Architecture documentation, review notes and plans for the systems behind [abcde.lv](https://abcde.lv). abcde.lv is a website in Latvian and English that shows Nutri-Score grades for food sold at Rimi and Maxima in Latvia.

This repository holds documents only. The code is in three separate GitHub repositories, which are cloned into this folder for reference but excluded from this repository by `.gitignore`:

| Repository | What it is |
|---|---|
| [RimiScraper-v2](https://github.com/yuri-ivanov1972/RimiScraper-v2) | Python/Streamlit scraper that collects and scores Rimi products into PostgreSQL |
| [BarboraScraper-v1](https://github.com/yuri-ivanov1972/BarboraScraper-v1) | A fork of the Rimi scraper for Barbora.lv, Maxima's online store |
| [ABCDE-Web-EU](https://github.com/yuri-ivanov1972/ABCDE-Web-EU) | The abcde.lv website: a React frontend and an Express API that reads both scraper databases |

## Documents

Start with the overview, then read the architecture document. Each document is committed as Markdown, and most also as a PDF.

| Document | What it covers |
|---|---|
| [OVERVIEW.md](OVERVIEW.md) | A one-paragraph summary of each repository |
| [ARCHITECTURE.md](ARCHITECTURE.md) ([PDF](ARCHITECTURE.pdf)) | How the three repositories fit together: system diagram, the shared database tables, the daily update cycle, the external services, and the risks that span the repos. Each repository also has its own `ARCHITECTURE.md`. |
| [THINGS_TO_LOOK_AT.md](THINGS_TO_LOOK_AT.md) | Issues found while documenting the code, most important first, each with file and line references and a suggested next step |
| [PROPOSAL_architecture_consolidation.md](PROPOSAL_architecture_consolidation.md) ([PDF](PROPOSAL_architecture_consolidation.pdf)) | A staged plan to share the scrapers' scoring code, merge them onto one codebase, check the shared database schema automatically, and add a category tree that doesn't belong to either store. It ends with decisions D-01 to D-06. |
| [AWS_MIGRATION_PLAN.md](AWS_MIGRATION_PLAN.md) ([PDF](AWS_MIGRATION_PLAN.pdf)) | Moving from Replit to AWS: two EC2 instances with an optional RDS database, costs from the AWS price list for Frankfurt and Stockholm, cutover steps, rollback, and decisions M-01 to M-05 |

## Setting up the code repositories

To read the documents next to the code they describe, clone the three repositories into this folder:

```bash
gh repo clone yuri-ivanov1972/RimiScraper-v2
gh repo clone yuri-ivanov1972/BarboraScraper-v1
gh repo clone yuri-ivanov1972/ABCDE-Web-EU
```

The documents were written against these commits, on each repository's `add-readme` branch:

| Repository | Commit |
|---|---|
| RimiScraper-v2 | `6741db0` |
| BarboraScraper-v1 | `d819fef` |
| ABCDE-Web-EU | `1a0c1de` |

File and line references in the documents point to these versions.

## Making the PDFs

The PDFs are made with `spec2pdf.sh`, which uses pandoc and XeLaTeX and draws the Mermaid diagrams with Chrome.

`spec2pdf.sh` is part of [speccheck](https://github.com/rioffe/speccheck), so install speccheck first. Its `install.sh` installs `spec2pdf.sh` to `~/.local/bin/` together with what it needs:
- pandoc
- XeLaTeX
- Node with `mermaid-filter`/`mmdc`
- a Chrome or Chromium browser

```bash
git clone https://github.com/rioffe/speccheck.git
cd speccheck
./install.sh --spec2pdf    # only spec2pdf.sh and its dependencies; plain ./install.sh sets up everything
```

Then, from this folder:

```bash
spec2pdf.sh ARCHITECTURE.md   # writes ARCHITECTURE.pdf next to it
```

After editing a Markdown file, regenerate its PDF before committing so the two stay in sync.
