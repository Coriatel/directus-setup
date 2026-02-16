#!/usr/bin/env python3
"""
Apply all HYCRM Directus customizations:
- Brand settings (colors, logo, CSS)
- Collection metadata (icons, colors, sort, notes, Hebrew translations)
- Field Hebrew translations
- System UI translations
- Module bar Hebrew names
- User language settings
- Dashboards & panels

Usage:
  DIRECTUS_URL=http://127.0.0.1:18055 DIRECTUS_TOKEN=<token> python3 apply-all.py
"""
import os, sys, json, requests

API = os.environ.get("DIRECTUS_URL", "http://127.0.0.1:18055")
TOKEN = os.environ.get("DIRECTUS_TOKEN", "hycrm-admin-api-token-2026")
H = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"}
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

def api(method, path, data=None):
    r = getattr(requests, method)(f"{API}{path}", headers=H, json=data)
    if r.status_code not in (200, 204):
        print(f"  WARN {method.upper()} {path}: {r.status_code}")
    return r

# ── 1. Brand Settings ──────────────────────────────────────────────
print("1. Applying brand settings...")
css_path = os.path.join(SCRIPT_DIR, "..", "config", "custom-css.css")
with open(css_path) as f:
    custom_css = f.read()

api("patch", "/settings", {
    "project_name": "חושן יהודה CRM",
    "project_color": "#04557a",
    "project_url": "https://crm.merkazneshama.co.il",
    "custom_css": custom_css,
})

# Upload logo if not already present
logo_path = os.path.join(SCRIPT_DIR, "..", "assets", "logo-white.png")
if os.path.exists(logo_path):
    r = requests.post(f"{API}/files",
        headers={"Authorization": f"Bearer {TOKEN}"},
        files={"file": open(logo_path, "rb")},
        data={"title": "חושן יהודה לוגו לבן"})
    if r.status_code == 200:
        logo_id = r.json()["data"]["id"]
        api("patch", "/settings", {"project_logo": logo_id})
        print(f"  Logo uploaded: {logo_id}")
print("  Done")

# ── 2. Module Bar ──────────────────────────────────────────────────
print("2. Setting Hebrew module bar...")
api("patch", "/settings", {"module_bar": [
    {"type": "module", "id": "content", "enabled": True, "name": "תוכן"},
    {"type": "module", "id": "visual", "enabled": True, "name": "תצוגה חזותית"},
    {"type": "module", "id": "users", "enabled": True, "name": "משתמשים"},
    {"type": "module", "id": "files", "enabled": True, "name": "קבצים"},
    {"type": "module", "id": "insights", "enabled": True, "name": "תובנות"},
    {"type": "link", "id": "docs", "name": "תיעוד", "url": "https://docs.directus.io", "icon": "help", "enabled": True},
    {"type": "module", "id": "settings", "enabled": True, "name": "הגדרות"},
    {"type": "module", "id": "protoqol/schema", "enabled": True, "name": "סכמה"},
]})
print("  Done")

