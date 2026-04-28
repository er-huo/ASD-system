from contextlib import asynccontextmanager
from fastapi import FastAPI
from database import engine, Base
import models  # noqa
from routers import children, sessions, reports, emotion

@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield

app = FastAPI(title="StarTalk ASD Backend", lifespan=lifespan)
app.include_router(children.router)
app.include_router(sessions.router)
app.include_router(reports.router)
app.include_router(emotion.router)
