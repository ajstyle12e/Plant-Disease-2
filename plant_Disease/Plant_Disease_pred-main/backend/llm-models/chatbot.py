"""
chatbot.py
──────────
LangGraph chatbot with:
- MongoDB persistent memory (conversation history per session)
- Context awareness of past plant disease predictions
- LangSmith tracing
- Gemini as the LLM
"""

import os
import re
from datetime import datetime, timezone
from typing import TypedDict, List, Optional

from dotenv import load_dotenv
from pymongo import MongoClient
from langgraph.graph import StateGraph, END
from google import genai
from google.genai import types

load_dotenv()

# ── LangSmith tracing ──────────────────────────────────────────────────────────
_ls_key = os.getenv("LANGSMITH_API_KEY", "").strip()
_tracing = os.getenv("LANGCHAIN_TRACING_V2", "false").lower() == "true"

if _ls_key and _tracing:
    os.environ["LANGCHAIN_TRACING_V2"] = "true"
    os.environ["LANGCHAIN_PROJECT"]    = os.getenv("LANGSMITH_PROJECT", "plant-disease-chatbot")
    os.environ["LANGCHAIN_API_KEY"]    = _ls_key
else:
    # Explicitly disable to prevent unauthenticated calls to LangSmith
    os.environ["LANGCHAIN_TRACING_V2"] = "false"

# ── MongoDB ────────────────────────────────────────────────────────────────────
_mongo_client: Optional[MongoClient] = None

def _get_db():
    global _mongo_client
    if _mongo_client is None:
        _mongo_client = MongoClient(
            os.getenv("MONGO_URI", "mongodb://localhost:27017/plant_disease"),
            serverSelectionTimeoutMS=3000,
        )
    return _mongo_client["plant_disease"]


def _load_history(session_id: str, limit: int = 20) -> List[dict]:
    """Load last N messages for a session from MongoDB."""
    try:
        db = _get_db()
        docs = list(
            db["chat_sessions"]
            .find({"session_id": session_id}, {"_id": 0})
            .sort("timestamp", -1)
            .limit(limit)
        )
        return list(reversed(docs))   # oldest first
    except Exception:
        return []


def _save_message(session_id: str, role: str, content: str,
                  disease_context: Optional[str] = None):
    """Persist a single message to MongoDB."""
    try:
        db = _get_db()
        db["chat_sessions"].insert_one({
            "session_id":     session_id,
            "role":           role,
            "content":        content,
            "disease_context": disease_context,
            "timestamp":      datetime.now(timezone.utc),
        })
    except Exception as e:
        print(f"[WARN] Could not save message: {e}")


def _load_prediction_context(session_id: str) -> Optional[str]:
    """Get the most recent disease prediction associated with this session."""
    try:
        db = _get_db()
        # Look in history collection for a prediction tied to this session
        rec = db["history"].find_one(
            {"session_id": session_id},
            sort=[("created_at", -1)]
        )
        if rec:
            return rec.get("predicted_class")
        # Also check chat_sessions for stored disease context
        msg = db["chat_sessions"].find_one(
            {"session_id": session_id, "disease_context": {"$ne": None}},
            sort=[("timestamp", -1)]
        )
        if msg:
            return msg.get("disease_context")
    except Exception:
        pass
    return None


def list_sessions() -> List[dict]:
    """Return all unique chat sessions (for history sidebar)."""
    try:
        db = _get_db()
        pipeline = [
            {"$sort": {"timestamp": -1}},
            {"$group": {
                "_id": "$session_id",
                "last_message": {"$first": "$content"},
                "last_role":    {"$first": "$role"},
                "updated_at":   {"$first": "$timestamp"},
                "disease_context": {"$first": "$disease_context"},
            }},
            {"$sort": {"updated_at": -1}},
            {"$limit": 50},
        ]
        docs = list(db["chat_sessions"].aggregate(pipeline))
        return [
            {
                "session_id":     d["_id"],
                "last_message":   d["last_message"][:80],
                "updated_at":     d["updated_at"].isoformat(),
                "disease_context": d.get("disease_context"),
            }
            for d in docs
        ]
    except Exception as e:
        print(f"[WARN] list_sessions: {e}")
        return []


def get_session_messages(session_id: str) -> List[dict]:
    """Return full message list for one session."""
    return _load_history(session_id, limit=200)


