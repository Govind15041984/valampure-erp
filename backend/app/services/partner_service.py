from sqlalchemy.orm import Session
from sqlalchemy import and_
from uuid import UUID
from app.models.partner_model import Partner, PartnerType
from app.schemas.partner_schema import PartnerCreate, PartnerUpdate

def create_partner(db: Session, data: PartnerCreate, profile_id: UUID):
    # Initialize the partner with current_balance same as opening_balance
    db_partner = Partner(
        **data.model_dump(),
        profile_id=profile_id,
        current_balance=data.opening_balance
    )
    db.add(db_partner)
    db.commit()
    db.refresh(db_partner)
    return db_partner

def get_partners_by_type(db: Session, profile_id: UUID, partner_type: PartnerType):
    return db.query(Partner).filter(
        and_(
            Partner.profile_id == profile_id,
            Partner.partner_type == partner_type,
            Partner.is_active == True
        )
    ).all()

def get_partner_details(db: Session, partner_id: UUID, profile_id: UUID):
    return db.query(Partner).filter(
        Partner.id == partner_id, 
        Partner.profile_id == profile_id
    ).first()

def update_partner(db: Session, partner_id: UUID, profile_id: UUID, data: PartnerUpdate):
    db_partner = get_partner_details(db, partner_id, profile_id)
    if not db_partner:
        return None
    
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_partner, key, value)
    
    db.commit()
    db.refresh(db_partner)
    return db_partner