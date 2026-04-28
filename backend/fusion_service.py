from config import FUSION_WEIGHTS
from typing import Optional

def fuse_emotions(face: Optional[dict], voice: Optional[dict], heart: Optional[dict] = None) -> Optional[dict]:
    if face is None:
        return None
    if voice is None and heart is None:
        key = "face_only"
    elif voice is None:
        key = "face_heart"
    elif heart is None:
        key = "face_voice"
    else:
        key = "face_voice_heart"
    w_face, w_voice, w_heart = FUSION_WEIGHTS[key]
    sources = [(face, w_face), (voice, w_voice), (heart, w_heart)]
    sources = [(s, w) for s, w in sources if s is not None]
    emotion_scores: dict = {}
    for signal, weight in sources:
        e = signal["emotion"]
        emotion_scores[e] = emotion_scores.get(e, 0.0) + signal["confidence"] * weight
    best_emotion = max(emotion_scores, key=emotion_scores.get)
    return {"emotion": best_emotion, "confidence": round(emotion_scores[best_emotion], 3)}