# ── 3. Collection Metadata ─────────────────────────────────────────
print("3. Applying collection metadata...")
COLLECTIONS = {
    "contacts":       {"icon": "people", "color": "#04557a", "sort": 1, "note": "אנשי קשר / תורמים / תלמידים", "sing": "איש קשר", "plur": "אנשי קשר"},
    "transactions":   {"icon": "payments", "color": "#eba064", "sort": 2, "note": "שורות הכנסות והוצאות", "sing": "עסקה", "plur": "עסקאות"},
    "receipts":       {"icon": "receipt_long", "color": "#1a74a4", "sort": 3, "note": "מטא-נתוני קבלות וקבצים", "sing": "קבלה", "plur": "קבלות"},
    "interactions":   {"icon": "forum", "color": "#04557a", "sort": 4, "note": "שיחות, הערות ומעקב", "sing": "אינטראקציה", "plur": "אינטראקציות"},
    "categories":     {"icon": "category", "color": "#1a74a4", "sort": 5, "note": "קטלוג קטגוריות מנוהל", "sing": "קטגוריה", "plur": "קטגוריות"},
    "tags":           {"icon": "sell", "color": "#eba064", "sort": 6, "note": "תגיות לאנשי קשר", "sing": "תגית", "plur": "תגיות"},
    "contact_tags":   {"icon": "link", "color": "#8B9DAF", "sort": 7, "note": "טבלת קישור אנשי קשר-תגיות", "sing": "קשר תגית", "plur": "קשרי תגיות"},
    "bank_rows":      {"icon": "account_balance", "color": "#1a74a4", "sort": 8, "note": "שורות דפי חשבון בנק מיובאות", "sing": "שורת בנק", "plur": "שורות בנק"},
    "payment_events_raw": {"icon": "radar", "color": "#ca553b", "sort": 9, "note": "נתוני webhook גולמיים מתקבול", "sing": "אירוע תשלום גולמי", "plur": "אירועי תשלום גולמיים"},
    "eshet_chayil_leads": {"icon": "volunteer_activism", "color": "#ca553b", "sort": 10, "note": "לידים מטופס אשת חיל", "sing": "ליד אשת חיל", "plur": "לידים אשת חיל"},
    "workshop_registrations": {"icon": "school", "color": "#04557a", "sort": 11, "note": "הרשמות לסדנת אשת חיל", "sing": "הרשמה לסדנה", "plur": "הרשמות לסדנאות"},
    "bank_recon":     {"icon": "compare_arrows", "color": "#1a74a4", "sort": 12, "note": "התאמות בנק", "sing": "התאמת בנק", "plur": "התאמות בנק"},
    "bit_recon":      {"icon": "credit_card", "color": "#eba064", "sort": 13, "note": "התאמות עסקאות ביט", "sing": "התאמת ביט", "plur": "התאמות ביט"},
    "paybox_recon":   {"icon": "point_of_sale", "color": "#eba064", "sort": 14, "note": "התאמות עסקאות פייבוקס", "sing": "התאמת פייבוקס", "plur": "התאמות פייבוקס"},
    "import_failures": {"icon": "error", "color": "#ca553b", "sort": 15, "note": "שגיאות בייבוא נתונים", "sing": "שגיאת ייבוא", "plur": "שגיאות ייבוא"},
    "legacy_monthly_income_breakdown": {"icon": "bar_chart", "color": "#04557a", "sort": 16, "note": "פירוט הכנסות חודשי - ארכיון", "sing": "פירוט הכנסות חודשי", "plur": "פירוטי הכנסות חודשיים"},
    "legacy_monthly_cashflow": {"icon": "trending_up", "color": "#1a74a4", "sort": 17, "note": "תזרים מזומנים חודשי - ארכיון", "sing": "תזרים מזומנים חודשי", "plur": "תזרימי מזומנים חודשיים"},
    "receipt_queue_legacy": {"icon": "queue", "color": "#04557a", "sort": 18, "note": "תור קבלות להנפקה - ארכיון", "sing": "תור קבלות", "plur": "תור קבלות"},
}

for col, meta in COLLECTIONS.items():
    api("patch", f"/collections/{col}", {"meta": {
        "icon": meta["icon"], "color": meta["color"], "sort": meta["sort"], "note": meta["note"],
        "translations": [{"language": "he-IL", "singular": meta["sing"], "plural": meta["plur"], "translation": meta["plur"]}]
    }})
print(f"  {len(COLLECTIONS)} collections configured")

