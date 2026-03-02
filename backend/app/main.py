import os
from dotenv import load_dotenv
# 1. LOAD THE ENVIRONMENT FIRST
load_dotenv() 

from fastapi import FastAPI
from app.api.profiles_router import router as profiles_router


app = FastAPI(title="VALAMPURE API", version="1.0")

app.include_router(profiles_router, prefix="/auth")


@app.get("/health")
def health_check():
    return {"status": "VALAMPURE running"}

