def test_create_child(client):
    resp = client.post("/children", json={"name": "小明", "age": 7, "robot_preference": "tino"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["name"] == "小明"
    assert "id" in data
    assert len(data["id"]) == 36

def test_list_children(client):
    client.post("/children", json={"name": "小明", "age": 7})
    client.post("/children", json={"name": "小红", "age": 8})
    resp = client.get("/children")
    assert resp.status_code == 200
    assert len(resp.json()) == 2

def test_create_child_initialises_bkt_states(client, db_session):
    from models import BktState
    resp = client.post("/children", json={"name": "小明", "age": 7})
    child_id = resp.json()["id"]
    count = db_session.query(BktState).filter(BktState.child_id == child_id).count()
    assert count == 7
    states = db_session.query(BktState).filter(BktState.child_id == child_id).all()
    assert all(abs(s.p_known - 0.10) < 1e-6 for s in states)
