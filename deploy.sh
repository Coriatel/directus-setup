#!/usr/bin/env bash
# ============================================================
#  deploy.sh — מרכז נשמה / חושן יהודה CRM Deployment
#
#  Master script that runs all customization steps in order:
#    1. Apply branding (CSS, logo, project settings)
#    2. Configure collection layouts
#    3. Create dashboards
#
#  Usage:
#    1. Edit .env and set your DIRECTUS_TOKEN
#    2. bash deploy.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Load .env ────────────────────────────────────────────────
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  set -a; source "$SCRIPT_DIR/.env"; set +a
fi

: "${DIRECTUS_URL:?Edit .env and set DIRECTUS_URL}"
: "${DIRECTUS_TOKEN:?Edit .env and set DIRECTUS_TOKEN}"

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║                                              ║"
echo "  ║     מרכז נשמה — CRM Setup & Branding        ║"
echo "  ║     חושן יהודה | ניהול לקוחות ופיננסי       ║"
echo "  ║                                              ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""
echo "  Target: $DIRECTUS_URL"
echo ""

# ── Verify connectivity ─────────────────────────────────────
echo "Verifying API connectivity..."
HTTP_CODE=$(curl -sS -o /dev/null -w "%{http_code}" \
  "$DIRECTUS_URL/server/ping" -H "Authorization: Bearer $DIRECTUS_TOKEN")

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "  ✗ Cannot reach Directus API (HTTP $HTTP_CODE)"
  echo "    Check DIRECTUS_URL and DIRECTUS_TOKEN in .env"
  exit 1
fi
echo "  ✓ API reachable"
echo ""

# ── Step 1: Branding ────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/scripts/apply-branding.sh"

echo ""

# ── Step 2: Collection Layouts ───────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/scripts/configure-layouts.sh"

echo ""

# ── Step 3: Dashboards ──────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/scripts/setup-dashboards.sh"

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║                                              ║"
echo "  ║  ✓  Setup complete!                          ║"
echo "  ║                                              ║"
echo "  ║  Open your CRM:                              ║"
echo "  ║  $DIRECTUS_URL/admin                         ║"
echo "  ║                                              ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""
