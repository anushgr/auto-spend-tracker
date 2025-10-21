from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from database import init_db
from routes import router as transactions_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize database on startup"""
    await init_db()
    yield


app = FastAPI(
    title="Auto Spend Tracker API",
    description="Backend API for tracking expenses from bank SMS messages",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware to allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(transactions_router)


@app.get("/")
async def root():
    return {
        "message": "Auto Spend Tracker API",
        "version": "1.0.0",
        "endpoints": {
            "transactions": "/api/transactions",
            "docs": "/docs",
            "redoc": "/redoc"
        }
    }


@app.get("/health")
async def health_check():
    return {"status": "healthy"}
