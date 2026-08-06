import os
import uuid
import boto3
from flask import Flask, request, render_template, jsonify

app = Flask(__name__)

BUCKET = os.environ.get("APP_BUCKET")
REGION = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")


def get_clients():
    """All clients must use the same region as the S3 bucket."""
    session = boto3.session.Session(region_name=REGION)
    return (
        session.client("s3"),
        session.client("rekognition"),
        session.client("comprehend"),
    )


@app.errorhandler(Exception)
def handle_exception(e):
    app.logger.error("Unhandled exception: %s", str(e), exc_info=True)
    return jsonify({"error": str(e)}), 500


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/analyze", methods=["POST"])
def analyze():
    if not BUCKET:
        return jsonify({"error": "APP_BUCKET environment variable is not set"}), 500

    file = request.files.get("image")
    if not file:
        return jsonify({"error": "No image uploaded"}), 400

    ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else ""
    content_type = file.content_type or ""
    if ext not in ("jpg", "jpeg", "png") and "image" not in content_type:
        return jsonify({"error": f"Only JPEG and PNG are supported. Got: '{file.filename}' ({content_type})"}), 400
    if ext not in ("jpg", "jpeg", "png"):
        ext = "jpg" if "jpeg" in content_type else "png"

    s3, rekognition, comprehend = get_clients()
    key = f"uploads/{uuid.uuid4()}.{ext}"

    # Upload to S3
    s3.upload_fileobj(file, BUCKET, key, ExtraArgs={"ContentType": file.content_type})

    # Extract text via Rekognition
    rek_response = rekognition.detect_text(
        Image={"S3Object": {"Bucket": BUCKET, "Name": key}}
    )
    lines = [
        d["DetectedText"]
        for d in rek_response["TextDetections"]
        if d["Type"] == "LINE"
    ]
    extracted_text = " ".join(lines).strip()

    if not extracted_text:
        return jsonify({"text": "", "sentiment": "N/A", "scores": {}})

    # Sentiment analysis via Comprehend
    comp_response = comprehend.detect_sentiment(
        Text=extracted_text[:4900], LanguageCode="en"
    )
    sentiment = comp_response["Sentiment"]
    scores = {k: round(v * 100, 1) for k, v in comp_response["SentimentScore"].items()}

    return jsonify({"text": extracted_text, "sentiment": sentiment, "scores": scores})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
