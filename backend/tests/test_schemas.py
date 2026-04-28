from schemas import ChildCreate, ChildResponse

def test_child_create_validates_robot_preference():
    c = ChildCreate(name="小明", age=7, robot_preference="tino")
    assert c.robot_preference == "tino"

def test_child_create_rejects_invalid_robot():
    import pytest
    with pytest.raises(Exception):
        ChildCreate(name="小明", age=7, robot_preference="robot3")
