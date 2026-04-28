from unittest.mock import patch
from voice_service import VoiceService
import struct

svc = VoiceService()
LOUD_AUDIO = struct.pack("500h", *([1000] * 500))

def test_analyze_returns_emotion_dict():
    mock_response = {"emotion": "happy", "confidence": 0.75}
    with patch.object(svc, "_call_api", return_value=mock_response):
        result = svc.analyze(LOUD_AUDIO)
    assert result["emotion"] == "happy"

def test_analyze_returns_none_below_volume_threshold():
    result = svc.analyze(b"\x00" * 1000)
    assert result is None

def test_analyze_returns_none_on_api_error():
    with patch.object(svc, "_call_api", side_effect=Exception("network error")):
        result = svc.analyze(LOUD_AUDIO)
    assert result is None
