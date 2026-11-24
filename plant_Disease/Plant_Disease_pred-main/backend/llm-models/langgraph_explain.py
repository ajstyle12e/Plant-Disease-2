"""
langgraph_explain.py
────────────────────
LangGraph pipeline:  build_prompt → call_gemini → return_result

Uses google-genai SDK (new) directly — compatible with gemini-3.x models.
Input : disease_name (str), confidence (float 0-1)
Output: detailed explanation string from Gemini
"""

import os
from typing import TypedDict
from dotenv import load_dotenv
from langgraph.graph import StateGraph, END
from google import genai
from google.genai import types

load_dotenv()


# ── Shared state ───────────────────────────────────────────────────────────────
class ExplainState(TypedDict):
    disease_name: str
    confidence:   float
    prompt:       str
    explanation:  str


# ── Node 1: build prompt ───────────────────────────────────────────────────────
def build_prompt(state: ExplainState) -> ExplainState:
    name = state["disease_name"].replace("___", " - ").replace("_", " ")

    prompt = (
        f"You are an expert plant pathologist and agronomist.\n\n"
        f"A plant disease has been detected: {name}\n\n"
        f"Write a detailed, practical explanation covering ALL of these sections:\n\n"
        f"1. Disease Overview - what it is, scientific name of the pathogen\n"
        f"2. Visual Symptoms - what the farmer will see on leaves, stems, fruit\n"
        f"3. Spread & Conditions - how it spreads, temperature/humidity it thrives in\n"
        f"4. Crop Impact - yield loss if left untreated\n"
        f"5. Treatment - recommended fungicides/bactericides with dosage\n"
        f"6. Organic/Natural Remedies - eco-friendly alternatives\n"
        f"7. Prevention Tips - cultural practices to avoid recurrence\n"
        f"8. When to Seek Expert Help - signs that the situation is serious\n\n"
        f"Do NOT include any disclaimers about AI confidence or accuracy scores. "
        f"Be specific, clear, and helpful for a farmer with no scientific background."
    )
    return {**state, "prompt": prompt}


# ── Node 2: call Gemini ────────────────────────────────────────────────────────
def call_gemini(state: ExplainState) -> ExplainState:
    api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
    if not api_key:
        return {**state,
                "explanation": "Gemini API key not found. Add GEMINI_API_KEY to your .env file."}

    client = genai.Client(api_key=api_key)

    # Try models in order until one succeeds
    models_to_try = [
        "models/gemini-flash-lite-latest",
        "models/gemini-flash-latest",
        "models/gemini-pro-latest",
    ]

    last_error = ""
    for model_name in models_to_try:
        try:
            response = client.models.generate_content(
                model=model_name,
                contents=state["prompt"],
                config=types.GenerateContentConfig(temperature=0.4),
            )
            return {**state, "explanation": response.text}
        except Exception as e:
            last_error = str(e)
            # 503 = server busy, try next model
            # 404 = model not found, try next model
            continue

    return {**state, "explanation": f"Gemini call failed after trying all models: {last_error}"}


# ── Node 3: strip disclaimer lines ────────────────────────────────────────────
import re

_DISCLAIMER_PATTERNS = [
    r"confidence",
    r"accuracy",
    r"disclaimer",
    r"ai model",
    r"low confidence",
    r"not certain",
    r"should be verified",
    r"\d+\.?\d*\s*%",          # any percentage like 19.2% or 85%
    r"note:",
    r"\*note",
    r"\*\*note",
    r"\*disclaimer",
    r"\*\*disclaimer",
    r"the model",
    r"detected with",
    r"predicted class",
    r"detection result",
    r"this diagnosis",
    r"while the ai",
    r"while the model",
    r"based on the (ai|model|detection)",
]

_COMPILED = [re.compile(p, re.IGNORECASE) for p in _DISCLAIMER_PATTERNS]


def _is_disclaimer_line(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return False
    return any(p.search(stripped) for p in _COMPILED)


def return_result(state: ExplainState) -> ExplainState:
    text = state["explanation"]
    lines = text.splitlines()
    clean = [line for line in lines if not _is_disclaimer_line(line)]
    explanation = "\n".join(clean).strip()
    # Remove any leading/trailing blank lines
    explanation = re.sub(r"^\n+", "", explanation)
    explanation = re.sub(r"\n{3,}", "\n\n", explanation)
    return {**state, "explanation": explanation}


# ── Singleton graph ────────────────────────────────────────────────────────────
_graph = None

def _get_graph():
    global _graph
    if _graph is None:
        g = StateGraph(ExplainState)
        g.add_node("build_prompt",  build_prompt)
        g.add_node("call_gemini",   call_gemini)
        g.add_node("return_result", return_result)
        g.set_entry_point("build_prompt")
        g.add_edge("build_prompt",  "call_gemini")
        g.add_edge("call_gemini",   "return_result")
        g.add_edge("return_result", END)
        _graph = g.compile()
    return _graph


def get_explanation(disease_name: str, confidence: float = 0.0) -> str:
    """
    Main entry point used by abc.py and app.py.
    Returns a Gemini-generated detailed explanation string.
    """
    result = _get_graph().invoke({
        "disease_name": disease_name,
        "confidence":   0.0,
        "prompt":       "",
        "explanation":  "",
    })
    return result["explanation"]


# ── Standalone test ────────────────────────────────────────────────────────────
if __name__ == "__main__":
    out = get_explanation("Tomato___Early_blight", 0.9731)
    with open("test_out.txt", "w", encoding="utf-8") as f:
        f.write(out)
    print("Done. Output written to test_out.txt")
    print(out[:300])
