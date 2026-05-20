# Lighthouse Bulk Analysis

A lightweight tool that runs bulk Lighthouse audits on a list of URLs. It uses [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci) for collection, runs multiple passes per URL on mobile and desktop, and produces a consolidated **HTML dashboard** plus a **terminal summary** for performance, accessibility, SEO, and best practices.


https://github.com/user-attachments/assets/418fd04c-a9eb-4edc-a21f-be5e400801b3


## Features

* **Bulk execution:** Reads URLs from a plain text file (`urls.txt`).
* **Dual mode:** Mobile (default throttling) and desktop (`--settings.preset=desktop`) in one run.
* **Variance control:** Multiple Lighthouse runs per URL (default 3, configurable); the dashboard uses the **median run by performance score** for each URL.
* **HTML dashboard:** `Summary_<domain>.html` with mobile/desktop scores, links to full reports, and top performance opportunities.
* **Terminal summary:** Score table and top recommendations printed while the audit runs.
* **Raw artifacts:** Full Lighthouse HTML and JSON for every run, organized under `reports/`.

## How it works

1. **`run-audit.sh`** reads `urls.txt`, writes a fresh `lighthouserc.json`, and runs `lhci collect` + `lhci upload` for mobile, then again for desktop.
2. Results land in a timestamped folder under `reports/` (`mobile/` and `desktop/` subfolders).
3. **`generate-dashboard.js`** reads the Lighthouse CI manifests, picks the median run per URL, prints the terminal table, and writes `Summary_<domain>.html`.

You only run `./run-audit.sh`; the Node script is invoked automatically.

## Project layout

| File | Role |
|------|------|
| `run-audit.sh` | Entry point: audits, folder setup, calls the dashboard generator |
| `generate-dashboard.js` | Builds the HTML summary and terminal output from manifests |
| `urls.sample.txt` | Example URL list (copy to `urls.txt` to get started) |
| `urls.txt` | Your URL list (gitignored; not committed) |
| `lighthouserc.json` | Generated on each run from `urls.txt` and `RUNS` — do not edit by hand for normal use |
| `reports/` | Audit output (gitignored) |

## Created & supported by TEN7

This tool was created and is actively supported by the team at [TEN7](https://ten7.com).

**TEN7** is a digital agency that builds, rescues, and cares for Drupal sites. Our mission is to **Make Things That Matter**. We are a distributed team of experts, strategists, creators, and doers who lead with empathy and are committed to living our values: Be Honest, Be Inclusive, Be Open, Be Mindful, and Be a Team.

* **Visit our homepage:** [ten7.com](https://ten7.com)
* **View our employee handbook:** [handbook.ten7.com](https://handbook.ten7.com)

**Interested in joining us?**
We are a fully remote company that believes in transparency and open culture. If you are a developer, designer, or strategist looking to do meaningful work, check out our [handbook](https://handbook.ten7.com) to get a sense of what it's like to work at TEN7.

## Prerequisites

1. **Node.js (v14+) & npm** — used to generate `lighthouserc.json` and run the dashboard script.
   * Verify: `node -v`
2. **Lighthouse CI CLI (`@lhci/cli`)** — provides the `lhci` command.
   * Verify: `lhci --version`
3. **Google Chrome** — required by the Lighthouse engine.
   * macOS/Windows: standard install.
   * Linux: Chrome or Chromium (`sudo apt install chromium-browser`).
4. **Bash** — macOS and Linux natively; on Windows use WSL or Git Bash.

## Installation & setup

1. **Clone the repository:**

    ```bash
    git clone https://github.com/ten7/lighthouse-bulk-analysis.git
    cd lighthouse-bulk-analysis
    ```

2. **Install Lighthouse CI globally:**

    ```bash
    npm install -g @lhci/cli
    ```

3. **Make the audit script executable:**

    ```bash
    chmod +x run-audit.sh
    ```

4. **Create your URL list:**

    ```bash
    cp urls.sample.txt urls.txt
    ```

    Edit `urls.txt`: one full URL per line. Lines starting with `#` are ignored.

    Example:

    ```
    # Production pages
    https://www.example.com/
    https://www.example.com/about
    ```

## Usage

From the project root (with `urls.txt` in place):

```bash
./run-audit.sh
```

The script will:

1. Create `reports/YYYY-MM-DD_HH-MM-SS_<domain>/` (domain taken from the first `http` URL in the list).
2. Run Lighthouse CI for every URL on mobile, then desktop (`RUNS` times each).
3. Write `Summary_<domain>.html` and print a score table in the terminal.
4. Open the run folder with `open` (macOS) or `xdg-open` (Linux), if available.

Open **`Summary_<domain>.html`** first; use the Mobile/Desktop links in each row for full Lighthouse reports.

## Operating system support

### macOS (recommended)

Works natively with Node.js, Chrome, and `@lhci/cli` installed.

### Linux

Works natively. Install Chrome or Chromium. The script uses `xdg-open` when present to open the results folder; otherwise open `reports/` manually.

### Windows

This is a Bash workflow — use **WSL (recommended)** or **Git Bash**, with Node.js, Chrome, and `@lhci/cli` installed in that environment. Run `./run-audit.sh` the same way as on macOS/Linux.

## Output structure

Each run creates a folder under `reports/`:

```
reports/
└── YYYY-MM-DD_HH-MM-SS_example.com/
    ├── Summary_example.com.html   # Start here — dashboard
    ├── mobile/
    │   ├── manifest.json          # Lighthouse CI index for mobile runs
    │   └── *.report.html / *.report.json
    └── desktop/
        ├── manifest.json
        └── *.report.html / *.report.json
```

`reports/` and `.lighthouseci/` are gitignored. Only your local `urls.txt` and generated reports stay on disk.

## Configuration

Edit the block at the top of **`run-audit.sh`**:

```bash
# --- CONFIGURATION ---
URL_FILE="urls.txt"
RUNS=3
```

* **`URL_FILE`** — path to the URL list.
* **`RUNS`** — Lighthouse CI `numberOfRuns` per URL per device type.

For dashboard layout, scoring display, or opportunity ranking, edit **`generate-dashboard.js`**.

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**.
See the [LICENSE](LICENSE) file for details.
