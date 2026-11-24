# Python FastAPI — ML Model + LangGraph

FastAPI server hosting the EfficientNetB4 plant disease classifier and LangGraph AI pipelines.

## Setup

```bash
python -m venv .venv
.venv/Scripts/activate

pip install uvicorn fastapi tensorflow opencv-python pandas h5py \
  python-dotenv langchain langgraph langchain-google-genai \
  google-genai pymongo python-multipart

cp .env.example .env
# Set GEMINI_API_KEY in .env
```

## Run

```bash
TF_ENABLE_ONEDNN_OPTS=0 .venv/Scripts/uvicorn app:app --host 0.0.0.0 --port 8000
```

## Files

| File | Purpose |
|---|---|
| `app.py` | FastAPI app, predict + chat endpoints |
| `chatbot.py` | LangGraph chatbot with MongoDB memory |
| `langgraph_explain.py` | LangGraph disease explanation pipeline |

## Model

- EfficientNetB4, 38 classes, 99.6% validation accuracy
- Weights: `efficientnetb4-Plant Village Disease-weights1.h5`
- Classes: `Plant Village Disease-class_dict.csv`

## Environment

See `.env.example` for all required variables.
