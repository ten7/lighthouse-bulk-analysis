# Lighthouse Bulk Analysis

> Point it at a list of URLs. Get back a clean HTML dashboard — performance, accessibility, best practices, and SEO scored for both mobile and desktop — from one command.

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

A slow site shuts people out — especially on the phones and older laptops your visitors actually use. We build for schools and nonprofits, so we check this work constantly. Auditing dozens of URLs by hand, twice each for mobile and desktop, gets old fast. This tool does it for you.

Give it a plain text list of URLs. It runs [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci) against each one — several times, on mobile and desktop — and produces:

- **An HTML dashboard** (`Summary_<domain>.html`) scoring performance, accessibility, SEO, and best practices for every URL. It links to the full per-page reports and ranks the top performance opportunities.
- **A terminal summary.** While the audit runs, Lighthouse CI streams its own progress. When it finishes, you get a color-coded score table and the top opportunities printed right in your terminal.
- **Raw artifacts** — the full Lighthouse HTML and JSON reports for every run, kept in a timestamped folder under `reports/`.

Lighthouse scores wobble from run to run. That's normal, and it's why we run each URL several times and use the **median run by performance score** for the dashboard. One bad run won't skew your numbers.

---

## How it works

```
urls.txt  ──►  run-audit.sh  ──►  lhci collect (mobile)   ──►  reports/<timestamp>/mobile/
                              ──►  lhci collect (desktop)  ──►  reports/<timestamp>/desktop/
                              ──►  generate-dashboard.js   ──►  Summary_<domain>.html
                                                           ──►  terminal score table
```

1. **`run-audit.sh`** reads `urls.txt`, writes a fresh `lighthouserc.json`, then runs `lhci collect` + `lhci upload` twice — once with default mobile throttling, once with `--settings.preset=desktop`.
2. Results land in a timestamped folder under `reports/`, with `mobile/` and `desktop/` subfolders. Each holds a `manifest.json` and the raw HTML/JSON reports.
3. **`generate-dashboard.js`** reads the manifests, picks the median run per URL, prints the score table, and writes the HTML dashboard.

You only ever run `./run-audit.sh`. It calls the Node script for you at the end.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| **Node.js** and npm | Use the current LTS — v18+ is a safe bet. Lighthouse CI tracks supported Node versions, and older releases will fail to install. Verify: `node -v` |
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

Edit `urls.txt` — one full URL per line. Lines starting with `#` are comments and get skipped.

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
2. Run Lighthouse CI `RUNS` times per URL on **mobile**, then again on **desktop**.
3. Write the HTML dashboard and print a score table to your terminal.
4. Open the run folder when it finishes (macOS via `open`, Linux via `xdg-open`).

Open **`Summary_<domain>.html`** first for the overview. Then follow the Mobile and Desktop links in each row to drill into the full per-page reports.

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
| `RUNS` | `3` | Lighthouse CI runs per URL, per device type. More runs cut variance; fewer runs finish faster. |

The run folder and dashboard take their name from the domain of the **first** URL in your list. You can audit a mixed list of domains, but the folder name reflects whichever URL comes first.

To change the dashboard layout, score display, or opportunity ranking, edit `generate-dashboard.js` directly.

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

`reports/`, `.lighthouseci/`, `lighthouserc.json`, and your `urls.txt` are all gitignored. Your audit output and URL lists stay on your machine — nothing gets committed.

---

## OS support

| OS | Status | Notes |
|---|---|---|
| **macOS** | ✅ Recommended | Works natively with Node.js, Chrome, and `@lhci/cli` installed. |
| **Linux** | ✅ Supported | Install Chrome or Chromium. The results folder opens via `xdg-open` if it's available. |
| **Windows** | ⚠️ Via WSL/Git Bash | Use WSL (recommended) or Git Bash, with Node.js, Chrome, and `@lhci/cli` installed in that environment. |

---

## Project layout

| File | Role |
|---|---|
| `run-audit.sh` | Entry point. Sets up the folder, generates `lighthouserc.json`, runs the audits, and calls the dashboard. |
| `generate-dashboard.js` | Reads the Lighthouse CI manifests, picks the median run per URL, writes the HTML dashboard, and prints the terminal summary. |
| `urls.sample.txt` | Example URL list. Copy it to `urls.txt` to get started. |
| `urls.txt` | Your URL list (gitignored). |
| `lighthouserc.json` | Auto-generated on each run from `urls.txt` and `RUNS`. Don't edit it by hand. |
| `reports/` | All audit output (gitignored). |

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. See the [LICENSE](LICENSE) file for details.

---

## About TEN7

We built and maintain this tool at [TEN7](https://ten7.com), a digital agency that builds, rescues, and cares for Drupal sites. Our mission is to **Make Things That Matter**.

- 🌐 [ten7.com](https://ten7.com)
- 📖 [handbook.ten7.com](https://handbook.ten7.com)
