from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import create_access_token, get_current_user
from app.services.profiles_service import (
    get_profile_by_mobile, 
    authenticate_profile,
    create_profile,      # Ensure this is imported
    update_profile_details # Ensure this is imported
)
from app.schemas.profiles_schema import (
    UserCreate,
    ProfileUpdate,
    ProfileOut,
    LoginRequest,       # You need to add this to your schemas.py
)
from app.models.profiles_model import Profile

router = APIRouter(tags=["Auth"])

# 1. NEW GATEKEEPER ENDPOINT
# USE: Checks if a mobile number is already in the 'valampure' schema.
# WHEN: Called by MobileScreen to decide between Signup and PIN screen.
@router.get("/check-user/{mobile}")
def check_user(mobile: str, db: Session = Depends(get_db)):
    user = get_profile_by_mobile(db, mobile)
    return {"exists": True if user else False}

# 2. UPDATED SIGNUP
@router.post("/signup", response_model=ProfileOut)
def signup(data: UserCreate, db: Session = Depends(get_db)):
    existing_user = get_profile_by_mobile(db, data.mobile)
    if existing_user:
        raise HTTPException(status_code=400, detail="Mobile already registered")
    return create_profile(db, data)

# 3. FIXED LOGIN (Prevents 422 Error)
# Changed from (mobile: str, pin: str) to (data: LoginRequest)
# This allows FastAPI to read the JSON body from Flutter.
@router.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = authenticate_profile(db, data.mobile, data.pin)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid Credentials")
    
    access_token = create_access_token(data={"sub": str(user.id), "role": user.role})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id, 
            "company": user.company_name, 
            "role": user.role
        }
    }

# 4. UPDATE PROFILE
@router.put("/update", response_model=ProfileOut)
def update_my_profile(
    data: ProfileUpdate, 
    db: Session = Depends(get_db), 
    current_user: Profile = Depends(get_current_user)
):
    updated_profile = update_profile_details(db, current_user.id, data)
    if not updated_profile:
        raise HTTPException(status_code=404, detail="Profile update failed")
    return updated_profile

# 5. GET MY PROFILE (The Missing Piece)
# USE: Fetches company name, GSTIN, and Bank details for Invoices.
@router.get("/me", response_model=ProfileOut)
def get_my_profile(
    current_user: Profile = Depends(get_current_user)
):
    # current_user is already fetched from the DB by the dependency
    return current_user