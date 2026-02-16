#!/usr/bin/env bash
# ============================================================
#  apply-branding.sh — Apply מרכז נשמה / חושן יהודה branding
#  to the Directus CRM instance.
#
#  Usage:
#    export DIRECTUS_URL=https://crm.merkazneshama.co.il
#    export DIRECTUS_TOKEN=<admin-static-token>
#    bash scripts/apply-branding.sh
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
echo "  מרכז נשמה — Directus CRM Branding Setup"
echo "══════════════════════════════════════════════════"
echo ""
echo "Target: $API"
echo ""

# ── Helper function ──────────────────────────────────────────
api() {
  local method="$1" endpoint="$2"
  shift 2
  curl -sS -X "$method" "$API/$endpoint" \
    -H "$AUTH" -H "$CT" "$@"
}

# ── Step 1: Upload Logo (if exists) ─────────────────────────
upload_logo() {
  local logo_path="$1"
  local title="$2"

  if [[ ! -f "$logo_path" ]]; then
    echo "  ⚠ Logo file not found: $logo_path"
    return 1
  fi

  echo "  Uploading logo: $title ..."
  local result
  result=$(curl -sS -X POST "$API/files" \
    -H "$AUTH" \
    -F "title=$title" \
    -F "file=@$logo_path")

  local file_id
  file_id=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null || echo "")

  if [[ -n "$file_id" ]]; then
    echo "  ✓ Uploaded: $file_id"
    echo "$file_id"
  else
    echo "  ✗ Upload failed: $result"
    return 1
  fi
}

# ── Step 2: Read Custom CSS ──────────────────────────────────
echo "[1/4] Loading custom CSS..."
CSS_FILE="$PROJECT_DIR/config/custom-css.css"
if [[ ! -f "$CSS_FILE" ]]; then
  echo "  ✗ CSS file not found: $CSS_FILE"
  exit 1
fi
CUSTOM_CSS=$(cat "$CSS_FILE")
echo "  ✓ CSS loaded ($(wc -c < "$CSS_FILE") bytes)"

# ── Step 3: Upload Logos ─────────────────────────────────────
echo ""
echo "[2/4] Uploading logos..."

LOGO_ID=""
# Look for logo files in assets directory
for ext in png jpg jpeg svg webp; do
  for logo_file in "$PROJECT_DIR/assets/logo."$ext "$PROJECT_DIR/assets/merkaz-neshama."$ext; do
    if [[ -f "$logo_file" ]]; then
      LOGO_ID=$(upload_logo "$logo_file" "מרכז נשמה - לוגו")
      break 2
    fi
  done
done

if [[ -z "$LOGO_ID" ]]; then
  echo "  ⓘ No logo file found in assets/. Place your logo as assets/logo.png"
  echo "    Skipping logo upload — you can set it manually in Settings."
fi

# ── Step 4: Apply Project Settings ───────────────────────────
echo ""
echo "[3/4] Applying project settings..."

# Build settings JSON
SETTINGS_JSON=$(python3 -c "
import json, sys

settings = {
    'project_name': 'מרכז נשמה — ניהול לקוחות',
    'project_descriptor': 'חושן יהודה | CRM',
    'project_color': '#0F4C5C',
    'default_language': 'he-IL',
    'custom_css': sys.stdin.read()
}

logo_id = '$LOGO_ID'
if logo_id:
    settings['project_logo'] = logo_id

print(json.dumps(settings, ensure_ascii=False))
" <<< "$CUSTOM_CSS")

RESULT=$(api PATCH "settings" -d "$SETTINGS_JSON")

# Check if successful
if echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'data' in d" 2>/dev/null; then
  echo "  ✓ Project settings applied successfully"
  echo "    • Name: מרכז נשמה — ניהול לקוחות"
  echo "    • Color: #0F4C5C (Deep Teal)"
  echo "    • Language: he-IL"
  echo "    • Custom CSS: injected"
  if [[ -n "$LOGO_ID" ]]; then
    echo "    • Logo: uploaded"
  fi
else
  echo "  ✗ Failed to apply settings:"
  echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
fi

# ── Step 5: Configure Collection Display Templates ───────────
echo ""
echo "[4/4] Configuring collection display settings..."

# Update contacts collection — display template
api PATCH "collections/contacts" -d '{
  "meta": {
    "icon": "contacts",
    "color": "#0F4C5C",
    "display_template": "{{first_name}} {{last_name}} — {{phone}}",
    "sort_field": "last_name",
    "archive_field": "status",
    "archive_value": "archived",
    "unarchive_value": "active",
    "translations": [
      {"language": "he-IL", "translation": "אנשי קשר", "singular": "איש קשר", "plural": "אנשי קשר"}
    ]
  }
}' > /dev/null 2>&1 && echo "  ✓ contacts — אנשי קשר" || echo "  ⚠ contacts — skipped"

