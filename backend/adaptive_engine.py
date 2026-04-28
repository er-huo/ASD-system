from config import (
    BKT_LEARNING_RATE, BKT_SLIP_RATE, BKT_GUESS_RATE,
    ANXIETY_CONFIDENCE_THRESHOLD, BOREDOM_STREAK, BOREDOM_RESPONSE_MS,
)

def update_bkt(p_known: float, is_correct: bool, difficulty: int) -> float:
    p_g = BKT_GUESS_RATE.get(difficulty, BKT_GUESS_RATE[2])
    p_s = BKT_SLIP_RATE
    p_t = BKT_LEARNING_RATE
    if is_correct:
        p_l_given_obs = (p_known * (1 - p_s)) / (p_known * (1 - p_s) + (1 - p_known) * p_g)
    else:
        p_l_given_obs = (p_known * p_s) / (p_known * p_s + (1 - p_known) * (1 - p_g))
    p_new = p_l_given_obs + (1 - p_l_given_obs) * p_t
    return max(0.0, min(1.0, p_new))

def decide_adaptive_action(
    fused_emotion: str,
    fused_confidence: float,
    recent_answers: list,
    difficulty: int,
    response_ms: int,
) -> str:
    from config import CONFUSION_CONFIDENCE_THRESHOLD
    if fused_emotion in ("angry", "fear") and fused_confidence > ANXIETY_CONFIDENCE_THRESHOLD:
        return "reduce"
    if fused_emotion == "confused" and fused_confidence > CONFUSION_CONFIDENCE_THRESHOLD.get(difficulty, CONFUSION_CONFIDENCE_THRESHOLD[2]):
        return "hint"
    if len(recent_answers) < 3:
        return "none"
    accuracy = sum(recent_answers) / len(recent_answers)
    if (len(recent_answers) >= BOREDOM_STREAK
            and all(recent_answers[-BOREDOM_STREAK:])
            and fused_emotion == "neutral"
            and response_ms < BOREDOM_RESPONSE_MS):
        return "scene_change"
    if len(recent_answers) >= 5:
        if accuracy > 0.80 and fused_emotion in ("happy", "neutral"):
            return "raise"
        if accuracy < 0.40:
            return "reduce"
    return "none"

def clamp_difficulty(difficulty: int, action: str) -> int:
    delta = {"raise": 1, "reduce": -1}.get(action, 0)
    return max(1, min(3, difficulty + delta))
