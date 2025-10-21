import re
from typing import Tuple, Optional


def parse_kotak_sms(sms_text: str) -> dict:
    """
    Parse Kotak bank SMS to extract transaction details.
    
    Example SMS:
    "Sent Rs.236.00 from Kotak Bank AC X0396 to vyapar.172400950852@hdfcbank on 05-07-25.UPI Ref 555256646612."
    
    Returns dict with: amount, transaction_type, sender_receiver_info, date
    """
    result = {
        "amount": 0.0,
        "transaction_type": "unknown",
        "sender_receiver_info": None,
        "date": None,
        "time": None
    }
    
    # Extract amount (Rs.XXX.XX or Rs.XXX)
    amount_match = re.search(r'Rs\.?(\d+(?:,\d+)*(?:\.\d+)?)', sms_text, re.IGNORECASE)
    if amount_match:
        amount_str = amount_match.group(1).replace(',', '')
        result["amount"] = float(amount_str)
    
    # Determine transaction type (Sent or Received/Credited)
    if re.search(r'\b(sent|debited|paid)\b', sms_text, re.IGNORECASE):
        result["transaction_type"] = "sent"
    elif re.search(r'\b(received|credited|deposited)\b', sms_text, re.IGNORECASE):
        result["transaction_type"] = "received"
    
    # Extract UPI ID or account info
    # UPI ID format: something@bankname
    upi_match = re.search(r'([\w\.-]+@[\w]+)', sms_text)
    if upi_match:
        result["sender_receiver_info"] = upi_match.group(1)
    else:
        # Try to extract account number (AC XXXXX or A/c XXXXX)
        account_match = re.search(r'A[Cc/]\s*([A-Z0-9]+)', sms_text)
        if account_match:
            result["sender_receiver_info"] = f"AC {account_match.group(1)}"
    
    # Extract date (DD-MM-YY format)
    date_match = re.search(r'(\d{2}-\d{2}-\d{2})', sms_text)
    if date_match:
        result["date"] = date_match.group(1)
    
    return result


def parse_user_input(user_input: str) -> Tuple[Optional[str], Optional[str]]:
    """
    Parse user input like 'mom, apples' or 'dad,groceries'
    
    Returns: (applicable_to, reason)
    """
    if not user_input or not user_input.strip():
        return None, None
    
    # Split by comma
    parts = [part.strip() for part in user_input.split(',')]
    
    applicable_to = parts[0] if len(parts) > 0 else None
    reason = parts[1] if len(parts) > 1 else None
    
    return applicable_to, reason
