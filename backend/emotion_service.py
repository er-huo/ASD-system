from collections import deque, Counter
from typing import Optional
import numpy as np
import cv2

# Lazy import — DeepFace is large; backend starts without it,
# emotion recognition silently returns None until it's installed.
try:
    from deepface import DeepFace
    _DEEPFACE_AVAILABLE = True
except Exception:          # catches ImportError, MemoryError, and any other init error
    DeepFace = None  # type: ignore
    _DEEPFACE_AVAILABLE = False

EMOTION_MAP = {
    "happy": "happy", "sad": "sad", "angry": "angry",
    "fear": "fear", "surprise": "surprise", "neutral": "neutral",
    "disgust": "angry",
}

class EmotionService:
    def __init__(self, window: int = 3):
        self._buffer: deque = deque(maxlen=window)

    def analyze_frame(self, jpeg_bytes: bytes) -> Optional[dict]:
        if not _DEEPFACE_AVAILABLE:
            return None
        try:
            arr = np.frombuffer(jpeg_bytes, np.uint8)
            img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
            results = DeepFace.analyze(img, actions=["emotion"], enforce_detection=False, silent=True)
            raw = results[0]["emotion"]
            total = sum(raw.values()) or 1.0
            dominant = max(raw, key=raw.get)
            mapped = EMOTION_MAP.get(dominant, "neutral")
            return {"emotion": mapped, "confidence": float(round(raw[dominant] / total, 3))}
        except Exception as e:
            print(f"[DeepFace ERR] {type(e).__name__}: {e}", flush=True)
            return None

    def _push_frame(self, result: dict):
        self._buffer.append(result)

    def process(self, jpeg_bytes: bytes) -> Optional[dict]:
        result = self.analyze_frame(jpeg_bytes)
        if result:
            self._push_frame(result)
        return self.get_smoothed() if self._buffer else None

    def get_smoothed(self) -> Optional[dict]:
        if not self._buffer:
            return None
        emotions = [f["emotion"] for f in self._buffer]
        dominant = Counter(emotions).most_common(1)[0][0]
        matching = [f["confidence"] for f in self._buffer if f["emotion"] == dominant]
        return {"emotion": dominant, "confidence": round(sum(matching)/len(matching), 3)}
