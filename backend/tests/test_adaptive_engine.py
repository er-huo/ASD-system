from adaptive_engine import update_bkt, decide_adaptive_action

def test_bkt_correct_answer_increases_p_known():
    p = update_bkt(p_known=0.10, is_correct=True, difficulty=1)
    assert p > 0.10

def test_bkt_wrong_answer_decreases_p_known():
    p = update_bkt(p_known=0.50, is_correct=False, difficulty=2)
    assert p < 0.50

def test_bkt_p_known_stays_in_bounds():
    p_high = update_bkt(p_known=0.99, is_correct=True, difficulty=3)
    p_low = update_bkt(p_known=0.01, is_correct=False, difficulty=1)
    assert 0.0 <= p_high <= 1.0
    assert 0.0 <= p_low <= 1.0

def test_bkt_mastery_after_repeated_correct():
    from config import BKT_MASTERY_THRESHOLD
    p = 0.10
    for _ in range(15):
        p = update_bkt(p, is_correct=True, difficulty=2)
    assert p >= BKT_MASTERY_THRESHOLD

def test_anxiety_triggers_reduce():
    action = decide_adaptive_action(fused_emotion="angry", fused_confidence=0.75,
                                     recent_answers=[], difficulty=2, response_ms=3000)
    assert action == "reduce"

def test_high_accuracy_raises_difficulty():
    answers = [True, True, True, True, True]
    action = decide_adaptive_action(fused_emotion="happy", fused_confidence=0.80,
                                     recent_answers=answers, difficulty=1, response_ms=3000)
    assert action == "raise"

def test_low_accuracy_reduces_difficulty():
    answers = [False, False, False, True, False]
    action = decide_adaptive_action(fused_emotion="neutral", fused_confidence=0.60,
                                     recent_answers=answers, difficulty=2, response_ms=3000)
    assert action == "reduce"

def test_boredom_triggers_scene_change():
    answers = [True, True, True]
    action = decide_adaptive_action(fused_emotion="neutral", fused_confidence=0.70,
                                     recent_answers=answers, difficulty=1, response_ms=500)
    assert action == "scene_change"

def test_normal_state_returns_none():
    answers = [True, False, True, True, False]
    action = decide_adaptive_action(fused_emotion="neutral", fused_confidence=0.50,
                                     recent_answers=answers, difficulty=2, response_ms=3000)
    assert action == "none"

def test_confusion_returns_hint():
    action = decide_adaptive_action(fused_emotion="confused", fused_confidence=0.65,
                                     recent_answers=[True, False], difficulty=2, response_ms=6000)
    assert action == "hint"
