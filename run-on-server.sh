#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
#  מרכז נשמה / חושן יהודה — Directus CRM Full Setup
#
#  Copy-paste this ENTIRE script into your VPS SSH terminal.
#  It will apply branding, layouts, and create 2 dashboards.
# ════════════════════════════════════════════════════════════════
set -euo pipefail

API="http://127.0.0.1:18055"
TOKEN="0aabca51-35cf-4c8d-b817-9f7c585bc426"
AUTH="Authorization: Bearer $TOKEN"
CT="Content-Type: application/json"

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║     מרכז נשמה — CRM Setup & Branding        ║"
echo "  ║     חושן יהודה | ניהול לקוחות ופיננסי       ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""

# ── Verify connectivity ─────────────────────────────────────
echo "→ Verifying API..."
HTTP_CODE=$(curl -sS -o /dev/null -w "%{http_code}" "$API/server/ping" -H "$AUTH")
if [[ "$HTTP_CODE" != "200" ]]; then
  echo "  ✗ Cannot reach Directus (HTTP $HTTP_CODE). Check token."
  exit 1
fi
echo "  ✓ Connected"

# ════════════════════════════════════════════════════════════════
#  STEP 1: CUSTOM CSS + PROJECT SETTINGS
# ════════════════════════════════════════════════════════════════
echo ""
echo "━━━ [1/4] Applying branding & custom CSS ━━━"