# Update interactions
api PATCH "collections/interactions" -d '{
  "meta": {
    "icon": "forum",
    "color": "#1A6B7A",
    "display_template": "{{type}} — {{contact_id.first_name}} {{contact_id.last_name}}",
    "sort_field": "-date_created",
    "translations": [
      {"language": "he-IL", "translation": "אינטראקציות", "singular": "אינטראקציה", "plural": "אינטראקציות"}
    ]
  }
}' > /dev/null 2>&1 && echo "  ✓ interactions — אינטראקציות" || echo "  ⚠ interactions — skipped"

# Update transactions
api PATCH "collections/transactions" -d '{
  "meta": {
    "icon": "payments",
    "color": "#C8842B",
    "display_template": "{{amount}} ₪ — {{contact_id.first_name}} {{contact_id.last_name}}",
    "sort_field": "-date_created",
    "translations": [
      {"language": "he-IL", "translation": "עסקאות", "singular": "עסקה", "plural": "עסקאות"}
    ]
  }
}' > /dev/null 2>&1 && echo "  ✓ transactions — עסקאות" || echo "  ⚠ transactions — skipped"

# Update receipts
api PATCH "collections/receipts" -d '{
  "meta": {
    "icon": "receipt_long",
    "color": "#2D8659",
    "display_template": "קבלה #{{id}} — {{amount}} ₪",
    "sort_field": "-date_created",
    "translations": [
      {"language": "he-IL", "translation": "קבלות", "singular": "קבלה", "plural": "קבלות"}
    ]
  }
}' > /dev/null 2>&1 && echo "  ✓ receipts — קבלות" || echo "  ⚠ receipts — skipped"

# Update tags
api PATCH "collections/tags" -d '{
  "meta": {
    "icon": "label",
    "color": "#7B61C4",
    "display_template": "{{name}}",
    "translations": [
      {"language": "he-IL", "translation": "תגיות", "singular": "תגית", "plural": "תגיות"}
    ]
  }
}' > /dev/null 2>&1 && echo "  ✓ tags — תגיות" || echo "  ⚠ tags — skipped"

# Update categories
api PATCH "collections/categories" -d '{
  "meta": {
    "icon": "category",
    "color": "#D4922A",
    "display_template": "{{name}}",
    "translations": [
      {"language": "he-IL", "translation": "קטגוריות", "singular": "קטגוריה", "plural": "קטגוריות"}
    ]
  }
}' > /dev/null 2>&1 && echo "  ✓ categories — קטגוריות" || echo "  ⚠ categories — skipped"

# Update payment_events_raw
api PATCH "collections/payment_events_raw" -d '{
  "meta": {
    "icon": "bolt",
    "color": "#E8A840",
    "sort_field": "-date_created",
    "translations": [
      {"language": "he-IL", "translation": "אירועי תשלום (גולמי)", "singular": "אירוע תשלום", "plural": "אירועי תשלום"}
    ]
  }
}' > /dev/null 2>&1 && echo "  ✓ payment_events_raw — אירועי תשלום" || echo "  ⚠ payment_events_raw — skipped"

# Update bank_rows
api PATCH "collections/bank_rows" -d '{
  "meta": {
    "icon": "account_balance",
    "color": "#0A3540",
    "sort_field": "-date_created",
    "translations": [
      {"language": "he-IL", "translation": "שורות בנק", "singular": "שורת בנק", "plural": "שורות בנק"}
    ]
  }
}' > /dev/null 2>&1 && echo "  ✓ bank_rows — שורות בנק" || echo "  ⚠ bank_rows — skipped"

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✓ Branding applied successfully!"
echo ""
echo "  Open: $API/admin/settings/project"
echo "  to verify the changes."
echo "══════════════════════════════════════════════════"
