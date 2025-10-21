from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class TransactionCreate(BaseModel):
    sms_text: str = Field(..., description="Original SMS message from bank")
    user_input: str = Field(..., description="User input like 'mom, apples'")


class TransactionResponse(BaseModel):
    id: int
    date: str
    time: Optional[str]
    amount: float
    transaction_type: str
    sender_receiver_info: Optional[str]
    applicable_to: Optional[str]
    reason: Optional[str]
    full_text: str
    sms_text: str
    created_at: datetime

    class Config:
        from_attributes = True


class TransactionListResponse(BaseModel):
    transactions: list[TransactionResponse]
    total: int
    page: int
    page_size: int
