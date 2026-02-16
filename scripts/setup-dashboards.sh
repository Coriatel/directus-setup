#!/usr/bin/env bash
# ============================================================
#  setup-dashboards.sh — Create CRM & Financial dashboards
#  for מרכז נשמה Directus CRM.
#
#  Usage:
#    export DIRECTUS_URL=https://crm.merkazneshama.co.il
#    export DIRECTUS_TOKEN=<admin-static-token>
#    bash scripts/setup-dashboards.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# ── Load .env if present ─────────────────────────────────────
if [[ -f "$PROJECT_DIR/.env" ]]; then
  set -a; source "$PROJECT_DIR/.env"; set +a
fi

: "${DIRECTUS_URL:?Set DIRECTUS_URL}"
: "${DIRECTUS_TOKEN:?Set DIRECTUS_TOKEN}"

API="$DIRECTUS_URL"
AUTH="Authorization: Bearer $DIRECTUS_TOKEN"
CT="Content-Type: application/json"

echo "══════════════════════════════════════════════════"
echo "  מרכז נשמה — Dashboard Setup"
echo "══════════════════════════════════════════════════"
echo ""

# ── Helper ───────────────────────────────────────────────────
api_post() {
  local endpoint="$1"
  shift
  curl -sS -X POST "$API/$endpoint" \
    -H "$AUTH" -H "$CT" "$@"
}

extract_id() {
  python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])"
}

# ════════════════════════════════════════════════════════════════
#  DASHBOARD 1: סקירת CRM — CRM Overview
# ════════════════════════════════════════════════════════════════
echo "[1/2] Creating CRM Overview dashboard..."

DASH1=$(api_post "dashboards" -d '{
  "name": "סקירת CRM",
  "icon": "dashboard",
  "note": "סקירה כללית של אנשי קשר, אינטראקציות ופעילות במערכת",
  "color": "#0F4C5C"
}' | extract_id)

if [[ -z "$DASH1" || "$DASH1" == "null" ]]; then
  echo "  ✗ Failed to create CRM dashboard"
  exit 1
fi
echo "  ✓ Dashboard created: $DASH1"

# ── Panel: Total Contacts ────────────────────────────────────
echo "  Adding panels..."
api_post "panels" -d "{
  \"dashboard\": \"$DASH1\",
  \"name\": \"סה\\\"כ אנשי קשר\",
  \"icon\": \"contacts\",
  \"color\": \"#0F4C5C\",
  \"type\": \"metric\",
  \"position_x\": 1,
  \"position_y\": 1,
  \"width\": 8,
  \"height\": 6,
  \"note\": \"מספר אנשי הקשר הכולל במערכת\",
  \"options\": {
    \"collection\": \"contacts\",
    \"function\": \"count\",
    \"sortField\": \"id\",
    \"filter\": {}
  }
}" > /dev/null 2>&1 && echo "    ✓ סה\"כ אנשי קשר" || echo "    ⚠ סה\"כ אנשי קשר — skipped"

# ── Panel: Total Interactions ────────────────────────────────
api_post "panels" -d "{
  \"dashboard\": \"$DASH1\",
  \"name\": \"סה\\\"כ אינטראקציות\",
  \"icon\": \"forum\",
  \"color\": \"#1A6B7A\",
  \"type\": \"metric\",
  \"position_x\": 9,
  \"position_y\": 1,
  \"width\": 8,
  \"height\": 6,
  \"note\": \"מספר האינטראקציות הכולל\",
  \"options\": {
    \"collection\": \"interactions\",
    \"function\": \"count\",
    \"sortField\": \"id\",
    \"filter\": {}
  }
}" > /dev/null 2>&1 && echo "    ✓ סה\"כ אינטראקציות" || echo "    ⚠ סה\"כ אינטראקציות — skipped"

# ── Panel: Total Transactions ────────────────────────────────
api_post "panels" -d "{
  \"dashboard\": \"$DASH1\",
  \"name\": \"סה\\\"כ עסקאות\",
  \"icon\": \"payments\",
  \"color\": \"#C8842B\",
  \"type\": \"metric\",
  \"position_x\": 17,
  \"position_y\": 1,
  \"width\": 8,
  \"height\": 6,
  \"note\": \"מספר העסקאות הכולל\",
  \"options\": {
    \"collection\": \"transactions\",
    \"function\": \"count\",
    \"sortField\": \"id\",
    \"filter\": {}
  }
}" > /dev/null 2>&1 && echo "    ✓ סה\"כ עסקאות" || echo "    ⚠ סה\"כ עסקאות — skipped"