# ── 4. Field Translations ──────────────────────────────────────────
print("4. Applying field translations...")
FIELD_TRANS = {
    "contacts": {"id": "מזהה", "full_name": "שם מלא", "phone_raw": "טלפון (גולמי)", "phone_e164": "טלפון (E.164)", "email": "אימייל", "status": "סטטוס", "id_number": "תעודת זהות", "notes": "הערות", "created_at": "נוצר ב", "updated_at": "עודכן ב"},
    "transactions": {"id": "מזהה", "contact_id": "איש קשר", "direction": "כיוון", "amount": "סכום", "currency": "מטבע", "date": "תאריך", "source": "מקור", "external_ref": "מזהה חיצוני", "category_id": "קטגוריה", "note": "הערה", "status": "סטטוס", "created_at": "נוצר ב", "updated_at": "עודכן ב", "counterparty_name": "צד נגדי", "purpose": "מטרה", "payment_method": "אמצעי תשלום", "document_type": "סוג מסמך", "document_number": "מספר מסמך"},
    "receipts": {"id": "מזהה", "transaction_id": "עסקה", "receipt_number": "מספר קבלה", "issued_at": "תאריך הנפקה", "pdf_file": "קובץ PDF", "section_46": "סעיף 46", "note": "הערה", "created_at": "נוצר ב", "updated_at": "עודכן ב"},
    "interactions": {"id": "מזהה", "contact_id": "איש קשר", "type": "סוג", "status": "סטטוס", "category_id": "קטגוריה", "summary": "תקציר", "next_action_at": "פעולה הבאה", "created_at": "נוצר ב", "created_by": "נוצר על ידי", "result": "תוצאה", "result_note": "הערת תוצאה"},
    "categories": {"id": "מזהה", "name": "שם", "direction": "כיוון", "active": "פעיל", "created_at": "נוצר ב", "updated_at": "עודכן ב"},
    "tags": {"id": "מזהה", "name": "שם", "created_at": "נוצר ב", "updated_at": "עודכן ב"},
    "contact_tags": {"id": "מזהה", "contact_id": "איש קשר", "tag_id": "תגית", "created_at": "נוצר ב"},
    "bank_rows": {"id": "מזהה", "import_batch_id": "מזהה אצווה", "date": "תאריך", "amount": "סכום", "counterparty": "צד נגדי", "memo": "תיאור", "category_id": "קטגוריה", "note": "הערה", "matched_transaction_id": "עסקה מותאמת", "pdf_file": "קובץ PDF", "created_at": "נוצר ב", "updated_at": "עודכן ב", "direction": "כיוון", "balance": "יתרה", "reference": "אסמכתא"},
    "payment_events_raw": {"id": "מזהה", "provider": "ספק", "received_at": "התקבל ב", "external_ref": "מזהה חיצוני", "payload_json": "נתוני JSON", "processed_status": "סטטוס עיבוד", "linked_transaction_id": "עסקה מקושרת", "created_at": "נוצר ב"},
    "eshet_chayil_leads": {"id": "מזהה", "first_name": "שם פרטי", "last_name": "שם משפחה", "phone": "טלפון", "email": "דואל", "created_at": "נוצר ב", "source": "מקור", "city": "עיר", "marital_status": "מצב משפחתי", "background": "רקע", "message": "הודעה", "consent": "הסכמה", "user_agent": "סוכן משתמש", "ip": "כתובת IP"},
    "workshop_registrations": {"id": "מזהה", "first_name": "שם פרטי", "last_name": "שם משפחה", "phone": "טלפון", "email": "דואל", "city": "עיר", "marital_status": "מצב משפחתי", "background": "רקע בלימוד", "notes": "הערות", "status": "סטטוס"},
    "bank_recon": {"id": "מזהה", "bank_row_ref": "אסמכתת בנק", "bank_row_id": "שורת בנק", "date": "תאריך", "effective_amount": "סכום בפועל", "classification": "סיווג", "recon_status": "סטטוס התאמה", "details": "פרטים", "import_batch_id": "מזהה אצווה", "created_at": "נוצר ב"},
    "bit_recon": {"id": "מזהה", "source_file": "קובץ מקור", "bit_date": "תאריך ביט", "bit_description": "תיאור ביט", "direction": "כיוון", "gross_amount": "סכום ברוטו", "fee": "עמלה", "net_amount": "סכום נטו", "match_amount": "סכום התאמה", "bank_row_ref": "אסמכתת בנק", "bank_row_id": "שורת בנק", "bank_date": "תאריך בנק", "bank_amount": "סכום בנק", "amount_diff": "הפרש סכום", "days_diff": "הפרש ימים", "confidence": "רמת ביטחון", "bank_description": "תיאור בנק", "recon_status": "סטטוס התאמה", "import_batch_id": "מזהה אצווה", "created_at": "נוצר ב"},
    "paybox_recon": {"id": "מזהה", "source_file": "קובץ מקור", "withdrawal_date": "תאריך משיכה", "withdrawal_amount": "סכום משיכה", "donor_name": "שם תורם", "bank_row_ref": "אסמכתת בנק", "bank_row_id": "שורת בנק", "bank_date": "תאריך בנק", "bank_amount": "סכום בנק", "amount_diff": "הפרש סכום", "bank_description": "תיאור בנק", "days_diff": "הפרש ימים", "confidence": "רמת ביטחון", "recon_status": "סטטוס התאמה", "import_batch_id": "מזהה אצווה", "created_at": "נוצר ב"},
    "import_failures": {"id": "מזהה", "import_batch_id": "מזהה אצווה", "source_tab": "לשונית מקור", "source_row": "שורת מקור", "error_type": "סוג שגיאה", "error_message": "הודעת שגיאה", "raw_row_json": "שורה גולמית", "created_at": "נוצר ב"},
    "legacy_monthly_income_breakdown": {"id": "מזהה", "cashflow_id": "מזהה תזרים", "donor_label": "שם תורם", "amount": "סכום", "source_col": "עמודת מקור", "import_batch_id": "מזהה אצווה", "created_at": "נוצר ב"},
    "legacy_monthly_cashflow": {"id": "מזהה", "year": "שנה", "month": "חודש", "rent": "שכירות", "condo_fee": "ועד בית", "electricity": "חשמל", "water": "מים", "extra_expense_1": "הוצאה נוספת 1", "extra_expense_1_label": "תיאור הוצאה 1", "extra_expense_2": "הוצאה נוספת 2", "extra_expense_2_label": "תיאור הוצאה 2", "total_expenses": 'סה"כ הוצאות', "expenses_in_account": "הוצאות בחשבון", "balance_eom": "יתרה סוף חודש", "total_income": 'סה"כ הכנסות', "notes": "הערות", "receipt_reminder": "תזכורת קבלה", "source_section_row": "שורת מקור", "import_batch_id": "מזהה אצווה", "created_at": "נוצר ב", "updated_at": "עודכן ב"},
    "receipt_queue_legacy": {"id": "מזהה", "source_tab": "לשונית מקור", "source_row": "שורת מקור", "date": "תאריך", "amount": "סכום", "receipt_number": "מספר קבלה", "direction": "כיוון", "category_label": "קטגוריה", "counterparty": "צד נגדי", "linked_transaction_id": "עסקה מקושרת", "import_batch_id": "מזהה אצווה", "status": "סטטוס", "error_note": "הערת שגיאה", "created_at": "נוצר ב"},
}

