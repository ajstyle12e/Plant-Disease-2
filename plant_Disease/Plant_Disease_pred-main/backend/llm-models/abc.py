import os
import numpy as np
import cv2
import pandas as pd
import h5py
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout, BatchNormalization
from tensorflow.keras import regularizers
from langgraph_explain import get_explanation

# ── Config ─────────────────────────────────────────────────────────────────────
WEIGHTS_PATH = "efficientnetb4-Plant Village Disease-weights1.h5"
CSV_PATH = "Plant Village Disease-class_dict.csv"

IMG_SIZE     = (224, 224)

CLASS_NAMES  = []
model        = None


def build_model(num_classes):
    """Exact replica of Cell 10 from plant-village-disease.ipynb"""
    base_model = tf.keras.applications.efficientnet.EfficientNetB4(
        include_top=False, weights=None,
        input_shape=(224, 224, 3), pooling='max'
    )
    # unfreeze last 30 layers (matches training notebook)
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


def _load_keras2_weights(mdl, weights_path):
    """
    Load Keras 2 h5 weights into Keras 3 model.

    Keras 2 stores EfficientNet weights by sublayer name:
        efficientnetb4/block1a_bn/beta:0
    Keras 3 flattens all EfficientNet weights into one layer with bare names.

    Strategy:
    - For efficientnetb4: collect all weights from all sublayers in order
    - For head layers: use explicit name mapping (dense_2->dense, etc.)
    """
    # head layer name map: keras2 -> keras3
    head_map = {
        "batch_normalization_1": "batch_normalization",
        "dense_3": "dense",
        "dense_4": "dense_1",
        "dense_5": "dense_2",
    }

    with h5py.File(weights_path, "r") as f:

        # ── 1. Load EfficientNetB4 weights ─────────────────────────────────────
        # Load sublayer-by-sublayer by matching names between Keras3 and h5.
        # 256/257 sublayers match directly — only 'normalization' is Keras3-only.
        eff_base  = mdl.layers[0]   # the EfficientNetB4 base model
        eff_grp   = f["efficientnetb4"]
        loaded_sublayers = 0

        for sublayer in eff_base.layers:
            if not sublayer.weights:
                continue
            sl_name = sublayer.name
            if sl_name not in eff_grp:
                continue   # skip 'normalization' — Keras3-only, not in Keras2 h5
            sub = eff_grp[sl_name]
            weights = []
            ok = True
            for w in sublayer.weights:
                # weight stored as 'kernel:0', 'bias:0', 'gamma:0', etc.
                bare = w.name.split("/")[-1]
                key  = bare + ":0" if not bare.endswith(":0") else bare
                # Keras3 names depthwise conv 'kernel', Keras2 stored it as 'depthwise_kernel:0'
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
                    print(f"  [WARN] {sl_name}: {e}")

        print(f"  EfficientNetB4: loaded {loaded_sublayers}/257 sublayers OK")

        # ── 2. Load head layer weights ─────────────────────────────────────────
        k3_to_k2 = {v: k for k, v in head_map.items()}
        for layer in mdl.layers[1:]:
            if not layer.weights:
                continue
            k2_name = k3_to_k2.get(layer.name, layer.name)
            if k2_name not in f:
                print(f"  [SKIP] {layer.name} -> {k2_name} not in h5")
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

    print("[INFO] All weights loaded.")


def load_model():
    global model, CLASS_NAMES

    if not os.path.exists(CSV_PATH):
        print(f"[ERROR] {CSV_PATH} not found.")
        return False

    df = pd.read_csv(CSV_PATH).sort_values("class_index")
    CLASS_NAMES = df["class"].tolist()
    print(f"[INFO] {len(CLASS_NAMES)} classes loaded.")

    if not os.path.exists(WEIGHTS_PATH):
        print(f"[ERROR] {WEIGHTS_PATH} not found.")
        return False

    print(f"[INFO] Building EfficientNetB4 ({len(CLASS_NAMES)} classes)...")
    model = build_model(len(CLASS_NAMES))
    model(tf.zeros([1, 224, 224, 3]), training=False)   # initialize in inference mode

    print(f"[INFO] Loading weights from {WEIGHTS_PATH} ...")
    _load_keras2_weights(model, WEIGHTS_PATH)
    print(f"[INFO] Model ready.")
    return True


# ── Leaf extraction ────────────────────────────────────────────────────────────
def extract_largest_leaf(img_bgr):
    hsv  = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(hsv,
                       np.array([20, 30, 30], dtype=np.uint8),
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
    return img_bgr[max(y-pad_y,0):min(y+bh+pad_y,h),
                   max(x-pad_x,0):min(x+bw+pad_x,w)]


# ── Preprocessing ──────────────────────────────────────────────────────────────
def preprocess(image_bytes):
    nparr = np.frombuffer(image_bytes, np.uint8)
    img   = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Cannot decode image.")
    img = extract_largest_leaf(img)
    lab     = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    l       = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8)).apply(l)
    img     = cv2.cvtColor(cv2.merge([l, a, b]), cv2.COLOR_LAB2BGR)
    blur    = cv2.GaussianBlur(img, (0, 0), sigmaX=2)
    img     = cv2.addWeighted(img, 1.5, blur, -0.5, 0)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, IMG_SIZE)
    # Model has built-in Rescaling layer — feed raw float [0-255]
    return np.expand_dims(img.astype(np.float32), axis=0)


# ── Predict ────────────────────────────────────────────────────────────────────
def predict_local(image_path):
    if model is None:
        print("[ERROR] Model not loaded.")
        return
    if not os.path.exists(image_path):
        print(f"[ERROR] Image not found: {image_path}")
        return

    print(f"[INFO] Processing: {image_path}")
    with open(image_path, "rb") as f:
        tensor = preprocess(f.read())

    probs      = model(tensor, training=False).numpy()[0]
    pred_idx   = int(np.argmax(probs))
    pred_class = CLASS_NAMES[pred_idx]
    confidence = float(probs[pred_idx])

    top5 = [
        {"class": CLASS_NAMES[i], "confidence": round(float(probs[i]), 4)}
        for i in np.argsort(probs)[::-1][:5]
    ]

    print("\n" + "="*50)
    print("PREDICTION RESULTS")
    print("="*50)
    print(f"Predicted Class : {pred_class}")
    print(f"Confidence      : {round(confidence*100, 2)}%")
    print("\nTop 5:")
    for rank, item in enumerate(top5, 1):
        print(f"  {rank}. {item['class']}: {item['confidence']*100:.2f}%")
    print("="*50)

    print("\nFetching Gemini explanation...\n")
    explanation = get_explanation(pred_class, confidence)
    print("="*50)
    print("DISEASE EXPLANATION")
    print("="*50)
    print(explanation)
    print("="*50)


if __name__ == "__main__":
    if load_model():
        test_image = "test_image.jpg"
        predict_local(test_image)
