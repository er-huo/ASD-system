import uuid
from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, UniqueConstraint
from database import Base

def _uuid():
    return str(uuid.uuid4())

class Child(Base):
    __tablename__ = "children"
    id = Column(String, primary_key=True, default=_uuid)
    name = Column(String, nullable=False)
    age = Column(Integer)
    robot_preference = Column(String, default="tino")
    current_difficulty_level = Column(Integer, default=1)
    created_at = Column(DateTime, default=datetime.utcnow)

class Session(Base):
    __tablename__ = "sessions"
    id = Column(String, primary_key=True, default=_uuid)
    child_id = Column(String, ForeignKey("children.id"), nullable=False)
    activity_type = Column(String, nullable=False)
    started_at = Column(DateTime, default=datetime.utcnow)
    ended_at = Column(DateTime)
    accuracy = Column(Float)
    avg_response_ms = Column(Integer)
    dominant_child_emotion = Column(String)

class Answer(Base):
    __tablename__ = "answers"
    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(String, ForeignKey("sessions.id"), nullable=False)
    emotion_target = Column(String, nullable=False)
    user_response = Column(String)
    is_correct = Column(Boolean)
    response_ms = Column(Integer)
    difficulty_level = Column(Integer)
    hint_shown = Column(Boolean, default=False)
    timestamp = Column(DateTime, default=datetime.utcnow)

class EmotionLog(Base):
    __tablename__ = "emotion_logs"
    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(String, ForeignKey("sessions.id"), nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)
    emotion = Column(String)
    confidence = Column(Float)
    source = Column(String)
    adaptive_action = Column(String)

class BktState(Base):
    __tablename__ = "bkt_states"
    id = Column(Integer, primary_key=True, autoincrement=True)
    child_id = Column(String, ForeignKey("children.id"), nullable=False)
    emotion = Column(String, nullable=False)
    p_known = Column(Float, default=0.10)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    __table_args__ = (UniqueConstraint("child_id", "emotion"),)
