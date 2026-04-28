import os
import struct
from typing import Optional

VOLUME_THRESHOLD = 30
MIN_AUDIO_BYTES = 500

class VoiceService:
    def __init__(self):
        self._api_key = os.getenv("TENCENT_API_KEY", "")
        self._api_secret = os.getenv("TENCENT_API_SECRET", "")

    def _is_loud_enough(self, audio_bytes: bytes) -> bool:
        if len(audio_bytes) < MIN_AUDIO_BYTES:
            return False
        samples = struct.unpack(f"{len(audio_bytes)//2}h", audio_bytes[:len(audio_bytes) & ~1])
        rms = (sum(s**2 for s in samples) / max(len(samples), 1)) ** 0.5
        return rms > VOLUME_THRESHOLD

    def _call_api(self, audio_bytes: bytes) -> dict:
        raise NotImplementedError("Configure TENCENT_API_KEY to enable voice analysis")

    def analyze(self, audio_bytes: bytes) -> Optional[dict]:
        if not self._is_loud_enough(audio_bytes):
            return None
        try:
            return self._call_api(audio_bytes)
        except Exception:
            return None
