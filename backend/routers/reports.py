import models
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from schemas import ReportResponse
import data_service

router = APIRouter(prefix="/report", tags=["reports"])

@router.get("/{child_id}", response_model=ReportResponse)
def get_report(child_id: str, db: Session = Depends(get_db)):
    child = db.query(models.Child).filter_by(id=child_id).first()
    if not child:
        raise HTTPException(404, "Child not found")
    return data_service.get_report(db, child_id)

@router.get("/session/{session_id}/emotions")
def get_session_emotions(session_id: str, db: Session = Depends(get_db)):
    """Return emotion logs for a session, for the trend chart."""
    logs = (db.query(models.EmotionLog)
            .filter(models.EmotionLog.session_id == session_id)
            .order_by(models.EmotionLog.logged_at)
            .all())
    return [{"emotion": l.emotion, "confidence": float(l.confidence),
             "logged_at": l.logged_at.isoformat()} for l in logs]
