import models
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session as DBSession
from database import get_db
from schemas import (SessionStartRequest, SessionStartResponse, AnswerRequest,
                     AnswerResponse, SessionEndRequest, SessionEndResponse, QuestionPayload)
import data_service
from adaptive_engine import update_bkt, decide_adaptive_action, clamp_difficulty
from question_loader import question_loader
from config import BKT_MASTERY_THRESHOLD

router = APIRouter(prefix="/session", tags=["sessions"])
_session_state: dict = {}

@router.post("/start", response_model=SessionStartResponse)
def start_session(req: SessionStartRequest, db: DBSession = Depends(get_db)):
    session = data_service.create_session(db, req.child_id, req.activity_type)
    child = db.query(models.Child).filter_by(id=req.child_id).first()
    if not child:
        raise HTTPException(404, "Child not found")
    bkt_states = {s.emotion: s.p_known for s in data_service.get_bkt_states(db, req.child_id)}
    diff = child.current_difficulty_level
    if req.activity_type == "diary":
        _session_state[session.id] = {"child_id": req.child_id, "difficulty": diff,
                                       "recent_answers": [], "seen_ids": set(), "bkt": bkt_states}
        return SessionStartResponse(session_id=session.id, first_question=None, difficulty=None)
    weakest = min(bkt_states, key=lambda e: bkt_states[e])
    q_dict = question_loader.get_next_question(req.activity_type, diff, seen_ids=set(), emotion_target=weakest)
    if not q_dict:
        q_dict = question_loader.get_next_question(req.activity_type, diff, seen_ids=set())
    if not q_dict:
        raise HTTPException(404, "No questions available")
    _session_state[session.id] = {
        "child_id": req.child_id, "activity_type": req.activity_type,
        "difficulty": diff, "recent_answers": [], "seen_ids": {q_dict["id"]},
        "bkt": bkt_states, "fused_emotion": "neutral", "fused_confidence": 0.5,
    }
    return SessionStartResponse(session_id=session.id, first_question=QuestionPayload(**q_dict), difficulty=diff)

@router.post("/answer", response_model=AnswerResponse)
def submit_answer(req: AnswerRequest, db: DBSession = Depends(get_db)):
    state = _session_state.get(req.session_id)
    if not state:
        raise HTTPException(404, "Session not found or expired")
    answer = data_service.record_answer(db, req.session_id, req.emotion_target, req.user_response,
                                        req.response_ms, req.hint_shown, state["difficulty"])
    old_p = state["bkt"].get(req.emotion_target, 0.10)
    new_p = update_bkt(old_p, answer.is_correct, state["difficulty"])
    state["bkt"][req.emotion_target] = new_p
    data_service.update_bkt_state(db, state["child_id"], req.emotion_target, new_p)
    state["recent_answers"].append(answer.is_correct)
    if len(state["recent_answers"]) > 5:
        state["recent_answers"] = state["recent_answers"][-5:]
    action = decide_adaptive_action(
        fused_emotion=state.get("fused_emotion", "neutral"),
        fused_confidence=state.get("fused_confidence", 0.5),
        recent_answers=state["recent_answers"],
        difficulty=state["difficulty"],
        response_ms=req.response_ms,
    )
    state["difficulty"] = clamp_difficulty(state["difficulty"], action)
    unmastered = {e: p for e, p in state["bkt"].items() if p < BKT_MASTERY_THRESHOLD}
    next_emotion = min(unmastered, key=lambda e: unmastered[e]) if unmastered else min(state["bkt"], key=lambda e: state["bkt"][e])
    next_q = question_loader.get_next_question(state["activity_type"], state["difficulty"], state["seen_ids"], emotion_target=next_emotion)
    if not next_q:
        next_q = question_loader.get_next_question(state["activity_type"], state["difficulty"], state["seen_ids"])
    if next_q:
        state["seen_ids"].add(next_q["id"])
    return AnswerResponse(is_correct=answer.is_correct, adaptive_action=action,
                          next_question=QuestionPayload(**next_q) if next_q else None,
                          difficulty=state["difficulty"])

@router.post("/end", response_model=SessionEndResponse)
def end_session(req: SessionEndRequest, db: DBSession = Depends(get_db)):
    session = data_service.end_session(db, req.session_id)
    if not session:
        raise HTTPException(404, "Session not found")
    _session_state.pop(req.session_id, None)
    answers_count = db.query(models.Answer).filter_by(session_id=req.session_id).count()
    return SessionEndResponse(accuracy=session.accuracy,
                               dominant_child_emotion=session.dominant_child_emotion,
                               total_questions=answers_count)
