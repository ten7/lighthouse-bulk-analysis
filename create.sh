cat << 'EOF' > run-audit.sh
#!/bin/bash

# --- CONFIGURATION ---
URL_FILE="urls.txt"
RUNS=5
# ---------------------

# 1. Validation
if [ ! -f "$URL_FILE" ]; then
    echo "❌ Error: $URL_FILE not found."
    exit 1
fi

# 2. Get Domain & Timestamp for Naming
FIRST_URL=$(grep -m 1 "^http" "$URL_FILE")
DOMAIN=$(echo "$FIRST_URL" | awk -F/ '{print $3}' | sed 's/www.//')
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# 3. Create Unique Run Directory
RUN_DIR="reports/${TIMESTAMP}_${DOMAIN}"
mkdir -p "$RUN_DIR/mobile"
mkdir -p "$RUN_DIR/desktop"

echo "📂 Created Run Folder: $RUN_DIR"

# 4. Build URL List
echo "🔍 Reading URLs..."
URL_FLAGS=""
count=0
while IFS= read -r url || [ -n "$url" ]; do
    [[ -z "$url" || "$url" =~ ^# ]] && continue
    echo "   - $url"
    URL_FLAGS="$URL_FLAGS --url=$url"
    ((count++))
done < "$URL_FILE"

if [ $count -eq 0 ]; then
    echo "❌ No valid URLs found."
    exit 1
fi

# --- RUN 1: MOBILE AUDIT ---
echo ""
echo "📱 STARTING MOBILE AUDIT (Default Throttling)..."
echo "   • Runs per URL: $RUNS"
lhci collect $URL_FLAGS --numberOfRuns=$RUNS
lhci upload --target=filesystem --outputDir="./$RUN_DIR/mobile"

# --- RUN 2: DESKTOP AUDIT ---
rm -rf .lighthouseci
echo ""
echo "🖥️  STARTING DESKTOP AUDIT (Unthrottled)..."
echo "   • Runs per URL: $RUNS"
lhci collect $URL_FLAGS --numberOfRuns=$RUNS --settings.preset=desktop
lhci upload --target=filesystem --outputDir="./$RUN_DIR/desktop"

# --- STEP 4: GENERATE HTML DASHBOARD ---
echo ""
echo "📊 Generating HTML Dashboard inside run folder..."

export REPORT_DIR="./$RUN_DIR"
export REPORT_DOMAIN="$DOMAIN"
export REPORT_TIMESTAMP="$TIMESTAMP"

cat << 'JS' > compare_results.js
const fs = require('fs');
const path = require('path');

try {
    const runDir = process.env.REPORT_DIR;
    const domain = process.env.REPORT_DOMAIN;
    const timestamp = process.env.REPORT_TIMESTAMP;
    
    const outputPath = path.join(runDir, `Summary_${domain}.html`);

    const loadManifest = (p) => JSON.parse(fs.readFileSync(p, 'utf8'));
    
    const mobilePath = path.join(runDir, 'mobile', 'manifest.json');
    const desktopPath = path.join(runDir, 'desktop', 'manifest.json');

    const mobileData = fs.existsSync(mobilePath) ? loadManifest(mobilePath) : [];
    const desktopData = fs.existsSync(desktopPath) ? loadManifest(desktopPath) : [];

    // --- HELPER FUNCTIONS ---
    const getRepresentativeRun = (data, url) => {
        const runs = data.filter(r => r.url === url);
        if (runs.length === 0) return null;
        runs.sort((a, b) => a.summary.performance - b.summary.performance);
        return runs[Math.floor(runs.length / 2)];
    };

    // Attempt to extract Page Title from LHR
    const getPageTitle = (jsonPath) => {
        try {
            if (!jsonPath || !fs.existsSync(jsonPath)) return null;
            const lhr = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
            // Try getting title from audits
            // Note: 'document-title' audit usually contains the title in 'title' or 'displayValue' logic
            // But strict 'title' often just says "Document has a title".
            // We'll rely on a clean fallback or check specific properties if available.
            // A reliable fallback in LH is often not straightforward without the HTML, 
            // but let's try to parse the URL path if title is generic.
            return null; // For now returning null to force URL path logic, or implement complex parsing
        } catch(e) { return null; }
    };

    const fmt = (val) => val === undefined ? '-' : Math.round(val * 100);
    
    const getScoreClass = (score) => {
        if (score === '-') return 'neutral';
        if (score >= 90) return 'good';
        if (score >= 50) return 'average';
        return 'poor';
    };

    const color = (scoreStr) => {
        const s = parseInt(scoreStr);
        if (isNaN(s)) return '\x1b[37m'; 
        if (s >= 90) return '\x1b[32m'; 
        if (s >= 50) return '\x1b[33m'; 
        return '\x1b[31m'; 
    };
    const reset = '\x1b[0m';
    const dim = '\x1b[2m';

    const urls = [...new Set(mobileData.map(r => r.url))];
    const validMobileRuns = [];
    const validDesktopRuns = [];

    // --- HTML BUILDER ---
    let html = `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Audit: ${domain}</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #f9f9f9; color: #333; margin: 0; padding: 40px; }
            .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); }
            h1 { margin-top: 0; margin-bottom: 5px;}
            .meta { color: #666; font-size: 0.9em; margin-bottom: 20px; padding-bottom: 20px; border-bottom: 1px solid #eee; }
            
            table { width: 100%; border-collapse: collapse; margin-top: 20px; }
            th { text-align: left; padding: 12px; background: #f0f0f0; border-bottom: 2px solid #ddd; font-size: 0.85em; text-transform: uppercase; letter-spacing: 0.5px; }
            td { padding: 12px; border-bottom: 1px solid #eee; vertical-align: middle; }
            
            .score-cell { font-family: 'Courier New', monospace; font-weight: bold; }
            .good { color: #0cce6b; font-weight: bold; }
            .average { color: #ffa400; font-weight: bold; }
            .poor { color: #ff4e42; font-weight: bold; }
            .neutral { color: #ccc; }
            
            .split-score span { display: inline-block; width: 30px; text-align: right; }
            .slash { color: #ccc; margin: 0 4px; }

            .recommendations { margin-top: 40px; padding-top: 20px; border-top: 2px solid #eee; }
            .rec-container { display: flex; gap: 30px; }
            .rec-column { flex: 1; }
            
            .rec-header { display: flex; align-items: center; margin-bottom: 15px; } 
            .rec-header h2 { margin: 0; font-size: 1.1em; }
            .rec-header .tag { margin-left: 10px; padding: 2px 8px; border-radius: 4px; font-size: 0.7em; text-transform: uppercase; font-weight: bold; }
            .tag.mobile { background: #e3f2fd; color: #1565c0; }
            .tag.desktop { background: #f3e5f5; color: #7b1fa2; }

            .rec-item { margin-bottom: 10px; padding: 12px; background: #f8f9fa; border-left: 4px solid #333; border-radius: 4px; }
            .rec-title { font-weight: bold; font-size: 0.95em; color: #222; }
            .rec-impact { color: #666; margin-top: 4px; font-size: 0.85em; }
            .rec-badge { background: #e0e0e0; padding: 2px 6px; border-radius: 4px; font-size: 0.8em; margin-right: 8px; }
            
            .folder-path { font-family: monospace; background: #eee; padding: 2px 5px; border-radius: 3px; }
            .page-title { font-weight: 600; display: block; margin-bottom: 2px; }
            .page-url { font-size: 0.8em; color: #888; text-decoration: none; font-family: monospace;}
            .report-links { font-size: 0.8em; margin-top: 4px; }
            .report-links a { color: #0066cc; text-decoration: none; }
            .report-links a:hover { text-decoration: underline; }
            .separator { color: #ccc; margin: 0 4px; }

            @media (max-width: 800px) {
                .rec-container { flex-direction: column; }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Lighthouse Audit Report</h1>
            <div class="meta">
                Run ID: <span class="folder-path">${timestamp}</span> &bull; 
                Domain: <strong>${domain}</strong> &bull; 
                Pages: ${urls.length}
            </div>

            <table>
                <thead>
                    <tr>
                        <th width="40%">Page</th>
                        <th>Performance</th>
                        <th>Accessibility</th>
                        <th>Best Prac</th>
                        <th>SEO</th>
                    </tr>
                </thead>
                <tbody>
    `;

    console.log("");
    console.log("------------------------------------------------------------------------------------------------");
    console.log(`| URL (Mobile / Desktop)               | ${dim}Perf${reset}      | ${dim}Access${reset}    | ${dim}BestPrac${reset}  | ${dim}SEO${reset}       |`);
    console.log("|--------------------------------------|-----------|-----------|-----------|-----------|");

    urls.forEach(url => {
        const mRun = getRepresentativeRun(mobileData, url);
        const dRun = getRepresentativeRun(desktopData, url);
        
        if (mRun) validMobileRuns.push(mRun.jsonPath);
        if (dRun) validDesktopRuns.push(dRun.jsonPath);

        const mP = mRun ? fmt(mRun.summary.performance) : '-';
        const mA = mRun ? fmt(mRun.summary.accessibility) : '-';
        const mB = mRun ? fmt(mRun.summary['best-practices']) : '-';
        const mS = mRun ? fmt(mRun.summary.seo) : '-';
        const dP = dRun ? fmt(dRun.summary.performance) : '-';
        const dA = dRun ? fmt(dRun.summary.accessibility) : '-';
        const dB = dRun ? fmt(dRun.summary['best-practices']) : '-';
        const dS = dRun ? fmt(dRun.summary.seo) : '-';

        let shortUrl = url.replace('https://', '').replace('http://', '').replace('www.', '');
        const cleanShortUrl = shortUrl.length > 34 ? shortUrl.substring(0, 31) + '...' : shortUrl;
        
        // Try to get a nicer title from URL structure since LHR title is unreliable
        const urlObj = new URL(url);
        let niceTitle = urlObj.pathname === '/' ? 'Home' : urlObj.pathname.replace(/\//g, ' ').trim();
        if(!niceTitle) niceTitle = "Home";
        // Capitalize words
        niceTitle = niceTitle.replace(/\b\w/g, l => l.toUpperCase());

        // Console
        const printCell = (m, d) => `${color(m)}${String(m).padStart(3)}${reset}/${color(d)}${String(d).padEnd(3)}${reset}`;
        console.log(`| ${cleanShortUrl.padEnd(36)} | ${printCell(mP, dP)} | ${printCell(mA, dA)} | ${printCell(mB, dB)} | ${printCell(mS, dS)} |`);

        // HTML
        const htmlCell = (m, d) => `
            <div class="split-score">
                <span class="${getScoreClass(m)}">${m}</span><span class="slash">/</span><span class="${getScoreClass(d)}">${d}</span>
            </div>`;
        
        const mLink = mRun ? `<a href="mobile/${path.basename(mRun.htmlPath)}" target="_blank">Mobile</a>` : '<span style="color:#ccc">Mobile</span>';
        const dLink = dRun ? `<a href="desktop/${path.basename(dRun.htmlPath)}" target="_blank">Desktop</a>` : '<span style="color:#ccc">Desktop</span>';
        
        html += `
            <tr>
                <td>
                    <span class="page-title">${niceTitle}</span>
                    <a href="${url}" target="_blank" class="page-url">${url}</a>
                    <div class="report-links">
                        (view ${mLink} <span class="separator">|</span> ${dLink} report)
                    </div>
                </td>
                <td>${htmlCell(mP, dP)}</td>
                <td>${htmlCell(mA, dA)}</td>
                <td>${htmlCell(mB, dB)}</td>
                <td>${htmlCell(mS, dS)}</td>
            </tr>`;
    });
    console.log("------------------------------------------------------------------------------------------------");

    html += `</tbody></table>`;

    // --- OPPORTUNITY CALCULATOR ---
    const getTopOpportunities = (filePaths, limit = 5) => {
        let opportunities = {};
        filePaths.forEach(jsonPath => {
            try {
                const report = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
                const audits = report.audits;
                for (const [id, audit] of Object.entries(audits)) {
                    if (audit.score !== 1 && audit.details && audit.details.overallSavingsMs > 0) {
                        if (!opportunities[id]) {
                            opportunities[id] = { title: audit.title, totalSavings: 0 };
                        }
                        opportunities[id].totalSavings += audit.details.overallSavingsMs;
                    }
                }
            } catch(e) {}
        });

        return Object.values(opportunities)
            .sort((a, b) => b.totalSavings - a.totalSavings)
            .slice(0, limit);
    };

    const renderRecommendations = (title, type, items) => {
        // Console output (Sequential)
        console.log(`\n🚀 \x1b[1m${title}\x1b[0m`);
        
        let sectionHtml = `
            <div class="rec-column">
                <div class="rec-header"><h2>${title}</h2><span class="tag ${type}">${type}</span></div>
        `;
        
        if (items.length === 0) {
            console.log("   🎉 No major performance issues found!");
            sectionHtml += `<p>🎉 No major performance issues found!</p></div>`;
            return sectionHtml;
        }

        items.forEach((op, index) => {
            const seconds = (op.totalSavings / 1000).toFixed(2);
            console.log(`   ${index + 1}. \x1b[36m${op.title}\x1b[0m (~${seconds}s)`);

            sectionHtml += `
                <div class="rec-item">
                    <div class="rec-title"><span class="rec-badge">#${index+1}</span> ${op.title}</div>
                    <div class="rec-impact">Potential savings: <strong>~${seconds}s</strong> cumulative.</div>
                </div>`;
        });
        
        sectionHtml += `</div>`;
        return sectionHtml;
    };

    html += `<div class="recommendations"><div class="rec-container">`;
    
    // Mobile Recs
    const mobileOps = getTopOpportunities(validMobileRuns, 5);
    html += renderRecommendations("Top 5 Actions", "mobile", mobileOps);

    // Desktop Recs
    const desktopOps = getTopOpportunities(validDesktopRuns, 5);
    html += renderRecommendations("Top 5 Actions", "desktop", desktopOps);

    html += `</div></div></div></body></html>`;

    fs.writeFileSync(outputPath, html);
    console.log("");
    console.log(`📄 \x1b[32mHTML Summary created: ${outputPath}\x1b[0m`);
    console.log("");

} catch (e) {
    console.error("Error generating comparison:", e);
}
JS

node compare_results.js
rm compare_results.js

echo "✅ Audit Complete."
open "$RUN_DIR"
EOF

chmod +x run-audit.sh