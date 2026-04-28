from datetime import datetime
from typing import Literal, Optional
from pydantic import BaseModel

class ChildCreate(BaseModel):
    name: str
    age: Optional[int] = None
    robot_preference: Literal["tino", "tina"] = "tino"

class ChildResponse(BaseModel):
    id: str
    name: str
    age: Optional[int]
    robot_preference: str
    current_difficulty_level: int
    created_at: datetime
    model_config = {"from_attributes": True}

class SessionStartRequest(BaseModel):
    child_id: str
    activity_type: Literal["detective", "match", "face_build", "social", "diary"]

class QuestionPayload(BaseModel):
    id: str
    activity_type: str
    emotion_target: str
    difficulty_level: int
    stimuli_type: str
    stimuli_path: str
    choices: list[str]
    correct_answer: str
    n_pairs: Optional[int] = None
    elements: Optional[list[str]] = None
    scenario: Optional[str] = None
    question_text: Optional[str] = None

class SessionStartResponse(BaseModel):
    session_id: str
    first_question: Optional[QuestionPayload]
    difficulty: Optional[int]

class AnswerRequest(BaseModel):
    session_id: str
    emotion_target: str
    user_response: str
    response_ms: int
    hint_shown: bool = False

class AnswerResponse(BaseModel):
    is_correct: bool
    adaptive_action: str
    next_question: Optional[QuestionPayload]
    difficulty: int

class SessionEndRequest(BaseModel):
    session_id: str

class SessionEndResponse(BaseModel):
    accuracy: Optional[float]
    dominant_child_emotion: Optional[str]
    total_questions: int

class BktStateOut(BaseModel):
    emotion: str
    p_known: float

class ReportResponse(BaseModel):
    child_id: str
    bkt_states: list[BktStateOut]
    accuracy_by_emotion: dict[str, float]
    sessions: list[dict]
