#!/usr/bin/env bash
# ============================================================
#  configure-layouts.sh — Configure collection layouts and
#  presets for comfortable data viewing.
#
#  Sets up default table views with proper column widths,
#  sorting, and field visibility for each collection.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [[ -f "$PROJECT_DIR/.env" ]]; then
  set -a; source "$PROJECT_DIR/.env"; set +a
fi

: "${DIRECTUS_URL:?Set DIRECTUS_URL}"
: "${DIRECTUS_TOKEN:?Set DIRECTUS_TOKEN}"

API="$DIRECTUS_URL"
AUTH="Authorization: Bearer $DIRECTUS_TOKEN"
CT="Content-Type: application/json"

echo "══════════════════════════════════════════════════"
echo "  מרכז נשמה — Collection Layouts Configuration"
echo "══════════════════════════════════════════════════"
echo ""

api_post() {
  curl -sS -X POST "$API/$1" -H "$AUTH" -H "$CT" -d "$2"
}

# ── Contacts — Default Table Layout ──────────────────────────
echo "[1/5] Setting up contacts layout..."
api_post "presets" '{
  "collection": "contacts",
  "bookmark": null,
  "role": null,
  "user": null,
  "layout": "tabular",
  "layout_query": {
    "tabular": {
      "fields": ["first_name", "last_name", "phone", "email", "city", "status", "date_created"],
      "sort": ["-date_created"],
      "limit": 50
    }
  },
  "layout_options": {
    "tabular": {
      "widths": {
        "first_name": 150,
        "last_name": 150,
        "phone": 140,
        "email": 200,
        "city": 120,
        "status": 100,
        "date_created": 160
      },
      "spacing": "comfortable"
    }
  },
  "search": null,
  "filter": null
}' > /dev/null 2>&1 && echo "  ✓ contacts — tabular layout" || echo "  ⚠ contacts — skipped (may already exist)"

# ── Interactions — Default Table Layout ──────────────────────
echo "[2/5] Setting up interactions layout..."
api_post "presets" '{
  "collection": "interactions",
  "bookmark": null,
  "role": null,
  "user": null,
  "layout": "tabular",
  "layout_query": {
    "tabular": {
      "fields": ["type", "contact_id", "notes", "date_created", "user_created"],
      "sort": ["-date_created"],
      "limit": 50
    }
  },
  "layout_options": {
    "tabular": {
      "widths": {
        "type": 120,
        "contact_id": 200,
        "notes": 300,
        "date_created": 160,
        "user_created": 140
      },
      "spacing": "comfortable"
    }
  },
  "search": null,
  "filter": null
}' > /dev/null 2>&1 && echo "  ✓ interactions — tabular layout" || echo "  ⚠ interactions — skipped"

# ── Transactions — Default Table Layout ──────────────────────
echo "[3/5] Setting up transactions layout..."
api_post "presets" '{
  "collection": "transactions",
  "bookmark": null,
  "role": null,
  "user": null,
  "layout": "tabular",
  "layout_query": {
    "tabular": {
      "fields": ["contact_id", "amount", "type", "status", "description", "date_created"],
      "sort": ["-date_created"],
      "limit": 50
    }
  },
  "layout_options": {
    "tabular": {
      "widths": {
        "contact_id": 200,
        "amount": 120,
        "type": 120,
        "status": 100,
        "description": 250,
        "date_created": 160
      },
      "spacing": "comfortable"
    }
  },
  "search": null,
  "filter": null
}' > /dev/null 2>&1 && echo "  ✓ transactions — tabular layout" || echo "  ⚠ transactions — skipped"

# ── Receipts — Default Table Layout ──────────────────────────
echo "[4/5] Setting up receipts layout..."
api_post "presets" '{
  "collection": "receipts",
  "bookmark": null,
  "role": null,
  "user": null,
  "layout": "tabular",
  "layout_query": {
    "tabular": {
      "fields": ["id", "contact_id", "amount", "status", "date_created"],
      "sort": ["-date_created"],
      "limit": 50
    }
  },
  "layout_options": {
    "tabular": {
      "widths": {
        "id": 80,
        "contact_id": 200,
        "amount": 120,
        "status": 100,
        "date_created": 160
      },
      "spacing": "comfortable"
    }
  },
  "search": null,
  "filter": null
}' > /dev/null 2>&1 && echo "  ✓ receipts — tabular layout" || echo "  ⚠ receipts — skipped"

# ── Bank Rows — Default Table Layout ─────────────────────────
echo "[5/5] Setting up bank_rows layout..."
api_post "presets" '{
  "collection": "bank_rows",
  "bookmark": null,
  "role": null,
  "user": null,
  "layout": "tabular",
  "layout_query": {
    "tabular": {
      "sort": ["-date_created"],
      "limit": 50
    }
  },
  "layout_options": {
    "tabular": {
      "spacing": "comfortable"
    }
  },
  "search": null,
  "filter": null
}' > /dev/null 2>&1 && echo "  ✓ bank_rows — tabular layout" || echo "  ⚠ bank_rows — skipped"

echo ""
echo "══════════════════════════════════════════════════"
echo "  ✓ Collection layouts configured!"
echo "  Default views set for all collections."
echo "══════════════════════════════════════════════════"
