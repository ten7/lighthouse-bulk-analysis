#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- CONFIGURATION ---
URL_FILE="urls.txt"
RUNS=3
# ---------------------

if [ ! -f "$URL_FILE" ]; then
  echo "❌ Error: $URL_FILE not found."
  exit 1
fi

FIRST_URL=$(grep -m 1 "^http" "$URL_FILE")
DOMAIN=$(echo "$FIRST_URL" | awk -F/ '{print $3}' | sed 's/www.//')
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

RUN_DIR="reports/${TIMESTAMP}_${DOMAIN}"
mkdir -p "$RUN_DIR/mobile"
mkdir -p "$RUN_DIR/desktop"

echo "📂 Created Run Folder: $RUN_DIR"

echo "🔍 Building lighthouserc.json..."

node -e "
const fs = require('fs');
const urls = fs.readFileSync('$URL_FILE', 'utf8')
  .split('\n')
  .map(line => line.trim())
  .filter(line => line.length > 0 && !line.startsWith('#'));

if (urls.length === 0) {
  console.error('❌ No valid URLs found.');
  process.exit(1);
}

const config = {
  ci: {
    collect: {
      url: urls,
      numberOfRuns: $RUNS
    }
  }
};
fs.writeFileSync('lighthouserc.json', JSON.stringify(config, null, 2));
"

echo ""
echo "📱 STARTING MOBILE AUDIT (Default Throttling)..."
echo "   • Runs per URL: $RUNS"
lhci collect --config=lighthouserc.json
lhci upload --target=filesystem --outputDir="./$RUN_DIR/mobile"

rm -rf .lighthouseci
echo ""
echo "🖥️  STARTING DESKTOP AUDIT (Unthrottled)..."
echo "   • Runs per URL: $RUNS"
lhci collect --config=lighthouserc.json --settings.preset=desktop
lhci upload --target=filesystem --outputDir="./$RUN_DIR/desktop"

echo ""
echo "📊 Generating HTML Dashboard inside run folder..."

export REPORT_DIR="./$RUN_DIR"
export REPORT_DOMAIN="$DOMAIN"
export REPORT_TIMESTAMP="$TIMESTAMP"

node "$SCRIPT_DIR/generate-dashboard.js"

echo "✅ Audit Complete."
if command -v open >/dev/null 2>&1; then
  open "$RUN_DIR"
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$RUN_DIR"
fi
