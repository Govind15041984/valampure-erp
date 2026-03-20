from sqlalchemy.orm import Session
from passlib.context import CryptContext
from app.models.profiles_model import Profile
from app.schemas.profiles_schema import UserCreate, ProfileUpdate
from uuid import UUID
from typing import Union, Dict, Any

# Setup for PIN encryption
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_pin(pin: str) -> str:
    return pwd_context.hash(pin)

def verify_pin(plain_pin: str, hashed_pin: str) -> bool:
    return pwd_context.verify(plain_pin, hashed_pin)

def get_profile_by_mobile(db: Session, mobile_number: str):
    return db.query(Profile).filter(Profile.mobile_number == mobile_number).first()

def create_profile(db: Session, data: UserCreate):
    pin_hash = hash_pin(data.pin)
    profile = Profile(
        mobile_number=data.mobile,
        owner_name=data.owner_name,
        company_name=data.company_name,
        pin_hash=pin_hash,
        role=data.role if data.role else "OWNER"
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile

def authenticate_profile(db: Session, mobile_number: str, pin: str):
    profile = get_profile_by_mobile(db, mobile_number)
    if not profile:
        return None
        
    is_valid = verify_pin(pin, profile.pin_hash)
    if not is_valid:
        return None
    return profile

# --- UPDATED UPDATE FUNCTION ---
def update_profile_details(db: Session, profile_id: Union[str, UUID], data: Union[ProfileUpdate, Dict[str, Any]]):
    """
    Updates specific fields. Now accepts either a Pydantic model 
    OR a pre-processed dictionary (needed for MinIO logo logic).
    """
    db_query = db.query(Profile).filter(Profile.id == profile_id)
    db_profile = db_query.first()
    
    if not db_profile:
        return None
        
    # If data is a Pydantic model, convert to dict. 
    # If it's already a dict (from our router logic), use it as is.
    if isinstance(data, dict):
        update_data = data
    else:
        update_data = data.model_dump(exclude_unset=True)
    
    # Apply the updates to the database record
    db_query.update(update_data, synchronize_session=False)
    
    db.commit()
    db.refresh(db_profile)
    return db_profile