count = 0
for col, fields in FIELD_TRANS.items():
    for field, he in fields.items():
        r = requests.get(f"{API}/fields/{col}/{field}", headers=H)
        if r.status_code != 200:
            continue
        meta = r.json()["data"].get("meta") or {}
        trans = [t for t in (meta.get("translations") or []) if t.get("language") != "he-IL"]
        trans.append({"language": "he-IL", "translation": he})
        api("patch", f"/fields/{col}/{field}", {"meta": {"translations": trans}})
        count += 1
print(f"  {count} fields translated")

# ── 5. System UI Translations ──────────────────────────────────────
print("5. Adding system UI translations...")
SYS_TRANS = [
    ("content", "תוכן"), ("users", "משתמשים"), ("files", "קבצים"),
    ("insights", "תובנות"), ("settings", "הגדרות"),
    ("save", "שמור"), ("create", "צור"), ("delete", "מחק"), ("edit", "ערוך"),
    ("cancel", "ביטול"), ("search", "חיפוש"), ("filter", "סינון"), ("sort", "מיון"),
    ("select_all", "בחר הכל"), ("no_items", "אין פריטים"), ("loading", "טוען..."),
    ("confirm", "אישור"), ("actions", "פעולות"), ("export", "ייצוא"), ("import", "ייבוא"),
    ("refresh", "רענון"), ("item_count", "מספר פריטים"),
    ("date_created", "תאריך יצירה"), ("date_updated", "תאריך עדכון"),
    ("created_by", "נוצר על ידי"), ("updated_by", "עודכן על ידי"),
    ("status", "סטטוס"), ("active", "פעיל"), ("inactive", "לא פעיל"),
    ("archived", "בארכיון"), ("draft", "טיוטה"), ("published", "פורסם"),
    ("name", "שם"), ("description", "תיאור"), ("note", "הערה"), ("type", "סוג"), ("value", "ערך"),
    ("fields.directus_users.email", "דואל"), ("fields.directus_users.first_name", "שם פרטי"),
    ("fields.directus_users.last_name", "שם משפחה"), ("fields.directus_users.role", "תפקיד"),
    ("fields.directus_users.status", "סטטוס"), ("fields.directus_users.language", "שפה"),
    ("fields.directus_users.location", "מיקום"), ("fields.directus_users.title", "כותרת"),
    ("fields.directus_users.description", "תיאור"),
    ("fields.directus_files.title", "כותרת"), ("fields.directus_files.type", "סוג"),
    ("fields.directus_files.folder", "תיקייה"), ("fields.directus_files.uploaded_on", "הועלה ב"),
    ("fields.directus_files.modified_on", "עודכן ב"), ("fields.directus_files.filesize", "גודל קובץ"),
    ("fields.directus_activity.action", "פעולה"), ("fields.directus_activity.timestamp", "חותמת זמן"),
    ("fields.directus_activity.user", "משתמש"), ("fields.directus_activity.collection", "אוסף"),
    ("fields.directus_roles.name", "שם"), ("fields.directus_roles.description", "תיאור"),
    ("fields.directus_roles.icon", "אייקון"), ("fields.directus_roles.users", "משתמשים"),
    ("fields.directus_permissions.collection", "אוסף"), ("fields.directus_permissions.action", "פעולה"),
    ("fields.directus_flows.name", "שם"), ("fields.directus_flows.status", "סטטוס"),
    ("fields.directus_flows.description", "תיאור"), ("fields.directus_flows.trigger", "טריגר"),
    ("fields.directus_operations.name", "שם"), ("fields.directus_operations.type", "סוג"),
    ("fields.directus_dashboards.name", "שם"), ("fields.directus_dashboards.icon", "אייקון"),
    ("fields.directus_dashboards.color", "צבע"), ("fields.directus_dashboards.note", "הערה"),
    ("fields.directus_panels.name", "שם"), ("fields.directus_panels.icon", "אייקון"),
    ("fields.directus_panels.color", "צבע"), ("fields.directus_panels.type", "סוג"),
    ("fields.directus_folders.name", "שם"),
    ("fields.directus_shares.name", "שם"), ("fields.directus_shares.collection", "אוסף"),
    ("fields.directus_presets.bookmark", "סימנייה"), ("fields.directus_presets.collection", "אוסף"),
    ("fields.directus_presets.layout", "פריסה"),
    ("fields.directus_collections.collection", "אוסף"), ("fields.directus_collections.note", "הערה"),
]

