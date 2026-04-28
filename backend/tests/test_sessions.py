def _create_child(client):
    resp = client.post("/children", json={"name": "小明", "age": 7})
    return resp.json()["id"]

def test_session_start_returns_first_question(client):
    child_id = _create_child(client)
    resp = client.post("/session/start", json={"child_id": child_id, "activity_type": "detective"})
    assert resp.status_code == 200
    data = resp.json()
    assert "session_id" in data
    assert data["first_question"] is not None
    assert data["difficulty"] == 1

def test_session_start_diary_returns_no_question(client):
    child_id = _create_child(client)
    resp = client.post("/session/start", json={"child_id": child_id, "activity_type": "diary"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["first_question"] is None
    assert data["difficulty"] is None

def test_session_answer_correct(client):
    child_id = _create_child(client)
    start = client.post("/session/start", json={"child_id": child_id, "activity_type": "detective"}).json()
    q = start["first_question"]
    resp = client.post("/session/answer", json={
        "session_id": start["session_id"], "emotion_target": q["emotion_target"],
        "user_response": q["correct_answer"], "response_ms": 2000, "hint_shown": False})
    assert resp.status_code == 200
    assert resp.json()["is_correct"] is True

def test_session_end_calculates_accuracy(client):
    child_id = _create_child(client)
    start = client.post("/session/start", json={"child_id": child_id, "activity_type": "detective"}).json()
    sid = start["session_id"]
    q = start["first_question"]
    client.post("/session/answer", json={
        "session_id": sid, "emotion_target": q["emotion_target"],
        "user_response": q["correct_answer"], "response_ms": 1500, "hint_shown": False})
    resp = client.post("/session/end", json={"session_id": sid})
    assert resp.status_code == 200
    data = resp.json()
    assert data["accuracy"] == 1.0
    assert data["total_questions"] == 1
