from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from emotion_service import EmotionService
from fusion_service import fuse_emotions
from routers.sessions import _session_state
from database import SessionLocal
import data_service
import json
from datetime import datetime

router = APIRouter()

@router.websocket("/emotion/stream/{session_id}")
async def emotion_stream(websocket: WebSocket, session_id: str):
    await websocket.accept()
    service = EmotionService()
    last_log_time = datetime.utcnow()
    try:
        while True:
            jpeg_bytes = await websocket.receive_bytes()
            print(f"[frame] {len(jpeg_bytes)}B", flush=True)
            face_result = service.process(jpeg_bytes)
            if face_result:
                print(f"[DeepFace] {face_result['emotion']} {face_result['confidence']:.0%}", flush=True)
            fused = fuse_emotions(face=face_result, voice=None, heart=None)
            payload = fused.copy() if fused else {"emotion": None, "confidence": 0.0}
            payload["source"] = "fused" if fused else "none"
            if fused and session_id in _session_state:
                _session_state[session_id]["fused_emotion"] = fused["emotion"]
                _session_state[session_id]["fused_confidence"] = fused["confidence"]
            now = datetime.utcnow()
            if fused and (now - last_log_time).total_seconds() >= 2:
                db = SessionLocal()
                try:
                    data_service.create_emotion_log(db, session_id=session_id,
                                                    emotion=fused["emotion"], confidence=fused["confidence"],
                                                    source="fused", adaptive_action="none")
                finally:
                    db.close()
                last_log_time = now
            await websocket.send_text(json.dumps(payload))
    except WebSocketDisconnect:
        pass
