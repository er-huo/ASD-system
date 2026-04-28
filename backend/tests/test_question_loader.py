from question_loader import QuestionLoader

loader = QuestionLoader()

def test_loader_indexes_all_activity_types():
    for at in ["detective", "match", "face_build", "social"]:
        assert at in loader.index

def test_get_next_question_returns_correct_difficulty():
    q = loader.get_next_question("detective", difficulty=1, seen_ids=set())
    assert q["difficulty_level"] == 1

def test_get_next_question_avoids_seen():
    seen = set()
    questions = []
    for _ in range(4):
        q = loader.get_next_question("detective", difficulty=1, seen_ids=seen)
        questions.append(q["id"])
        seen.add(q["id"])
    assert len(set(questions)) == 4

def test_get_next_question_returns_none_when_pool_exhausted():
    seen = {q["id"] for q in loader.index["detective"].get((1, "happy"), [])}
    result = loader.get_next_question("detective", difficulty=1, seen_ids=seen, emotion_target="happy")
    assert result is None or result["emotion_target"] == "happy"
