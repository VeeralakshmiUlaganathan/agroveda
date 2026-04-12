from flask import Flask, request, jsonify
from flask_cors import CORS
import random

app = Flask(__name__)
CORS(app)

@app.route("/")
def home():
    return "AgroVeda Backend Running ✅"

@app.route("/predict", methods=["POST"])
def predict():
    try:
        if "image" not in request.files:
            return jsonify({"error": "No image provided"}), 400

        # Simulated prediction (since model not deployed)
        diseases = [
            "Healthy",
            "Leaf Blight",
            "Powdery Mildew",
            "Rust",
            "Early Blight"
        ]

        disease = random.choice(diseases)

        return jsonify({
            "plant": "Plant",
            "disease": disease,
            "confidence": round(random.uniform(85, 99), 2),
            "status": "healthy" if "healthy" in disease.lower() else "disease",
            "recommendation": {
                "chemical": "Use fungicide",
                "dosage": "20ml per liter",
                "frequency": "Weekly"
            }
        })

    except Exception as e:
        return jsonify({
            "error": "Prediction failed",
            "message": str(e)
        }), 500


import os

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 1000))
    app.run(host="0.0.0.0", port=port)