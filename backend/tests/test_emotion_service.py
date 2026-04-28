from unittest.mock import patch
from emotion_service import EmotionService

service = EmotionService()

def test_analyze_returns_emotion_and_confidence():
    fake_result = [{"emotion": {"happy": 80.0, "sad": 10.0, "angry": 5.0,
                                "fear": 2.0, "surprise": 1.5, "neutral": 1.0, "confused": 0.5}}]
    with patch("emotion_service.DeepFace.analyze", return_value=fake_result):
        result = service.analyze_frame(b"fake_jpeg_bytes")
    assert result["emotion"] == "happy"
    assert 0.0 < result["confidence"] <= 1.0

def test_analyze_returns_none_on_no_face():
    with patch("emotion_service.DeepFace.analyze", side_effect=ValueError("Face could not be detected")):
        result = service.analyze_frame(b"no_face")
    assert result is None

def test_smoothed_emotion_uses_3_frame_average():
    service2 = EmotionService()
    frames = [{"emotion": "happy", "confidence": 0.9},
               {"emotion": "happy", "confidence": 0.8},
               {"emotion": "sad", "confidence": 0.7}]
    for f in frames:
        service2._push_frame(f)
    smoothed = service2.get_smoothed()
    assert smoothed["emotion"] == "happy"
