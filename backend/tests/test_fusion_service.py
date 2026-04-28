from fusion_service import fuse_emotions

def test_face_only_returns_face_emotion():
    result = fuse_emotions(face={"emotion": "happy", "confidence": 0.8}, voice=None, heart=None)
    assert result["emotion"] == "happy"
    assert result["confidence"] == 0.8

def test_face_voice_weights_are_normalised():
    result = fuse_emotions(face={"emotion": "happy", "confidence": 0.8},
                            voice={"emotion": "happy", "confidence": 0.6}, heart=None)
    assert result["emotion"] == "happy"
    assert 0.6 < result["confidence"] <= 1.0

def test_conflicting_signals_picks_higher_weight():
    result = fuse_emotions(face={"emotion": "angry", "confidence": 0.9},
                            voice={"emotion": "happy", "confidence": 0.8}, heart=None)
    assert result["emotion"] == "angry"
