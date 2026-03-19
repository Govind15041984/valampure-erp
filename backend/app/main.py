import os
from dotenv import load_dotenv
# 1. LOAD THE ENVIRONMENT FIRST
load_dotenv() 

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.profiles_router import router as profiles_router
from app.api.manufacturing_router import router as manufacturing_router
from app.api.partner_router import router as partner_router
from app.api.purchase_router import router as purchase_router
from app.api.upload_router import router as upload_router
from app.api.sales_router import router as sales_router
from app.api.payments_router import router as payment_router
from app.api.dashboard_router import router as dashboard_router
from app.api.expenses_router import router as expenses_router
from app.api.staff_router import router as staff_router
from app.services.minio_service import init_minio



app = FastAPI(title="VALAMPURE API", version="1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Mandatory for local Flutter testing
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Buckets
init_minio()

app.include_router(profiles_router, prefix="/auth")
app.include_router(manufacturing_router, prefix="/manufacturing")
app.include_router(partner_router, prefix="/partners")
app.include_router(purchase_router, prefix="/purchases")
app.include_router(upload_router, prefix="/uploads")
app.include_router(sales_router, prefix="/sales")
app.include_router(payment_router, prefix="/payments")
app.include_router(dashboard_router, prefix="/dashboard")
app.include_router(expenses_router, prefix="/expenses")
app.include_router(staff_router, prefix="/staff-salary")


@app.get("/health")
def health_check():
    return {"status": "VALAMPURI running"}

