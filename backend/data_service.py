from datetime import datetime
from collections import Counter
from sqlalchemy.orm import Session
from models import Child, Session as SessionModel, Answer, EmotionLog, BktState
from schemas import ChildCreate
from config import EMOTION_CLASSES
import uuid

def create_child(db: Session, data: ChildCreate) -> Child:
    child = Child(id=str(uuid.uuid4()), name=data.name, age=data.age, robot_preference=data.robot_preference)
    db.add(child)
    db.flush()
    for emotion in EMOTION_CLASSES:
        db.add(BktState(child_id=child.id, emotion=emotion, p_known=0.10))
    db.commit()
    db.refresh(child)
    return child

def list_children(db: Session) -> list:
    return db.query(Child).order_by(Child.created_at.desc()).all()

def create_session(db: Session, child_id: str, activity_type: str) -> SessionModel:
    db.query(SessionModel).filter(
        SessionModel.child_id == child_id, SessionModel.ended_at.is_(None)
    ).update({"ended_at": datetime.utcnow()})
    session = SessionModel(id=str(uuid.uuid4()), child_id=child_id, activity_type=activity_type)
    db.add(session)
    db.commit()
    db.refresh(session)
    return session

def record_answer(db: Session, session_id: str, emotion_target: str,
                  user_response: str, response_ms: int, hint_shown: bool,
                  difficulty_level: int) -> Answer:
    answer = Answer(
        session_id=session_id, emotion_target=emotion_target,
        user_response=user_response, is_correct=(user_response == emotion_target),
        response_ms=response_ms, hint_shown=hint_shown, difficulty_level=difficulty_level,
    )
    db.add(answer)
    db.commit()
    db.refresh(answer)
    return answer

def end_session(db: Session, session_id: str) -> SessionModel:
    session = db.query(SessionModel).filter(SessionModel.id == session_id).first()
    if not session:
        return None
    answers = db.query(Answer).filter(Answer.session_id == session_id).all()
    logs = db.query(EmotionLog).filter(EmotionLog.session_id == session_id).all()
    if answers:
        session.accuracy = sum(1 for a in answers if a.is_correct) / len(answers)
        session.avg_response_ms = sum(a.response_ms for a in answers) // len(answers)
    if logs:
        emotion_counts = Counter(l.emotion for l in logs if l.source == "fused")
        session.dominant_child_emotion = emotion_counts.most_common(1)[0][0] if emotion_counts else None
    session.ended_at = datetime.utcnow()
    db.commit()
    db.refresh(session)
    return session

def update_bkt_state(db: Session, child_id: str, emotion: str, p_known: float):
    state = db.query(BktState).filter(BktState.child_id == child_id, BktState.emotion == emotion).first()
    if state:
        state.p_known = p_known
        state.updated_at = datetime.utcnow()
        db.commit()

def get_bkt_states(db: Session, child_id: str) -> list:
    return db.query(BktState).filter(BktState.child_id == child_id).all()

def create_emotion_log(db: Session, session_id: str, emotion: str,
                       confidence: float, source: str, adaptive_action: str):
    log = EmotionLog(session_id=session_id, emotion=emotion, confidence=confidence,
                     source=source, adaptive_action=adaptive_action)
    db.add(log)
    db.commit()

def get_report(db: Session, child_id: str) -> dict:
    bkt_states = get_bkt_states(db, child_id)
    sessions = db.query(SessionModel).filter(
        SessionModel.child_id == child_id, SessionModel.ended_at.isnot(None)
    ).order_by(SessionModel.started_at.desc()).all()
    answers = db.query(Answer).join(SessionModel, Answer.session_id == SessionModel.id).filter(
        SessionModel.child_id == child_id).all()
    emotion_totals: dict = {}
    for a in answers:
        emotion_totals.setdefault(a.emotion_target, []).append(a.is_correct)
    return {
        "child_id": child_id,
        "bkt_states": [{"emotion": s.emotion, "p_known": s.p_known} for s in bkt_states],
        "accuracy_by_emotion": {e: sum(v)/len(v) for e, v in emotion_totals.items()},
        "sessions": [{"id": s.id, "activity_type": s.activity_type,
                      "accuracy": s.accuracy, "started_at": str(s.started_at)} for s in sessions],
    }
