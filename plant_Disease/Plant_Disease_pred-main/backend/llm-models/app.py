import os

# Must be set before TensorFlow is imported
os.environ.setdefault("TF_ENABLE_ONEDNN_OPTS", "0")
os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")

from dotenv import load_dotenv
load_dotenv()  # load .env before anything else

import numpy as np
import cv2
import pandas as pd
import h5py
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout, BatchNormalization
from tensorflow.keras import regularizers
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from contextlib import asynccontextmanager
from langgraph_explain import get_explanation
from chatbot import chat, list_sessions, get_session_messages, delete_session

# ── Config (all from .env) ─────────────────────────────────────────────────────
WEIGHTS_PATH = os.getenv("WEIGHTS_PATH", "efficientnetb4-Plant Village Disease-weights1.h5")
CSV_PATH     = os.getenv("CSV_PATH",     "Plant Village Disease-class_dict.csv")
IMG_SIZE     = (224, 224)

CLASS_NAMES: list = []
model        = None


def build_model(num_classes: int):
    base_model = tf.keras.applications.efficientnet.EfficientNetB4(
        include_top=False, weights=None,
        input_shape=(224, 224, 3), pooling='max'
    )
    for layer in base_model.layers[:-30]:
        layer.trainable = False
    for layer in base_model.layers[-30:]:
        layer.trainable = True
    return Sequential([
        base_model,
        BatchNormalization(axis=-1, momentum=0.99, epsilon=0.001),
        Dense(512, kernel_regularizer=regularizers.l2(0.016),
              activity_regularizer=regularizers.l1(0.006),
              bias_regularizer=regularizers.l1(0.006), activation='relu'),
        Dropout(rate=0.5, seed=123),
        Dense(256, kernel_regularizer=regularizers.l2(0.016), activation='relu'),
        Dropout(rate=0.3, seed=123),
        Dense(num_classes, activation='softmax'),
    ])


def _load_keras2_weights(mdl, weights_path: str):
    head_map = {
        "batch_normalization_1": "batch_normalization",
        "dense_3": "dense",
        "dense_4": "dense_1",
        "dense_5": "dense_2",
    }
    with h5py.File(weights_path, "r") as f:
        # ── EfficientNetB4 base ────────────────────────────────────────────────
        eff_base = mdl.layers[0]
        eff_grp  = f["efficientnetb4"]
        loaded_sublayers = 0
        for sublayer in eff_base.layers:
            if not sublayer.weights or sublayer.name not in eff_grp:
                continue
            sub = eff_grp[sublayer.name]
            weights, ok = [], True
            for w in sublayer.weights:
                bare = w.name.split("/")[-1]
                key  = bare + ":0" if not bare.endswith(":0") else bare
                if key == "kernel:0" and "depthwise_kernel:0" in sub:
                    key = "depthwise_kernel:0"
                if key in sub:
                    weights.append(np.array(sub[key]))
                elif bare in sub:
                    weights.append(np.array(sub[bare]))
                else:
                    ok = False
                    break
            if ok and len(weights) == len(sublayer.weights):
                try:
                    sublayer.set_weights(weights)
                    loaded_sublayers += 1
                except Exception as e:
                    print(f"  [WARN] {sublayer.name}: {e}")
        print(f"  EfficientNetB4: {loaded_sublayers}/257 sublayers loaded")

        # ── Head layers ────────────────────────────────────────────────────────
        k3_to_k2 = {v: k for k, v in head_map.items()}
        for layer in mdl.layers[1:]:
            if not layer.weights:
                continue
            k2_name = k3_to_k2.get(layer.name, layer.name)
            if k2_name not in f:
                continue
            grp = f[k2_name]
            if k2_name in grp:
                grp = grp[k2_name]
            weights = []
            for w in layer.weights:
                bare = w.name.split("/")[-1]
                key  = bare + ":0" if not bare.endswith(":0") else bare
                if key in grp:
                    weights.append(np.array(grp[key]))
                elif bare in grp:
                    weights.append(np.array(grp[bare]))
                else:
                    weights = None
                    break
            if weights and len(weights) == len(layer.weights):
                layer.set_weights(weights)
                print(f"  {layer.name} weights loaded OK")
            else:
                print(f"  [WARN] Could not load {layer.name}")
    print("[INFO] Weights loaded.")