CUSTOM_CSS=$(cat <<'CSSEOF'
:root {
  --project-color: #0F4C5C !important;
  --primary: #0F4C5C !important;
  --primary-alt: #0D3F4D !important;
  --primary-10: rgba(15, 76, 92, 0.1) !important;
  --primary-25: rgba(15, 76, 92, 0.25) !important;
  --primary-50: rgba(15, 76, 92, 0.5) !important;
  --primary-75: rgba(15, 76, 92, 0.75) !important;
  --primary-90: rgba(15, 76, 92, 0.9) !important;
  --secondary: #C8842B !important;
  --secondary-10: rgba(200, 132, 43, 0.1) !important;
  --secondary-25: rgba(200, 132, 43, 0.25) !important;
  --secondary-50: rgba(200, 132, 43, 0.5) !important;
  --success: #2D8659 !important;
  --warning: #D4922A !important;
  --danger: #B94444 !important;
  --background-page: #FAF7F2 !important;
  --background-normal: #F0EBE3 !important;
  --background-highlight: #E8E2D8 !important;
  --background-subdued: #F5F1EB !important;
  --background-normal-alt: #EDE7DE !important;
  --foreground-normal: #1A2E3B !important;
  --foreground-subdued: #5A6B78 !important;
  --foreground-inverted: #FAF7F2 !important;
  --border-normal: #D6CEBC !important;
  --border-subdued: #E3DCD0 !important;
  --module-background: #0A3540 !important;
  --module-icon: #A0C4CC !important;
  --module-background-alt: #0F4C5C !important;
}
#navigation .module-bar, .module-bar { background-color: #0A3540 !important; }
.module-bar .v-icon { color: #8FB8C4 !important; }
.module-bar .v-icon:hover, .module-bar .v-icon.router-link-active { color: #E8A840 !important; }
.module-bar-logo .custom-logo img, .module-bar-logo .default-logo { filter: brightness(0) invert(1) !important; }
#navigation .module-nav { background-color: #FFFFFF !important; border-left: 1px solid #E3DCD0 !important; }
.header-bar { background-color: #FFFFFF !important; border-bottom: 2px solid #0F4C5C !important; }
.header-bar .title .type-title { color: #1A2E3B !important; font-weight: 700 !important; }
.v-button.primary, .v-button[kind="primary"] {
  --v-button-background-color: #0F4C5C !important;
  --v-button-background-color-hover: #C8842B !important;
  --v-button-color: #FFFFFF !important;
  --v-button-color-hover: #FFFFFF !important;
}
.v-button.secondary, .v-button[kind="secondary"] {
  --v-button-background-color: #C8842B !important;
  --v-button-background-color-hover: #A06820 !important;
  --v-button-color: #FFFFFF !important;
}
.v-table .table-row { border-bottom: 1px solid #E3DCD0 !important; }
.v-table .table-row:nth-child(even) { background-color: #FAF7F2 !important; }
.v-table .table-row:nth-child(odd) { background-color: #FFFFFF !important; }
.v-table .table-row:hover { background-color: #E8E2D8 !important; }
.v-table .table-row td { padding-top: 12px !important; padding-bottom: 12px !important; }
.v-table .table-header { background-color: #0F4C5C !important; color: #FFFFFF !important; font-weight: 600 !important; }
.v-table .table-header .cell-content { color: #FFFFFF !important; }
.v-table .table-header .v-icon { color: #A0C4CC !important; }
.layout-cards .card {
  border: 1px solid #D6CEBC !important; border-radius: 8px !important;
  box-shadow: 0 1px 3px rgba(15,76,92,0.08) !important;
  transition: box-shadow 0.2s ease, border-color 0.2s ease !important;
}
.layout-cards .card:hover { border-color: #C8842B !important; box-shadow: 0 4px 12px rgba(200,132,43,0.15) !important; }
.detail-item .field-label { color: #0F4C5C !important; font-weight: 600 !important; }
.v-form .field .interface .input { border-color: #D6CEBC !important; }
.v-form .field .interface .input:focus-within { border-color: #C8842B !important; box-shadow: 0 0 0 2px rgba(200,132,43,0.2) !important; }
.sidebar-detail { border-right: 1px solid #E3DCD0 !important; }
.sidebar-detail .title { color: #0F4C5C !important; }
.panel-header { background: linear-gradient(135deg, #0F4C5C 0%, #1A6B7A 100%) !important; color: #FFFFFF !important; border-radius: 8px 8px 0 0 !important; }
.panel { border: 1px solid #D6CEBC !important; border-radius: 8px !important; box-shadow: 0 1px 4px rgba(15,76,92,0.06) !important; }
.v-chip { border-radius: 16px !important; }
.v-chip.primary { background-color: rgba(15,76,92,0.12) !important; color: #0F4C5C !important; }
::-webkit-scrollbar { width: 8px; height: 8px; }
::-webkit-scrollbar-track { background: #F0EBE3; border-radius: 4px; }
::-webkit-scrollbar-thumb { background: #B0A898; border-radius: 4px; }
::-webkit-scrollbar-thumb:hover { background: #0F4C5C; }
.v-tabs .v-tab.active { color: #0F4C5C !important; border-bottom-color: #C8842B !important; }
.drawer { background-color: #FFFFFF !important; border-right: 2px solid #0F4C5C !important; }
.content .layout { padding: 16px 24px !important; }
.search-input .input { border-radius: 8px !important; border: 1px solid #D6CEBC !important; }
.search-input .input:focus-within { border-color: #0F4C5C !important; box-shadow: 0 0 0 2px rgba(15,76,92,0.15) !important; }
#app .public-view .container .content { background-color: #FFFFFF !important; border: 1px solid #D6CEBC !important; border-radius: 12px !important; box-shadow: 0 8px 32px rgba(15,76,92,0.12) !important; }
.public-view { background: linear-gradient(135deg, #0A3540 0%, #0F4C5C 40%, #1A6B7A 100%) !important; }
.public-view .project-name { color: #0F4C5C !important; font-size: 1.5rem !important; font-weight: 700 !important; }
html[dir="rtl"] .v-table .table-row td, html[dir="rtl"] .v-table .table-header th { text-align: right !important; }
html[dir="rtl"] .header-bar .title { text-align: right !important; }
.interface-input-hash-masked .input, [data-collection="transactions"] .v-table td:nth-child(n), [data-collection="receipts"] .v-table td:nth-child(n) { font-variant-numeric: tabular-nums !important; font-feature-settings: "tnum" 1 !important; }
.status-dot.active, .status-dot.published { background-color: #2D8659 !important; }
.status-dot.draft { background-color: #D4922A !important; }
.status-dot.archived { background-color: #8A8A8A !important; }
.v-menu-popper { border: 1px solid #D6CEBC !important; border-radius: 8px !important; box-shadow: 0 4px 16px rgba(15,76,92,0.1) !important; }
.v-info .v-icon { color: #C8842B !important; }
.v-dialog .v-card { border-radius: 12px !important; border: 1px solid #D6CEBC !important; }
.v-dialog .v-card .v-card-title { background-color: #0F4C5C !important; color: #FFFFFF !important; }
.action-bar { background-color: #0F4C5C !important; color: #FFFFFF !important; border-radius: 8px !important; }
.bookmark .v-icon { color: #C8842B !important; }
CSSEOF
)

# Build JSON with Python
SETTINGS_JSON=$(python3 -c "
import json, sys
css = sys.stdin.read()
print(json.dumps({
    'project_name': 'מרכז נשמה — ניהול לקוחות',
    'project_descriptor': 'חושן יהודה | CRM',
    'project_color': '#0F4C5C',
    'default_language': 'he-IL',
    'custom_css': css
}, ensure_ascii=False))
" <<< "$CUSTOM_CSS")

curl -sS -X PATCH "$API/settings" -H "$AUTH" -H "$CT" -d "$SETTINGS_JSON" > /dev/null 2>&1
echo "  ✓ Project settings + custom CSS applied"
echo "    • Name: מרכז נשמה — ניהול לקוחות"
echo "    • Color: #0F4C5C (Deep Teal)"
echo "    • Descriptor: חושן יהודה | CRM"

# ════════════════════════════════════════════════════════════════
#  STEP 2: COLLECTION METADATA (icons, colors, translations)
# ════════════════════════════════════════════════════════════════
echo ""
echo "━━━ [2/4] Configuring collections ━━━"

patch_collection() {
  local col="$1" data="$2" label="$3"
  curl -sS -X PATCH "$API/collections/$col" -H "$AUTH" -H "$CT" -d "$data" > /dev/null 2>&1 \
    && echo "  ✓ $col — $label" \
    || echo "  ⚠ $col — skipped"
}

patch_collection "contacts" '{
  "meta": {
    "icon": "contacts",
    "color": "#0F4C5C",
    "display_template": "{{first_name}} {{last_name}} — {{phone}}",
    "translations": [{"language":"he-IL","translation":"אנשי קשר","singular":"איש קשר","plural":"אנשי קשר"}]
  }
}' "אנשי קשר"

patch_collection "interactions" '{
  "meta": {
    "icon": "forum",
    "color": "#1A6B7A",
    "translations": [{"language":"he-IL","translation":"אינטראקציות","singular":"אינטראקציה","plural":"אינטראקציות"}]
  }
}' "אינטראקציות"

patch_collection "transactions" '{
  "meta": {
    "icon": "payments",
    "color": "#C8842B",
    "display_template": "{{amount}} ₪ — {{contact_id.first_name}} {{contact_id.last_name}}",
    "translations": [{"language":"he-IL","translation":"עסקאות","singular":"עסקה","plural":"עסקאות"}]
  }
}' "עסקאות"

patch_collection "receipts" '{
  "meta": {
    "icon": "receipt_long",
    "color": "#2D8659",
    "display_template": "קבלה #{{id}} — {{amount}} ₪",
    "translations": [{"language":"he-IL","translation":"קבלות","singular":"קבלה","plural":"קבלות"}]
  }
}' "קבלות"

patch_collection "tags" '{
  "meta": {
    "icon": "label",
    "color": "#7B61C4",
    "display_template": "{{name}}",
    "translations": [{"language":"he-IL","translation":"תגיות","singular":"תגית","plural":"תגיות"}]
  }
}' "תגיות"

patch_collection "categories" '{
  "meta": {
    "icon": "category",
    "color": "#D4922A",
    "display_template": "{{name}}",
    "translations": [{"language":"he-IL","translation":"קטגוריות","singular":"קטגוריה","plural":"קטגוריות"}]
  }
}' "קטגוריות"

patch_collection "contact_tags" '{
  "meta": {
    "icon": "sell",
    "color": "#8B5CF6",
    "hidden": true,
    "translations": [{"language":"he-IL","translation":"תגיות אנשי קשר","singular":"תגית איש קשר","plural":"תגיות אנשי קשר"}]
  }
}' "תגיות אנשי קשר (מוסתר)"

patch_collection "payment_events_raw" '{
  "meta": {
    "icon": "bolt",
    "color": "#E8A840",
    "translations": [{"language":"he-IL","translation":"אירועי תשלום (גולמי)","singular":"אירוע תשלום","plural":"אירועי תשלום"}]
  }
}' "אירועי תשלום"

patch_collection "bank_rows" '{
  "meta": {
    "icon": "account_balance",
    "color": "#0A3540",
    "translations": [{"language":"he-IL","translation":"שורות בנק","singular":"שורת בנק","plural":"שורות בנק"}]
  }
}' "שורות בנק"

# ════════════════════════════════════════════════════════════════
#  STEP 3: COLLECTION LAYOUTS (comfortable table presets)
# ════════════════════════════════════════════════════════════════
echo ""
echo "━━━ [3/4] Setting up table layouts ━━━"

create_preset() {
  local data="$1" label="$2"
  curl -sS -X POST "$API/presets" -H "$AUTH" -H "$CT" -d "$data" > /dev/null 2>&1 \
    && echo "  ✓ $label" \
    || echo "  ⚠ $label — skipped (may exist)"
}

create_preset '{
  "collection":"contacts","layout":"tabular","role":null,"user":null,
  "layout_query":{"tabular":{"fields":["first_name","last_name","phone","email","city","status","date_created"],"sort":["-date_created"],"limit":50}},
  "layout_options":{"tabular":{"widths":{"first_name":150,"last_name":150,"phone":140,"email":200,"city":120,"status":100,"date_created":160},"spacing":"comfortable"}}
}' "contacts — tabular"

create_preset '{
  "collection":"interactions","layout":"tabular","role":null,"user":null,
  "layout_query":{"tabular":{"fields":["type","contact_id","notes","date_created","user_created"],"sort":["-date_created"],"limit":50}},
  "layout_options":{"tabular":{"widths":{"type":120,"contact_id":200,"notes":300,"date_created":160,"user_created":140},"spacing":"comfortable"}}
}' "interactions — tabular"

create_preset '{
  "collection":"transactions","layout":"tabular","role":null,"user":null,
  "layout_query":{"tabular":{"fields":["contact_id","amount","type","status","description","date_created"],"sort":["-date_created"],"limit":50}},
  "layout_options":{"tabular":{"widths":{"contact_id":200,"amount":120,"type":120,"status":100,"description":250,"date_created":160},"spacing":"comfortable"}}
}' "transactions — tabular"

create_preset '{
  "collection":"receipts","layout":"tabular","role":null,"user":null,
  "layout_query":{"tabular":{"fields":["id","contact_id","amount","status","date_created"],"sort":["-date_created"],"limit":50}},
  "layout_options":{"tabular":{"widths":{"id":80,"contact_id":200,"amount":120,"status":100,"date_created":160},"spacing":"comfortable"}}
}' "receipts — tabular"

create_preset '{
  "collection":"bank_rows","layout":"tabular","role":null,"user":null,
  "layout_query":{"tabular":{"sort":["-date_created"],"limit":50}},
  "layout_options":{"tabular":{"spacing":"comfortable"}}
}' "bank_rows — tabular"

# ════════════════════════════════════════════════════════════════
#  STEP 4: DASHBOARDS
# ════════════════════════════════════════════════════════════════
echo ""
echo "━━━ [4/4] Creating dashboards ━━━"

extract_id() {
  python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])"
}

# ── Dashboard 1: סקירת CRM ──────────────────────────────────
echo "  Creating: סקירת CRM..."
DASH1=$(curl -sS -X POST "$API/dashboards" -H "$AUTH" -H "$CT" -d '{
  "name":"סקירת CRM","icon":"dashboard","color":"#0F4C5C",
  "note":"סקירה כללית של אנשי קשר, אינטראקציות ופעילות"
}' | extract_id)

if [[ -n "$DASH1" && "$DASH1" != "null" ]]; then
  echo "  ✓ Dashboard: $DASH1"

  # Metric panels — top row
  curl -sS -X POST "$API/panels" -H "$AUTH" -H "$CT" -d "{
    \"dashboard\":\"$DASH1\",\"name\":\"סה\\\"כ אנשי קשר\",\"icon\":\"contacts\",\"color\":\"#0F4C5C\",
    \"type\":\"metric\",\"position_x\":1,\"position_y\":1,\"width\":8,\"height\":6,
    \"options\":{\"collection\":\"contacts\",\"function\":\"count\",\"sortField\":\"id\",\"filter\":{}}
  }" > /dev/null 2>&1 && echo "    ✓ סה\"כ אנשי קשר"

  curl -sS -X POST "$API/panels" -H "$AUTH" -H "$CT" -d "{
    \"dashboard\":\"$DASH1\",\"name\":\"סה\\\"כ אינטראקציות\",\"icon\":\"forum\",\"color\":\"#1A6B7A\",
    \"type\":\"metric\",\"position_x\":9,\"position_y\":1,\"width\":8,\"height\":6,
    \"options\":{\"collection\":\"interactions\",\"function\":\"count\",\"sortField\":\"id\",\"filter\":{}}
  }" > /dev/null 2>&1 && echo "    ✓ סה\"כ אינטראקציות"

  curl -sS -X POST "$API/panels" -H "$AUTH" -H "$CT" -d "{
    \"dashboard\":\"$DASH1\",\"name\":\"סה\\\"כ עסקאות\",\"icon\":\"payments\",\"color\":\"#C8842B\",
    \"type\":\"metric\",\"position_x\":17,\"position_y\":1,\"width\":8,\"height\":6,
    \"options\":{\"collection\":\"transactions\",\"function\":\"count\",\"sortField\":\"id\",\"filter\":{}}
  }" > /dev/null 2>&1 && echo "    ✓ סה\"כ עסקאות"

  # List panels — middle row
  curl -sS -X POST "$API/panels" -H "$AUTH" -H "$CT" -d "{
    \"dashboard\":\"$DASH1\",\"name\":\"אנשי קשר אחרונים\",\"icon\":\"person_add\",\"color\":\"#0F4C5C\",
    \"type\":\"list\",\"position_x\":1,\"position_y\":7,\"width\":12,\"height\":12,
    \"options\":{\"collection\":\"contacts\",\"sort\":\"-date_created\",\"limit\":10,
    \"displayTemplate\":\"{{first_name}} {{last_name}} — {{phone}}\",\"filter\":{}}
  }" > /dev/null 2>&1 && echo "    ✓ אנשי קשר אחרונים"

  curl -sS -X POST "$API/panels" -H "$AUTH" -H "$CT" -d "{
    \"dashboard\":\"$DASH1\",\"name\":\"אינטראקציות אחרונות\",\"icon\":\"history\",\"color\":\"#1A6B7A\",
    \"type\":\"list\",\"position_x\":13,\"position_y\":7,\"width\":12,\"height\":12,
    \"options\":{\"collection\":\"interactions\",\"sort\":\"-date_created\",\"limit\":10,
    \"displayTemplate\":\"{{type}} — {{notes}}\",\"filter\":{}}
  }" > /dev/null 2>&1 && echo "    ✓ אינטראקציות אחרונות"
else
  echo "  ✗ Failed to create CRM dashboard"
fi

# ── Dashboard 2: סקירה פיננסית ───────────────────────────────
echo ""
echo "  Creating: סקירה פיננסית..."
DASH2=$(curl -sS -X POST "$API/dashboards" -H "$AUTH" -H "$CT" -d '{
  "name":"סקירה פיננסית","icon":"account_balance","color":"#C8842B",
  "note":"סקירה פיננסית: עסקאות, תשלומים, קבלות ושורות בנק"
}' | extract_id)

if [[ -n "$DASH2" && "$DASH2" != "null" ]]; then
  echo "  ✓ Dashboard: $DASH2"

  # Metric panels — top row
  curl -sS -X POST "$API/panels" -H "$AUTH" -H "$CT" -d "{
    \"dashboard\":\"$DASH2\",\"name\":\"סכום עסקאות כולל\",\"icon\":\"account_balance_wallet\",\"color\":\"#C8842B\",
    \"type\":\"metric\",\"position_x\":1,\"position_y\":1,\"width\":8,\"height\":6,
    \"options\":{\"collection\":\"transactions\",\"function\":\"sum\",\"field\":\"amount\",\"sortField\":\"amount\",\"filter\":{}}
  }" > /dev/null 2>&1 && echo "    ✓ סכום עסקאות כולל"

  curl -sS -X POST "$API/panels" -H "$AUTH" -H "$CT" -d "{
    \"dashboard\":\"$DASH2\",\"name\":\"מספר עסקאות\",\"icon\":\"receipt\",\"color\":\"#0F4C5C\",
    \"type\":\"metric\",\"position_x\":9,\"position_y\":1,\"width\":8,\"height\":6,
    \"options\":{\"collection\":\"transactions\",\"function\":\"count\",\"sortField\":\"id\",\"filter\":{}}
  }" > /dev/null 2>&1 && echo "    ✓ מספר עסקאות"

  curl -sS -X POST "$API/panels" -H "$AUTH" -H "$CT" -d "{
    \"dashboard\":\"$DASH2\",\"name\":\"סה\\\"כ קבלות\",\"icon\":\"receipt_long\",\"color\":\"#2D8659\",
    \"type\":\"metric\",\"position_x\":17,\"position_y\":1,\"width\":8,\"height\":6,
    \"options\":{\"collection\":\"receipts\",\"function\":\"count\",\"sortField\":\"id\",\"filter\":{}}
  }" > /dev/null 2>&1 && echo "    ✓ סה\"כ קבלות"

  # List panels — middle row
  curl -sS -X POST "$API/panels" -H "$AUTH" -H "$CT" -d "{
    \"dashboard\":\"$DASH2\",\"name\":\"עסקאות אחרונות\",\"icon\":\"payments\",\"color\":\"#C8842B\",
    \"type\":\"list\",\"position_x\":1,\"position_y\":7,\"width\":12,\"height\":12,
    \"options\":{\"collection\":\"transactions\",\"sort\":\"-date_created\",\"limit\":10,
    \"displayTemplate\":\"{{amount}} ₪ — {{contact_id.first_name}} {{contact_id.last_name}}\",\"filter\":{}}
  }" > /dev/null 2>&1 && echo "    ✓ עסקאות אחרונות"

  curl -sS -X POST "$API/panels" -H "$AUTH" -H "$CT" -d "{
    \"dashboard\":\"$DASH2\",\"name\":\"קבלות אחרונות\",\"icon\":\"description\",\"color\":\"#2D8659\",
    \"type\":\"list\",\"position_x\":13,\"position_y\":7,\"width\":12,\"height\":12,
    \"options\":{\"collection\":\"receipts\",\"sort\":\"-date_created\",\"limit\":10,
    \"displayTemplate\":\"קבלה #{{id}} — {{amount}} ₪\",\"filter\":{}}
  }" > /dev/null 2>&1 && echo "    ✓ קבלות אחרונות"

  # Bottom row
  curl -sS -X POST "$API/panels" -H "$AUTH" -H "$CT" -d "{
    \"dashboard\":\"$DASH2\",\"name\":\"שורות בנק אחרונות\",\"icon\":\"account_balance\",\"color\":\"#0A3540\",
    \"type\":\"list\",\"position_x\":1,\"position_y\":19,\"width\":12,\"height\":10,
    \"options\":{\"collection\":\"bank_rows\",\"sort\":\"-date_created\",\"limit\":10,\"filter\":{}}
  }" > /dev/null 2>&1 && echo "    ✓ שורות בנק אחרונות"

  curl -sS -X POST "$API/panels" -H "$AUTH" -H "$CT" -d "{
    \"dashboard\":\"$DASH2\",\"name\":\"אירועי תשלום אחרונים\",\"icon\":\"bolt\",\"color\":\"#E8A840\",
    \"type\":\"list\",\"position_x\":13,\"position_y\":19,\"width\":12,\"height\":10,
    \"options\":{\"collection\":\"payment_events_raw\",\"sort\":\"-date_created\",\"limit\":10,\"filter\":{}}
  }" > /dev/null 2>&1 && echo "    ✓ אירועי תשלום אחרונים"
else
  echo "  ✗ Failed to create Financial dashboard"
fi

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║  ✓  הכל הושלם בהצלחה!                       ║"
echo "  ║                                              ║"
echo "  ║  פתח: https://crm.merkazneshama.co.il/admin  ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""
