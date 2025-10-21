from sqlalchemy import Column, Integer, String, Float, DateTime, Text
from datetime import datetime
from database import Base


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    date = Column(String(20), nullable=False)  # Date from SMS (DD-MM-YY format)
    time = Column(String(20), nullable=True)  # Time extracted if available
    amount = Column(Float, nullable=False)
    transaction_type = Column(String(20), nullable=False)  # 'sent' or 'received'
    sender_receiver_info = Column(String(255), nullable=True)  # UPI ID or account number
    applicable_to = Column(String(100), nullable=True)  # Person (mom, dad, etc.)
    reason = Column(String(255), nullable=True)  # Reason for transaction (apples, etc.)
    full_text = Column(Text, nullable=False)  # Complete user input
    sms_text = Column(Text, nullable=False)  # Original SMS message
    created_at = Column(DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "date": self.date,
            "time": self.time,
            "amount": self.amount,
            "transaction_type": self.transaction_type,
            "sender_receiver_info": self.sender_receiver_info,
            "applicable_to": self.applicable_to,
            "reason": self.reason,
            "full_text": self.full_text,
            "sms_text": self.sms_text,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
