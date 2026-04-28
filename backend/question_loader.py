import json
import random
from pathlib import Path
from typing import Optional

_BANK_DIR = Path(__file__).parent / "question_bank"
_ACTIVITY_FILES = ["detective", "match", "face_build", "social"]


class QuestionLoader:
    def __init__(self):
        self.index: dict = {}
        self._load()

    def _load(self):
        for activity in _ACTIVITY_FILES:
            path = _BANK_DIR / f"{activity}.json"
            if not path.exists():
                self.index[activity] = {}
                continue
            questions = json.loads(path.read_text(encoding="utf-8"))
            by_key: dict = {}
            for q in questions:
                key = (q["difficulty_level"], q["emotion_target"])
                by_key.setdefault(key, []).append(q)
            self.index[activity] = by_key

    def get_next_question(
        self,
        activity_type: str,
        difficulty: int,
        seen_ids: set,
        emotion_target: Optional[str] = None,
    ) -> Optional[dict]:
        bank = self.index.get(activity_type, {})
        if emotion_target:
            pool = [q for q in bank.get((difficulty, emotion_target), []) if q["id"] not in seen_ids]
            if pool:
                return random.choice(pool)
        # fall back: any emotion at this difficulty not yet seen
        all_at_diff = []
        for (diff, _emotion), qs in bank.items():
            if diff == difficulty:
                all_at_diff.extend(q for q in qs if q["id"] not in seen_ids)
        if all_at_diff:
            return random.choice(all_at_diff)
        return None


question_loader = QuestionLoader()
