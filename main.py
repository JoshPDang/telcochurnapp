import os
import pickle
import pandas as pd
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from loguru import logger
from typing import List
from io import StringIO

app = FastAPI()

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
async def predict_from_csv(file: UploadFile = File(...)):
    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="File must be a CSV.")

    try:
        contents = await file.read()
        df = pd.read_csv(StringIO(contents.decode()))

        # Ensure required columns are present
        required_cols = {"customerID", "TotalCharges", "Churn"}
        if not required_cols.issubset(df.columns):
            raise HTTPException(status_code=400, detail=f"Missing required columns: {required_cols - set(df.columns)}")

        # Preprocessing
        df['TotalCharges'] = pd.to_numeric(df['TotalCharges'], errors='coerce')
        df['TotalCharges'] = df['TotalCharges'].fillna(df['TotalCharges'].median())

        customer_ids = df['customerID']
        df = df.drop(columns=["customerID", "Churn"])

        X_transformed = preprocessor.transform(df)
        predictions = model.predict(X_transformed)

        result_df = pd.DataFrame({
            "customerID": customer_ids,
            "ChurnPrediction": ["Yes" if p == 1 else "No" for p in predictions]
        })

        return JSONResponse(content=result_df.to_dict(orient="records"))

    except Exception as e:
        logger.error(f"Prediction failed: {e}")
        raise HTTPException(status_code=500, detail="Prediction failed")
