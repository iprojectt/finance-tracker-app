"""
Bank CSV parser — handles common Indian bank statement formats.
"""
import csv
import io
from datetime import datetime

def _parse_date(date_str: str) -> str:
    """Try multiple date formats and return YYYY-MM-DD."""
    formats = ["%d/%m/%Y", "%d-%m-%Y", "%Y-%m-%d", "%d %b %Y", "%d-%b-%Y", "%d/%m/%y"]
    for fmt in formats:
        try:
            return datetime.strptime(date_str.strip(), fmt).strftime("%Y-%m-%d")
        except ValueError:
            continue
    raise ValueError(f"Unrecognized date format: {date_str}")

def parse_sbi(rows, account_id: str):
    transactions = []
    for row in rows:
        try:
            date = _parse_date(row.get("Date", row.get("Txn Date", "")))
            desc = row.get("Description", row.get("Narration", ""))
            debit = float(row.get("Debit", "0").replace(",", "") or 0)
            credit = float(row.get("Credit", "0").replace(",", "") or 0)
            if debit > 0:
                transactions.append({"accountId": account_id, "amount": debit, "type": "debit", "description": desc, "date": date})
            if credit > 0:
                transactions.append({"accountId": account_id, "amount": credit, "type": "credit", "description": desc, "date": date})
        except Exception:
            continue
    return transactions

def parse_hdfc(rows, account_id: str):
    transactions = []
    for row in rows:
        try:
            date = _parse_date(row.get("Date", ""))
            desc = row.get("Narration", "")
            debit = float(row.get("Withdrawal Amt.", "0").replace(",", "") or 0)
            credit = float(row.get("Deposit Amt.", "0").replace(",", "") or 0)
            if debit > 0:
                transactions.append({"accountId": account_id, "amount": debit, "type": "debit", "description": desc, "date": date})
            if credit > 0:
                transactions.append({"accountId": account_id, "amount": credit, "type": "credit", "description": desc, "date": date})
        except Exception:
            continue
    return transactions

def parse_generic(rows, account_id: str):
    transactions = []
    for row in rows:
        keys = {k.lower().strip(): v for k, v in row.items()}
        try:
            date_val = keys.get("date") or keys.get("txn date") or keys.get("value date") or ""
            date = _parse_date(date_val)
            desc = keys.get("description") or keys.get("narration") or keys.get("particulars") or ""
            debit_raw = keys.get("debit") or keys.get("withdrawal") or keys.get("withdrawal amt.") or "0"
            credit_raw = keys.get("credit") or keys.get("deposit") or keys.get("deposit amt.") or "0"
            debit = float(str(debit_raw).replace(",", "") or 0)
            credit = float(str(credit_raw).replace(",", "") or 0)
            if debit > 0:
                transactions.append({"accountId": account_id, "amount": debit, "type": "debit", "description": desc, "date": date})
            if credit > 0:
                transactions.append({"accountId": account_id, "amount": credit, "type": "credit", "description": desc, "date": date})
        except Exception:
            continue
    return transactions

BANK_PARSERS = {
    "sbi": parse_sbi,
    "hdfc": parse_hdfc,
    "generic": parse_generic,
}

def parse_bank_csv(content: str, account_id: str, bank: str = "generic") -> list:
    reader = csv.DictReader(io.StringIO(content))
    rows = list(reader)
    if not rows:
        raise ValueError("CSV is empty or has no data rows")
    parser = BANK_PARSERS.get(bank.lower(), parse_generic)
    return parser(rows, account_id)