def delete_session(session_id: str):
    """Delete all messages in a session."""
    try:
        _get_db()["chat_sessions"].delete_many({"session_id": session_id})
    except Exception as e:
        print(f"[WARN] delete_session: {e}")


# ── LangGraph state ────────────────────────────────────────────────────────────
class ChatState(TypedDict):
    session_id:      str
    user_message:    str
    disease_context: Optional[str]   # predicted class from last scan
    history:         List[dict]      # [{role, content}, ...]
    system_prompt:   str
    response:        str


# ── Node 1: load history + build system prompt ─────────────────────────────────
def prepare(state: ChatState) -> ChatState:
    sid  = state["session_id"]
    hist = _load_history(sid)

    # Resolve disease context: from request or from DB
    ctx = state.get("disease_context") or _load_prediction_context(sid)

    disease_section = ""
    if ctx:
        clean = ctx.replace("___", " → ").replace("_", " ")
        disease_section = (
            f"\n\nThe user's last scanned plant image was diagnosed as: "
            f"**{clean}**. "
            f"Use this context to give highly relevant answers about this specific disease, "
            f"its treatment, symptoms, and prevention. "
            f"If the user asks about 'the disease', 'this problem', or 'my plant', "
            f"always refer to {clean}."
        )

    system_prompt = (
        "You are an expert plant pathologist, agronomist, and farming advisor. "
        "You help farmers diagnose and treat plant diseases. "
        "Be practical, clear, and empathetic. "
        "Always base your answers on scientific knowledge but explain in simple farmer-friendly terms. "
        "You remember the full conversation history and refer back to earlier messages when relevant."
        + disease_section
    )

    return {**state, "history": hist, "system_prompt": system_prompt,
            "disease_context": ctx}


# ── Node 2: call Gemini with full history ──────────────────────────────────────
def respond(state: ChatState) -> ChatState:
    api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
    if not api_key:
        return {**state, "response": "API key not configured."}

    client = genai.Client(api_key=api_key)

    # Build contents list from history + current message
    contents = []

    # Inject system context as first user turn (Gemini doesn't have system role)
    contents.append(
        types.Content(
            role="user",
            parts=[types.Part(text=state["system_prompt"])],
        )
    )
    contents.append(
        types.Content(
            role="model",
            parts=[types.Part(text="Understood. I'm ready to help with plant disease questions.")],
        )
    )

    # Add conversation history
    for msg in state["history"]:
        role    = "model" if msg["role"] == "assistant" else "user"
        content = msg.get("content", "")
        if content:
            contents.append(
                types.Content(role=role, parts=[types.Part(text=content)])
            )

    # Add current user message
    contents.append(
        types.Content(
            role="user",
            parts=[types.Part(text=state["user_message"])],
        )
    )

    models_to_try = [
        "models/gemini-flash-latest",
        "models/gemini-flash-lite-latest",
        "models/gemini-pro-latest",
    ]

    last_error = ""
    for model_name in models_to_try:
        try:
            response = client.models.generate_content(
                model=model_name,
                contents=contents,
                config=types.GenerateContentConfig(temperature=0.5),
            )
            return {**state, "response": response.text}
        except Exception as e:
            last_error = str(e)
            continue

    return {**state, "response": f"Sorry, I'm having trouble connecting. Please try again. ({last_error})"}


# ── Node 3: save to MongoDB ────────────────────────────────────────────────────
def save(state: ChatState) -> ChatState:
    sid = state["session_id"]
    ctx = state.get("disease_context")
    _save_message(sid, "user",      state["user_message"], ctx)
    _save_message(sid, "assistant", state["response"],     ctx)
    return state


# ── Build graph ────────────────────────────────────────────────────────────────
_graph = None

def _get_graph():
    global _graph
    if _graph is not None:
        return _graph
    g = StateGraph(ChatState)
    g.add_node("prepare", prepare)
    g.add_node("respond", respond)
    g.add_node("save",    save)
    g.set_entry_point("prepare")
    g.add_edge("prepare", "respond")
    g.add_edge("respond", "save")
    g.add_edge("save",    END)
    _graph = g.compile()
    return _graph


def chat(session_id: str, user_message: str,
         disease_context: Optional[str] = None) -> str:
    """Main entry point — returns assistant response string."""
    result = _get_graph().invoke({
        "session_id":      session_id,
        "user_message":    user_message,
        "disease_context": disease_context,
        "history":         [],
        "system_prompt":   "",
        "response":        "",
    })
    return result["response"]
