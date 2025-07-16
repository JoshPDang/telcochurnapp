import os
import pickle
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.encoders import jsonable_encoder
from loguru import logger
from pydantic import BaseModel

app = FastAPI()

class TelcoFeatures(BaseModel):
    customerID: str = "1234-ABCD"
    gender: str = "Male"
    SeniorCitizen: int = 0
    Partner: str = "Yes"
    Dependents: str = "Yes"
    tenure: int = 72
    PhoneService: str = "Yes"
    MultipleLines: str = "Yes"
    InternetService: str = "Fiber optic"
    OnlineSecurity: str = "Yes"
    OnlineBackup: str = "Yes"
    DeviceProtection: str = "Yes"
    TechSupport: str = "Yes"
    StreamingTV: str = "Yes"
    StreamingMovies: str = "Yes"
    Contract: str = "Two year"
    PaperlessBilling: str = "No"
    PaymentMethod: str = "Bank transfer (automatic)"
    MonthlyCharges: float = 89.10
    TotalCharges: str = "6400.55"
    Churn: str = "No"

# Load model and preprocessor
model_path = os.path.join(os.path.dirname(__file__), 'model', 'xgb_churn_pipeline.pkl')

try:
    with open(model_path, "rb") as f:
        bundle = pickle.load(f)
        preprocessor = bundle["preprocessor"]
        model = bundle["model"]
    logger.info(f"Model and preprocessor loaded from {model_path}")
except Exception as e:
    logger.error(f"Failed to load model: {e}")
    raise HTTPException(status_code=500, detail="Model loading failed")

@app.get("/")
def check_health():
    return {"status": "ok"}

@app.post("/predict")
def predict(data: TelcoFeatures):
    try:
        # Convert input to DataFrame
        input_dict = jsonable_encoder(data)
        df = pd.DataFrame([input_dict])

        # Fix TotalCharges to float
        df['TotalCharges'] = pd.to_numeric(df['TotalCharges'], errors='coerce')
        df['TotalCharges'] = df['TotalCharges'].fillna(df['TotalCharges'].median())

        # Drop unused columns
        df = df.drop(columns=["customerID", "Churn"])

        # Preprocess
        X_transformed = preprocessor.transform(df)

        # Predict
        prediction = model.predict(X_transformed)[0]
        return {"Churn": "Yes" if prediction == 1 else "No"}

    except Exception as e:
        logger.error(f"Prediction failed: {e}")
        raise HTTPException(status_code=500, detail="Prediction failed")