def load_model():
    global model, CLASS_NAMES

    if not os.path.exists(CSV_PATH):
        print(f"[ERROR] {CSV_PATH} not found.")
        return

    df = pd.read_csv(CSV_PATH).sort_values("class_index")
    CLASS_NAMES = df["class"].tolist()
    print(f"[INFO] {len(CLASS_NAMES)} classes loaded.")

    if not os.path.exists(WEIGHTS_PATH):
        print(f"[ERROR] {WEIGHTS_PATH} not found.")
        return

    print(f"[INFO] Building EfficientNetB4 ({len(CLASS_NAMES)} classes)...")
    model = build_model(len(CLASS_NAMES))
    model(tf.zeros([1, 224, 224, 3]), training=False)   # initialize in inference mode
    print("[INFO] Loading weights...")
    _load_keras2_weights(model, WEIGHTS_PATH)
    print(f"[INFO] Model ready | classes: {len(CLASS_NAMES)}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    load_model()
    yield


app = FastAPI(title="Plant Disease Classifier", version="2.1.0", lifespan=lifespan)

# Allow all origins — tighten in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def extract_largest_leaf(img_bgr: np.ndarray) -> np.ndarray:
    hsv  = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(hsv,
                       np.array([20, 30, 30],  dtype=np.uint8),
                       np.array([95, 255, 255], dtype=np.uint8))
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15))
    mask   = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
    mask   = cv2.morphologyEx(mask, cv2.MORPH_OPEN,  kernel)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return img_bgr
    largest = max(contours, key=cv2.contourArea)
    h, w = img_bgr.shape[:2]
    if cv2.contourArea(largest) < 0.02 * h * w:
        return img_bgr
    x, y, bw, bh = cv2.boundingRect(largest)
    pad_x = max(int(bw * 0.05), 5)
    pad_y = max(int(bh * 0.05), 5)
    return img_bgr[max(y-pad_y, 0):min(y+bh+pad_y, h),
                   max(x-pad_x, 0):min(x+bw+pad_x, w)]


def preprocess(image_bytes: bytes) -> np.ndarray:
    nparr = np.frombuffer(image_bytes, np.uint8)
    img   = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Cannot decode image. Send a valid JPG or PNG.")

    img = extract_largest_leaf(img)

    # CLAHE contrast enhancement on L channel
    lab     = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    l       = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8)).apply(l)
    img     = cv2.cvtColor(cv2.merge([l, a, b]), cv2.COLOR_LAB2BGR)

    # Unsharp mask
    blur = cv2.GaussianBlur(img, (0, 0), sigmaX=2)
    img  = cv2.addWeighted(img, 1.5, blur, -0.5, 0)

    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, IMG_SIZE)
    # Model has built-in Rescaling layer — feed raw float [0-255]
    return np.expand_dims(img.astype(np.float32), axis=0)


@app.get("/")
def root():
    return {
        "status":       "running",
        "model_loaded": model is not None,
        "classes":      len(CLASS_NAMES),
    }


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    if model is None:
        raise HTTPException(503, "Model not loaded.")

    # Accept jpeg/png regardless of how the client labels content-type
    allowed = {"image/jpeg", "image/jpg", "image/png", "application/octet-stream"}
    if file.content_type and file.content_type not in allowed:
        raise HTTPException(400, f"Unsupported content type '{file.content_type}'.")

    try:
        tensor = preprocess(await file.read())
    except ValueError as e:
        raise HTTPException(422, str(e))

    # BUG FIX: call with training=False so Dropout layers are disabled at inference
    probs     = model(tensor, training=False).numpy()[0]
    pred_idx  = int(np.argmax(probs))
    pred_class = CLASS_NAMES[pred_idx]
    confidence = float(probs[pred_idx])

    top5 = [
        {"class": CLASS_NAMES[i], "confidence": round(float(probs[i]), 4)}
        for i in np.argsort(probs)[::-1][:5]
    ]

    return JSONResponse({
        "predicted_class":   pred_class,
        "confidence":        round(confidence, 4),
        "top_5_predictions": top5,
        "explanation":       get_explanation(pred_class, confidence),
    })


@app.get("/classes")
def get_classes():
    return {"total": len(CLASS_NAMES), "classes": CLASS_NAMES}


# ── Chat endpoints ─────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    session_id:      str
    message:         str
    disease_context: str = ""


@app.post("/chat")
async def chat_endpoint(req: ChatRequest):
    try:
        response = chat(
            session_id      = req.session_id,
            user_message    = req.message,
            disease_context = req.disease_context or None,
        )
        return JSONResponse({"response": response, "session_id": req.session_id})
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/chat/sessions")
def chat_sessions():
    return JSONResponse(list_sessions())


@app.get("/chat/sessions/{session_id}")
def chat_session_messages(session_id: str):
    msgs = get_session_messages(session_id)
    # Convert datetime to string
    result = []
    for m in msgs:
        result.append({
            "role":            m.get("role"),
            "content":         m.get("content"),
            "disease_context": m.get("disease_context"),
            "timestamp":       m.get("timestamp").isoformat() if m.get("timestamp") else "",
        })
    return JSONResponse(result)


@app.delete("/chat/sessions/{session_id}")
def delete_chat_session(session_id: str):
    delete_session(session_id)
    return JSONResponse({"deleted": True})
