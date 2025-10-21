from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List
from database import get_db
from models import Transaction
from schemas import TransactionCreate, TransactionResponse, TransactionListResponse
from parser import parse_kotak_sms, parse_user_input

router = APIRouter(prefix="/api/transactions", tags=["transactions"])


@router.post("/", response_model=TransactionResponse, status_code=201)
async def create_transaction(
    transaction_data: TransactionCreate,
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new transaction from SMS text and user input.
    
    - **sms_text**: Original bank SMS message
    - **user_input**: User's input like "mom, apples"
    """
    try:
        # Parse SMS to extract transaction details
        parsed_sms = parse_kotak_sms(transaction_data.sms_text)
        
        # Parse user input to get person and reason
        applicable_to, reason = parse_user_input(transaction_data.user_input)
        
        # Create transaction object
        transaction = Transaction(
            date=parsed_sms.get("date") or "",
            time=parsed_sms.get("time"),
            amount=parsed_sms.get("amount", 0.0),
            transaction_type=parsed_sms.get("transaction_type", "unknown"),
            sender_receiver_info=parsed_sms.get("sender_receiver_info"),
            applicable_to=applicable_to,
            reason=reason,
            full_text=transaction_data.user_input,
            sms_text=transaction_data.sms_text
        )
        
        db.add(transaction)
        await db.commit()
        await db.refresh(transaction)
        
        return transaction
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create transaction: {str(e)}")


@router.get("/", response_model=TransactionListResponse)
async def get_transactions(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=100, description="Items per page"),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all transactions with pagination.
    
    - **page**: Page number (default: 1)
    - **page_size**: Number of items per page (default: 50, max: 100)
    """
    try:
        # Calculate offset
        offset = (page - 1) * page_size
        
        # Get total count
        count_query = select(func.count(Transaction.id))
        total_result = await db.execute(count_query)
        total = total_result.scalar()
        
        # Get paginated transactions, ordered by created_at descending (newest first)
        query = (
            select(Transaction)
            .order_by(Transaction.created_at.desc())
            .offset(offset)
            .limit(page_size)
        )
        result = await db.execute(query)
        transactions = result.scalars().all()
        
        return TransactionListResponse(
            transactions=transactions,
            total=total,
            page=page,
            page_size=page_size
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch transactions: {str(e)}")


@router.get("/{transaction_id}", response_model=TransactionResponse)
async def get_transaction(
    transaction_id: int,
    db: AsyncSession = Depends(get_db)
):
    """Get a specific transaction by ID"""
    query = select(Transaction).where(Transaction.id == transaction_id)
    result = await db.execute(query)
    transaction = result.scalar_one_or_none()
    
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    return transaction