added = 0
for key, value in SYS_TRANS:
    r = requests.post(f"{API}/translations", headers=H, json={"language": "he-IL", "key": key, "value": value})
    if r.status_code in (200, 204):
        added += 1
print(f"  {added} new translations added ({len(SYS_TRANS) - added} already existed)")

# ── 6. User Language ───────────────────────────────────────────────
print("6. Setting all users to he-IL...")
r = requests.get(f"{API}/users?fields=id,email,language", headers=H)
for u in r.json()["data"]:
    if u.get("language") != "he-IL":
        api("patch", f"/users/{u['id']}", {"language": "he-IL"})
        print(f"  {u['email']} -> he-IL")
print("  Done")

# ── 7. Dashboards ──────────────────────────────────────────────────
print("7. Creating dashboards...")

# Delete existing dashboards first
r = requests.get(f"{API}/dashboards", headers=H)
for d in r.json().get("data", []):
    r2 = requests.get(f"{API}/panels?filter[dashboard][_eq]={d['id']}", headers=H)
    for p in r2.json().get("data", []):
        requests.delete(f"{API}/panels/{p['id']}", headers=H)
    requests.delete(f"{API}/dashboards/{d['id']}", headers=H)

# CRM & Sales
crm = api("post", "/dashboards", {"name": "CRM ומכירות", "icon": "storefront", "color": "#04557a", "note": "ניהול אנשי קשר, אינטראקציות, מכירות ולידים"})
crm_id = crm.json()["data"]["id"]
for panel in [
    {"name": 'סה"כ אנשי קשר', "icon": "people", "color": "#04557a", "type": "metric", "position_x": 1, "position_y": 1, "width": 6, "height": 6, "options": {"collection": "contacts", "function": "count"}},
    {"name": "אנשי קשר פעילים", "icon": "person_check", "color": "#1a74a4", "type": "metric", "position_x": 7, "position_y": 1, "width": 6, "height": 6, "options": {"collection": "contacts", "function": "count", "filter": {"status": {"_eq": "active"}}}},
    {"name": "אינטראקציות", "icon": "forum", "color": "#eba064", "type": "metric", "position_x": 13, "position_y": 1, "width": 6, "height": 6, "options": {"collection": "interactions", "function": "count"}},
    {"name": "לידים אשת חיל", "icon": "volunteer_activism", "color": "#ca553b", "type": "metric", "position_x": 19, "position_y": 1, "width": 6, "height": 6, "options": {"collection": "eshet_chayil_leads", "function": "count"}},
    {"name": "אנשי קשר אחרונים", "icon": "person_add", "color": "#04557a", "type": "list", "position_x": 1, "position_y": 7, "width": 12, "height": 14, "options": {"collection": "contacts", "fields": ["full_name", "phone_e164", "email", "status"], "sort": ["-created_at"], "limit": 12}},
    {"name": "אינטראקציות אחרונות", "icon": "history", "color": "#1a74a4", "type": "list", "position_x": 13, "position_y": 7, "width": 12, "height": 14, "options": {"collection": "interactions", "fields": ["contact_id", "type", "status", "summary", "result", "next_action_at"], "sort": ["-created_at"], "limit": 12}},
    {"name": "הרשמות לסדנאות", "icon": "school", "color": "#eba064", "type": "list", "position_x": 1, "position_y": 21, "width": 12, "height": 10, "options": {"collection": "workshop_registrations", "sort": ["-date_created"], "limit": 10}},
    {"name": "מכירות אחרונות", "icon": "shopping_cart", "color": "#ca553b", "type": "list", "position_x": 13, "position_y": 21, "width": 12, "height": 10, "options": {"collection": "transactions", "fields": ["contact_id", "amount", "currency", "source", "status", "date"], "sort": ["-date"], "limit": 10, "filter": {"direction": {"_eq": "income"}}}},
]:
    panel["dashboard"] = crm_id
    api("post", "/panels", panel)
