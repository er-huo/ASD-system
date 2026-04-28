THERAPIST_PASSWORD = "admin1234"
QUESTIONS_PER_SESSION = 10
DB_URL = "sqlite:///./database.db"
TEST_DB_URL = "sqlite:///:memory:"

BKT_LEARNING_RATE = 0.30
BKT_SLIP_RATE = 0.10
BKT_MASTERY_THRESHOLD = 0.95
BKT_GUESS_RATE = {1: 0.50, 2: 0.333, 3: 0.25}

EMOTION_CLASSES = ["happy", "sad", "angry", "fear", "surprise", "neutral", "confused"]

ANXIETY_CONFIDENCE_THRESHOLD = 0.60
CONFUSION_CONFIDENCE_THRESHOLD = {1: 0.50, 2: 0.60, 3: 0.70}
CONFUSION_TIMEOUT_SECONDS = 5
BOREDOM_STREAK = 3
BOREDOM_RESPONSE_MS = 1000

FUSION_WEIGHTS = {
    "face_voice_heart": (0.50, 0.30, 0.20),
    "face_voice":       (0.625, 0.375, 0.0),
    "face_heart":       (0.714, 0.0, 0.286),
    "face_only":        (1.0, 0.0, 0.0),
}

EMOTION_COLORS = {
    "happy":    (40, 100, 55),
    "angry":    (350, 78, 40),
    "sad":      (231, 77, 38),
    "fear":     (283, 62, 42),
    "neutral":  (200, 50, 70),
    "confused": (30, 60, 60),
    "surprise": (55, 90, 55),
}
