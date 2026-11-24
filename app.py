import streamlit as st
import tensorflow as tf
import numpy as np
import pandas as pd

from PIL import Image


# ---------------------------------------
# PAGE CONFIGURATION
# ---------------------------------------

st.set_page_config(
    page_title="Plant Disease Detection",
    page_icon="🌿",
    layout="wide"
)


# ---------------------------------------
# LOAD MODEL
# ---------------------------------------

@st.cache_resource
def load_model():

    model = tf.keras.models.load_model(
        "plant_disease_model.keras",
        compile=False
    )

    return model


# ---------------------------------------
# LOAD CLASS NAMES
# ---------------------------------------

@st.cache_data
def load_classes():

    df = pd.read_csv("class_indices.csv")

    df = df.sort_values("class_index")

    classes = df["class_name"].tolist()

    return classes


model = load_model()
class_names = load_classes()


# ---------------------------------------
# IMAGE PREPROCESSING
# ---------------------------------------

def preprocess_image(image):

    # Convert image into RGB
    image = image.convert("RGB")

    # Resize image
    image = image.resize((224, 224))

    # Convert image into numpy array
    image_array = np.array(image)

    # Convert into float32
    image_array = image_array.astype(np.float32)

    # Add batch dimension
    image_array = np.expand_dims(image_array, axis=0)

    return image_array


# ---------------------------------------
# PREDICTION FUNCTION
# ---------------------------------------

def predict_disease(image):

    processed_image = preprocess_image(image)

    predictions = model.predict(
        processed_image,
        verbose=0
    )

    predicted_index = np.argmax(predictions[0])

    confidence = float(
        predictions[0][predicted_index]
    ) * 100

    predicted_class = class_names[predicted_index]

    return predicted_class, confidence


# ---------------------------------------
# STREAMLIT USER INTERFACE
# ---------------------------------------

st.title("🌿 Plant Disease Detection System")

st.markdown(
    """
    ### AI-Based Plant Disease Prediction

    Upload an image of a plant leaf to identify
    possible diseases using Deep Learning.
    """
)

st.divider()


# Image uploader

uploaded_file = st.file_uploader(
    "Upload a Plant Leaf Image",
    type=["jpg", "jpeg", "png"]
)


if uploaded_file is not None:

    image = Image.open(uploaded_file)

    col1, col2 = st.columns(2)

    with col1:

        st.subheader("Uploaded Image")

        st.image(
            image,
            caption="Uploaded Leaf Image",
            use_container_width=True
        )


    with col2:

        st.subheader("Prediction Result")

        if st.button("Predict Disease"):

            with st.spinner("Analyzing leaf image..."):

                try:

                    disease, confidence = predict_disease(image)

                    st.success("Prediction Completed!")

                    st.markdown(
                        f"### 🌱 {disease.replace('___', ' - ').replace('_', ' ')}"
                    )

                    st.metric(
                        "Prediction Confidence",
                        f"{confidence:.2f}%"
                    )

                    st.progress(
                        min(int(confidence), 100)
                    )

                except Exception as e:

                    st.error(
                        f"Prediction failed: {str(e)}"
                    )


st.divider()

st.caption(
    "Powered by TensorFlow, EfficientNetB3 and Streamlit."
)
