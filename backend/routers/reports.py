from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from schemas import ReportResponse
import data_service

router = APIRouter(prefix="/report", tags=["reports"])

@router.get("/{child_id}", response_model=ReportResponse)
def get_report(child_id: str, db: Session = Depends(get_db)):
    return data_service.get_report(db, child_id)
