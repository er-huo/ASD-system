from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from schemas import ChildCreate, ChildResponse
import data_service

router = APIRouter(prefix="/children", tags=["children"])

@router.post("", response_model=ChildResponse)
def create_child(data: ChildCreate, db: Session = Depends(get_db)):
    return data_service.create_child(db, data)

@router.get("", response_model=list[ChildResponse])
def list_children(db: Session = Depends(get_db)):
    return data_service.list_children(db)
