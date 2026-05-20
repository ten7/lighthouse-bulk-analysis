# Lighthouse Bulk Analysis

> Run Google Lighthouse audits across dozens of URLs at once — mobile **and** desktop — and get a clean HTML dashboard plus a terminal summary in a single command.

Built and maintained by [TEN7](https://ten7.com).

---

## Table of Contents

- [What it does](#what-it-does)
- [How it works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Configuration](#configuration)
- [Output structure](#output-structure)
- [OS support](#os-support)
- [Project layout](#project-layout)
- [License](#license)

---

## What it does

Lighthouse Bulk Analysis takes a plain text list of URLs and runs [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci) against each one — multiple times, on both mobile and desktop — then produces:

- **An HTML dashboard** (`Summary_<domain>.html`) with scores for performance, accessibility, SEO, and best practices across every URL, plus links to full per-page reports and the top performance opportunities.
- **A terminal summary** printed in real time while the audit runs.
- **Raw artifacts** — full Lighthouse HTML and JSON reports for every run, organized in a timestamped folder under `reports/`.

To reduce noise, the dashboard uses the **median run by performance score** for each URL rather than any single run.

---

## How it works

```
urls.txt  ──►  run-audit.sh  ──►  lhci collect (mobile)   ──►  reports/<timestamp>/mobile/
                              ──►  lhci collect (desktop)  ──►  reports/<timestamp>/desktop/
                              ──►  generate-dashboard.js   ──►  Summary_<domain>.html
                                                           ──►  terminal score table
```

1. **`run-audit.sh`** reads `urls.txt`, dynamically writes a `lighthouserc.json`, and runs `lhci collect` + `lhci upload` twice — once with default mobile throttling and once with `--settings.preset=desktop`.
2. Results land in a timestamped folder under `reports/`, with `mobile/` and `desktop/` subfolders each containing a `manifest.json` and the raw HTML/JSON reports.
3. **`generate-dashboard.js`** reads the manifests, picks the median run per URL, prints the score table to the terminal, and writes the HTML dashboard.

You only ever run `./run-audit.sh` — the Node script is called automatically at the end.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| **Node.js v14+** and npm | Verify: `node -v` |
| **Lighthouse CI CLI** (`@lhci/cli`) | Verify: `lhci --version` |
| **Google Chrome** | macOS/Windows: standard install. Linux: `sudo apt install chromium-browser` |
| **Bash** | macOS/Linux: built-in. Windows: use WSL or Git Bash. |

---

## Installation

**1. Clone the repository:**

```bash
git clone https://github.com/ten7/lighthouse-bulk-analysis.git
cd lighthouse-bulk-analysis
```

**2. Install Lighthouse CI globally:**

```bash
npm install -g @lhci/cli
```

**3. Make the audit script executable:**

```bash
chmod +x run-audit.sh
```

**4. Create your URL list:**

```bash
cp urls.sample.txt urls.txt
```

Edit `urls.txt` — one full URL per line. Lines starting with `#` are treated as comments and ignored.

```
# Homepage and key landing pages
https://www.example.com/
https://www.example.com/about
https://www.example.com/contact
```

---

## Quick start

With `urls.txt` in place, run:

```bash
./run-audit.sh
```

That's it. The script will:

1. Create a timestamped run folder at `reports/YYYY-MM-DD_HH-MM-SS_<domain>/`.
2. Run Lighthouse CI `RUNS` times per URL on **mobile**, then repeat on **desktop**.
3. Write the HTML dashboard and print a score table to the terminal.
4. Automatically open the run folder when the audit finishes (macOS via `open`, Linux via `xdg-open`).

Open **`Summary_<domain>.html`** first for the overview, then follow the Mobile/Desktop links in each row to drill into full per-page Lighthouse reports.

---

## Configuration

Edit the configuration block near the top of `run-audit.sh`:

```bash
# --- CONFIGURATION ---
URL_FILE="urls.txt"
RUNS=3
# ---------------------
```

| Variable | Default | Description |
|---|---|---|
| `URL_FILE` | `urls.txt` | Path to your URL list |
| `RUNS` | `3` | Number of Lighthouse CI runs per URL per device type. Higher values reduce variance; lower values run faster. |

To change dashboard layout, score display, or opportunity ranking, edit `generate-dashboard.js` directly.

---

## Output structure

Each run creates a self-contained folder under `reports/`:

```
reports/
└── 2024-03-15_10-30-00_example.com/
    ├── Summary_example.com.html      ← Start here
    ├── mobile/
    │   ├── manifest.json             ← Lighthouse CI index
    │   ├── <hash>.report.html        ← Full report per run
    │   └── <hash>.report.json
    └── desktop/
        ├── manifest.json
        ├── <hash>.report.html
        └── <hash>.report.json
```

Both `reports/` and `.lighthouseci/` are gitignored — audit output stays local and is never committed.

---

## OS support

| OS | Status | Notes |
|---|---|---|
| **macOS** | ✅ Recommended | Works natively with Node.js, Chrome, and `@lhci/cli` installed. |
| **Linux** | ✅ Supported | Install Chrome or Chromium. Results folder opens via `xdg-open` if available. |
| **Windows** | ⚠️ Via WSL/Git Bash | Use WSL (recommended) or Git Bash with Node.js, Chrome, and `@lhci/cli` installed in that environment. |

---

## Project layout

| File | Role |
|---|---|
| `run-audit.sh` | Entry point: folder setup, `lighthouserc.json` generation, audit runs, dashboard invocation |
| `generate-dashboard.js` | Reads Lighthouse CI manifests, picks median run per URL, writes HTML dashboard, prints terminal summary |
| `urls.sample.txt` | Example URL list — copy to `urls.txt` to get started |
| `urls.txt` | Your URL list (gitignored; not committed) |
| `lighthouserc.json` | Auto-generated on each run from `urls.txt` and `RUNS` — do not edit manually |
| `reports/` | All audit output (gitignored) |

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. See the [LICENSE](LICENSE) file for details.

---

## About TEN7

This tool was created and is actively maintained by [TEN7](https://ten7.com), a digital agency that builds, rescues, and cares for Drupal sites. Our mission is to **Make Things That Matter**.

- 🌐 [ten7.com](https://ten7.com)
- 📖 [handbook.ten7.com](https://handbook.ten7.com)