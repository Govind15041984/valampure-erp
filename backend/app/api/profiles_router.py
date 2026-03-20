from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import create_access_token, get_current_user
from app.services.profiles_service import (
    get_profile_by_mobile, 
    authenticate_profile,
    create_profile,
    update_profile_details
)
from app.schemas.profiles_schema import (
    UserCreate,
    ProfileUpdate,
    ProfileOut,
    LoginRequest,
)
from app.models.profiles_model import Profile
from app.services import minio_service

router = APIRouter(tags=["Auth"])

# 1. CHECK USER
# Checks if a mobile number is already registered
@router.get("/check-user/{mobile}")
def check_user(mobile: str, db: Session = Depends(get_db)):
    user = get_profile_by_mobile(db, mobile)
    return {"exists": True if user else False}

# 2. SIGNUP
@router.post("/signup", response_model=ProfileOut)
def signup(data: UserCreate, db: Session = Depends(get_db)):
    existing_user = get_profile_by_mobile(db, data.mobile)
    if existing_user:
        raise HTTPException(status_code=400, detail="Mobile already registered")
    return create_profile(db, data)

# 3. LOGIN
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

# 4. LOGO UPLOAD URL
# Flutter calls this to get a direct-to-MinIO upload link
@router.get("/logo-upload-url")
def get_logo_upload_url(current_user: Profile = Depends(get_current_user)):
    try:
        # UPDATED: Calling the generic profile presigned function
        return minio_service.generate_profile_presigned_url(str(current_user.id))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 5. UPDATE PROFILE
@router.put("/update", response_model=ProfileOut)
def update_my_profile(
    data: ProfileUpdate, 
    db: Session = Depends(get_db), 
    current_user: Profile = Depends(get_current_user)
):
    update_data = data.model_dump(exclude_unset=True)

    if data.logo_temp_name:
        try:
            # UPDATED: Calling the new finalize name
            final_logo_url = minio_service.finalize_profile_logo_update(
                str(current_user.id), 
                data.logo_temp_name
            )
            update_data["logo_url"] = final_logo_url
            update_data.pop("logo_temp_name", None)
        except Exception as e:
            print(f"⚠️ Logo move failed: {e}")

    updated_profile = update_profile_details(db, current_user.id, update_data)
    
    if not updated_profile:
        raise HTTPException(status_code=404, detail="Profile update failed")
    return updated_profile

# 6. GET MY PROFILE
@router.get("/me", response_model=ProfileOut)
def get_my_profile(current_user: Profile = Depends(get_current_user)):
    return current_user