# ── Panel: Recent Contacts (List) ────────────────────────────
api_post "panels" -d "{
  \"dashboard\": \"$DASH1\",
  \"name\": \"אנשי קשר אחרונים\",
  \"icon\": \"person_add\",
  \"color\": \"#0F4C5C\",
  \"type\": \"list\",
  \"position_x\": 1,
  \"position_y\": 7,
  \"width\": 12,
  \"height\": 12,
  \"note\": \"אנשי קשר שנוספו לאחרונה\",
  \"options\": {
    \"collection\": \"contacts\",
    \"sort\": \"-date_created\",
    \"limit\": 10,
    \"displayTemplate\": \"{{first_name}} {{last_name}} — {{phone}}\",
    \"filter\": {}
  }
}" > /dev/null 2>&1 && echo "    ✓ אנשי קשר אחרונים" || echo "    ⚠ אנשי קשר אחרונים — skipped"

# ── Panel: Recent Interactions (List) ────────────────────────
api_post "panels" -d "{
  \"dashboard\": \"$DASH1\",
  \"name\": \"אינטראקציות אחרונות\",
  \"icon\": \"history\",
  \"color\": \"#1A6B7A\",
  \"type\": \"list\",
  \"position_x\": 13,
  \"position_y\": 7,
  \"width\": 12,
  \"height\": 12,
  \"note\": \"אינטראקציות שנוצרו לאחרונה\",
  \"options\": {
    \"collection\": \"interactions\",
    \"sort\": \"-date_created\",
    \"limit\": 10,
    \"displayTemplate\": \"{{type}} — {{notes}}\",
    \"filter\": {}
  }
}" > /dev/null 2>&1 && echo "    ✓ אינטראקציות אחרונות" || echo "    ⚠ אינטראקציות אחרונות — skipped"

# ── Panel: Contacts by Tag (Label) ───────────────────────────
api_post "panels" -d "{
  \"dashboard\": \"$DASH1\",
  \"name\": \"אנשי קשר לפי תגית\",
  \"icon\": \"label\",
  \"color\": \"#7B61C4\",
  \"type\": \"relational-variable\",
  \"position_x\": 1,
  \"position_y\": 19,
  \"width\": 24,
  \"height\": 6,
  \"note\": \"התפלגות אנשי קשר לפי תגיות\",
  \"options\": {
    \"collection\": \"tags\",
    \"displayTemplate\": \"{{name}}\",
    \"filter\": {}
  }
}" > /dev/null 2>&1 && echo "    ✓ אנשי קשר לפי תגית" || echo "    ⚠ אנשי קשר לפי תגית — skipped"

echo "  ✓ CRM Overview dashboard complete"

# ════════════════════════════════════════════════════════════════
#  DASHBOARD 2: סקירה פיננסית — Financial Overview
# ════════════════════════════════════════════════════════════════
echo ""
echo "[2/2] Creating Financial Overview dashboard..."

DASH2=$(api_post "dashboards" -d '{
  "name": "סקירה פיננסית",
  "icon": "account_balance",
  "note": "סקירה פיננסית: עסקאות, תשלומים, קבלות ושורות בנק",
  "color": "#C8842B"
}' | extract_id)

if [[ -z "$DASH2" || "$DASH2" == "null" ]]; then
  echo "  ✗ Failed to create Financial dashboard"
  exit 1
fi
echo "  ✓ Dashboard created: $DASH2"

echo "  Adding panels..."

# ── Panel: Total Transaction Amount ──────────────────────────
api_post "panels" -d "{
  \"dashboard\": \"$DASH2\",
  \"name\": \"סכום עסקאות כולל\",
  \"icon\": \"account_balance_wallet\",
  \"color\": \"#C8842B\",
  \"type\": \"metric\",
  \"position_x\": 1,
  \"position_y\": 1,
  \"width\": 8,
  \"height\": 6,
  \"note\": \"סך כל העסקאות בש\\\"ח\",
  \"options\": {
    \"collection\": \"transactions\",
    \"function\": \"sum\",
    \"field\": \"amount\",
    \"sortField\": \"amount\",
    \"filter\": {}
  }
}" > /dev/null 2>&1 && echo "    ✓ סכום עסקאות כולל" || echo "    ⚠ סכום עסקאות כולל — skipped"

# ── Panel: Transaction Count ─────────────────────────────────
api_post "panels" -d "{
  \"dashboard\": \"$DASH2\",
  \"name\": \"מספר עסקאות\",
  \"icon\": \"receipt\",
  \"color\": \"#0F4C5C\",
  \"type\": \"metric\",
  \"position_x\": 9,
  \"position_y\": 1,
  \"width\": 8,
  \"height\": 6,
  \"note\": \"מספר העסקאות הכולל\",
  \"options\": {
    \"collection\": \"transactions\",
    \"function\": \"count\",
    \"sortField\": \"id\",
    \"filter\": {}
  }
}" > /dev/null 2>&1 && echo "    ✓ מספר עסקאות" || echo "    ⚠ מספר עסקאות — skipped"