print(f"  CRM dashboard: {crm_id}")

# Accounting & Finance
fin = api("post", "/dashboards", {"name": "הנהלת חשבונות ובקרה פיננסית", "icon": "account_balance", "color": "#eba064", "note": "עסקאות, קבלות, שורות בנק, התאמות ובקרה פיננסית"})
fin_id = fin.json()["data"]["id"]
for panel in [
    {"name": 'סה"כ עסקאות', "icon": "payments", "color": "#eba064", "type": "metric", "position_x": 1, "position_y": 1, "width": 5, "height": 6, "options": {"collection": "transactions", "function": "count"}},
    {"name": "קבלות", "icon": "receipt_long", "color": "#04557a", "type": "metric", "position_x": 6, "position_y": 1, "width": 5, "height": 6, "options": {"collection": "receipts", "function": "count"}},
    {"name": "שורות בנק", "icon": "account_balance", "color": "#1a74a4", "type": "metric", "position_x": 11, "position_y": 1, "width": 5, "height": 6, "options": {"collection": "bank_rows", "function": "count"}},
    {"name": "התאמות בנק", "icon": "compare_arrows", "color": "#2C6B4F", "type": "metric", "position_x": 16, "position_y": 1, "width": 5, "height": 6, "options": {"collection": "bank_recon", "function": "count"}},
    {"name": "אירועי תשלום", "icon": "radar", "color": "#ca553b", "type": "metric", "position_x": 21, "position_y": 1, "width": 4, "height": 6, "options": {"collection": "payment_events_raw", "function": "count"}},
    {"name": "הכנסות אחרונות", "icon": "trending_up", "color": "#2E8B57", "type": "list", "position_x": 1, "position_y": 7, "width": 12, "height": 12, "options": {"collection": "transactions", "fields": ["contact_id", "counterparty_name", "amount", "currency", "source", "payment_method", "date", "status"], "sort": ["-date"], "limit": 12, "filter": {"direction": {"_eq": "income"}}}},
    {"name": "הוצאות אחרונות", "icon": "trending_down", "color": "#ca553b", "type": "list", "position_x": 13, "position_y": 7, "width": 12, "height": 12, "options": {"collection": "transactions", "fields": ["contact_id", "counterparty_name", "amount", "currency", "source", "payment_method", "date", "status"], "sort": ["-date"], "limit": 12, "filter": {"direction": {"_eq": "expense"}}}},
    {"name": "שורות בנק אחרונות", "icon": "list_alt", "color": "#1a74a4", "type": "list", "position_x": 1, "position_y": 19, "width": 12, "height": 12, "options": {"collection": "bank_rows", "fields": ["date", "amount", "direction", "counterparty", "memo", "balance", "category_id"], "sort": ["-date"], "limit": 12}},
    {"name": "קבלות אחרונות", "icon": "receipt", "color": "#04557a", "type": "list", "position_x": 13, "position_y": 19, "width": 12, "height": 12, "options": {"collection": "receipts", "fields": ["receipt_number", "transaction_id", "issued_at", "section_46", "note"], "sort": ["-issued_at"], "limit": 12}},
    {"name": "שגיאות ייבוא", "icon": "error", "color": "#CC3333", "type": "list", "position_x": 1, "position_y": 31, "width": 12, "height": 8, "options": {"collection": "import_failures", "sort": ["-date_created"], "limit": 8}},
    {"name": "אירועי תשלום גולמיים", "icon": "raw_on", "color": "#8B6914", "type": "list", "position_x": 13, "position_y": 31, "width": 12, "height": 8, "options": {"collection": "payment_events_raw", "fields": ["provider", "external_ref", "processed_status", "received_at"], "sort": ["-received_at"], "limit": 8}},
]:
    panel["dashboard"] = fin_id
    api("post", "/panels", panel)
print(f"  Finance dashboard: {fin_id}")

print("\nAll customizations applied successfully!")
