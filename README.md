# Lighthouse Bulk Analysis

A lightweight, automated Bash tool that performs bulk Lighthouse audits on a list of URLs. It runs multiple passes (mobile & desktop) to ensure statistical accuracy and generates a consolidated **HTML Dashboard** and **Terminal Summary** comparing performance, accessibility, SEO, and best practices.

## 🚀 Features

* **Bulk Execution:** Reads a list of URLs from a simple text file.
* **Dual Mode:** Audits both Mobile (throttled) and Desktop (unthrottled) environments.
* **Accuracy:** Runs Lighthouse 5 times per URL (configurable) and selects the median run to avoid variance spikes.
* **Visual Reports:** Generates a clean HTML dashboard identifying high-impact opportunities.
* **Data Export:** Saves full Lighthouse HTML reports and JSON data for every run.

## 🤝 Created & Supported by TEN7

This script was created and is actively supported by the team at [TEN7](https://ten7.com).

**TEN7** is a digital agency that builds, rescues, and cares for Drupal sites. Our mission is to **Make Things That Matter**. We are a distributed team of experts, strategists, creators, and doers who lead with empathy and are committed to living our values: Be Honest, Be Inclusive, Be Open, Be Mindful, and Be a Team.

* **Visit our Homepage:** [ten7.com](https://ten7.com)
* **View our Employee Handbook:** [handbook.ten7.com](https://handbook.ten7.com)

**Interested in joining us?**
We are a fully remote company that believes in transparency and open culture. If you are a developer, designer, or strategist looking to do meaningful work, check out our [handbook](https://handbook.ten7.com) to get a sense of what it's like to work at TEN7.

## 📋 Prerequisites

To use this tool, your system must have the following installed:

1.  **Node.js (v14+)**: Required for running the audit engine.
    * *Verify:* `node -v`
2.  **Google Chrome**: The auditing engine requires a browser instance.
    * *macOS/Windows:* Standard installation works.
    * *Linux:* You may need `chromium-browser`.
3.  **Bash Terminal**: Native on macOS/Linux. Windows users see below.

## 🛠 Installation & Setup

1.  **Clone the repository:**
    ```
    git clone https://github.com/ten7/lighthouse-bulk-analysis.git
    cd lighthouse-bulk-analysis
    ```

2.  **Make the generator executable:**
    ```
    chmod +x create.sh
    ```

3.  **Create your URL list:**
    Create a file named `urls.txt` in the root directory. Add one full URL per line.

    *Example `urls.txt`:*
    ```
    https://www.google.com
    https://www.apple.com
    https://www.github.com
    ```

## 🏃 Usage

### Step 1: Generate the Audit Runner
Run the setup script. This validates your environment and creates the `run-audit.sh` executable.

```
./create.sh
```

### Step 2: Run the Audit
Execute the newly created script to start the process.

```
./run-audit.sh
```

*The script will:*
1.  Create a timestamped folder in `./reports/`.
2.  Launch Chrome via Headless Lighthouse.
3.  Test every URL 5 times on Mobile and 5 times on Desktop.
4.  Generate a summary HTML file and open the folder automatically.

## 🖥 Operating System Support

### macOS (Recommended)
Works natively. Ensure you have Node.js installed (e.g., via `brew install node`).

### Linux
Works natively.
* Ensure Chrome or Chromium is installed (`sudo apt install chromium-browser`).
* If running on a server without a display (headless), Lighthouse handles this automatically, but ensure all dependencies for Chrome are present.

### Windows
This is a **Bash** script, so it will not run in standard Command Prompt or PowerShell.

**Option A: WSL (Windows Subsystem for Linux) - Recommended**
1.  Install WSL (Ubuntu).
2.  Install Node.js and Chrome inside the WSL environment.
3.  Run the scripts exactly as shown in the Usage section.

**Option B: Git Bash**
1.  Install [Git for Windows](https://git-scm.com/download/win).
2.  Open "Git Bash".
3.  Run `./create.sh`.
    * *Note:* You must have Node.js installed in Windows and accessible via your PATH.

## 📂 Output Structure

All data is saved in the `reports/` directory:

```
reports/
└── YYYY-MM-DD_DomainName/
    ├── Summary_Domain.html      # <--- Start here (The Dashboard)
    ├── mobile/                  # Raw JSON/HTML files for mobile runs
    └── desktop/                 # Raw JSON/HTML files for desktop runs
```

## ⚙️ Configuration

To change the number of runs (default is 5) or the input filename, you can edit the `create.sh` file directly before running it. Look for the configuration block at the top:

```
# In create.sh
cat << 'EOF' > run-audit.sh
#!/bin/bash

# --- CONFIGURATION ---
URL_FILE="urls.txt"
RUNS=5   <-- Change this value
```

## 📄 License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**.
See the [LICENSE](LICENSE) file for details.