# ── Panel: Receipt Count ─────────────────────────────────────
api_post "panels" -d "{
  \"dashboard\": \"$DASH2\",
  \"name\": \"סה\\\"כ קבלות\",
  \"icon\": \"receipt_long\",
  \"color\": \"#2D8659\",
  \"type\": \"metric\",
  \"position_x\": 17,
  \"position_y\": 1,
  \"width\": 8,
  \"height\": 6,
  \"note\": \"מספר הקבלות שהופקו\",
  \"options\": {
    \"collection\": \"receipts\",
    \"function\": \"count\",
    \"sortField\": \"id\",
    \"filter\": {}
  }
}" > /dev/null 2>&1 && echo "    ✓ סה\"כ קבלות" || echo "    ⚠ סה\"כ קבלות — skipped"

# ── Panel: Recent Transactions (List) ────────────────────────
api_post "panels" -d "{
  \"dashboard\": \"$DASH2\",
  \"name\": \"עסקאות אחרונות\",
  \"icon\": \"payments\",
  \"color\": \"#C8842B\",
  \"type\": \"list\",
  \"position_x\": 1,
  \"position_y\": 7,
  \"width\": 12,
  \"height\": 12,
  \"note\": \"עסקאות שנוצרו לאחרונה\",
  \"options\": {
    \"collection\": \"transactions\",
    \"sort\": \"-date_created\",
    \"limit\": 10,
    \"displayTemplate\": \"{{amount}} ₪ — {{contact_id.first_name}} {{contact_id.last_name}}\",
    \"filter\": {}
  }
}" > /dev/null 2>&1 && echo "    ✓ עסקאות אחרונות" || echo "    ⚠ עסקאות אחרונות — skipped"

# ── Panel: Recent Receipts (List) ────────────────────────────
api_post "panels" -d "{
  \"dashboard\": \"$DASH2\",
  \"name\": \"קבלות אחרונות\",
  \"icon\": \"description\",
  \"color\": \"#2D8659\",
  \"type\": \"list\",
  \"position_x\": 13,
  \"position_y\": 7,
  \"width\": 12,
  \"height\": 12,
  \"note\": \"קבלות שהופקו לאחרונה\",
  \"options\": {
    \"collection\": \"receipts\",
    \"sort\": \"-date_created\",
    \"limit\": 10,
    \"displayTemplate\": \"קבלה #{{id}} — {{amount}} ₪\",
    \"filter\": {}
  }
}" > /dev/null 2>&1 && echo "    ✓ קבלות אחרונות" || echo "    ⚠ קבלות אחרונות — skipped"

# ── Panel: Recent Bank Rows (List) ───────────────────────────
api_post "panels" -d "{
  \"dashboard\": \"$DASH2\",
  \"name\": \"שורות בנק אחרונות\",
  \"icon\": \"account_balance\",
  \"color\": \"#0A3540\",
  \"type\": \"list\",
  \"position_x\": 1,
  \"position_y\": 19,
  \"width\": 12,
  \"height\": 10,
  \"note\": \"שורות בנק שנוספו לאחרונה\",
  \"options\": {
    \"collection\": \"bank_rows\",
    \"sort\": \"-date_created\",
    \"limit\": 10,
    \"filter\": {}
  }
}" > /dev/null 2>&1 && echo "    ✓ שורות בנק אחרונות" || echo "    ⚠ שורות בנק אחרונות — skipped"

# ── Panel: Payment Events (List) ─────────────────────────────
api_post "panels" -d "{
  \"dashboard\": \"$DASH2\",
  \"name\": \"אירועי תשלום אחרונים\",
  \"icon\": \"bolt\",
  \"color\": \"#E8A840\",
  \"type\": \"list\",
  \"position_x\": 13,
  \"position_y\": 19,
  \"width\": 12,
  \"height\": 10,
  \"note\": \"אירועי תשלום גולמיים מ-Takbul\",
  \"options\": {
    \"collection\": \"payment_events_raw\",
    \"sort\": \"-date_created\",
    \"limit\": 10,
    \"filter\": {}
  }
}" > /dev/null 2>&1 && echo "    ✓ אירועי תשלום אחרונים" || echo "    ⚠ אירועי תשלום אחרונים — skipped"

echo "  ✓ Financial Overview dashboard complete"

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✓ Both dashboards created successfully!"
echo ""
echo "  1. סקירת CRM:      $API/admin/insights/$DASH1"
echo "  2. סקירה פיננסית:   $API/admin/insights/$DASH2"
echo "══════════════════════════════════════════════════"
