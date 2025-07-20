from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import firebase_admin
from firebase_admin import credentials, firestore
import smtplib
from email.mime.text import MIMEText
import random
import string
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv
from pathlib import Path

# ======================
#     Load .env
# ======================
load_dotenv(dotenv_path=Path("assets/.env"))
EMAIL_ADDRESS = os.getenv("GMAIL_USER")       # e.g. voteapp@gmail.com
EMAIL_PASSWORD = os.getenv("GMAIL_PASS")      # Your 16-char app password

# ======================
#     Firebase Setup
# ======================
cred = credentials.Certificate("firebase_config.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# ======================
#     FastAPI Setup
# ======================
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change this to specific domains in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ======================
#     Models
# ======================
class RegisterRequest(BaseModel):
    name: str
    email: str
    phone: str
    password: str

class VerifyRequest(BaseModel):
    phone: str
    otp: str

class LoginRequest(BaseModel):
    email: str
    password: str

class VoteRequest(BaseModel):
    uid: str
    candidate_id: str

# ======================
#     In-Memory Store
# ======================
otp_store = {}  # {phone: otp}
deadline = datetime.now() + timedelta(days=2)

# ======================
#     Email Function
# ======================
def send_otp_email(to_email, otp):
    msg = MIMEText(f"Your OTP for Digital Voting App is: {otp}")
    msg['Subject'] = "Your OTP for Digital Voting"
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = to_email

    try:
        # Debug: print credentials and recipient for troubleshooting
        print(f"Sending OTP to: {to_email}")
        print(f"Using EMAIL_ADDRESS: {EMAIL_ADDRESS}")
        # End debug
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
            server.send_message(msg)
        print("✅ OTP email sent successfully")  # Debug
        return True
    except Exception as e:
        print(f"❌ Email Error: {e}")
        return False

# ======================
#     API Endpoints
# ======================

@app.post("/register")
def register(req: RegisterRequest):
    otp = ''.join(random.choices(string.digits, k=6))
    otp_store[req.phone] = otp

    db.collection("users").document(req.email).set({
        "name": req.name,
        "email": req.email,
        "phone": req.phone,
        "password": req.password,
        "verified": False
    })

    if send_otp_email(req.email, otp):
        return {"message": "✅ OTP sent to your email"}
    else:
        raise HTTPException(status_code=500, detail="❌ Failed to send OTP")

@app.post("/verify")
def verify(req: VerifyRequest):
    if otp_store.get(req.phone) != req.otp:
        raise HTTPException(status_code=400, detail="❌ Invalid OTP")

    users = db.collection("users").where("phone", "==", req.phone).stream()
    found = False
    for user in users:
        user.reference.update({"verified": True})
        found = True

    if not found:
        raise HTTPException(status_code=404, detail="User not found")

    return {"message": "✅ Phone number verified"}

@app.post("/login")
def login(req: LoginRequest):
    user_doc = db.collection("users").document(req.email).get()
    if not user_doc.exists:
        raise HTTPException(status_code=404, detail="❌ User not found")

    user = user_doc.to_dict()
    if user["password"] != req.password:
        raise HTTPException(status_code=401, detail="❌ Incorrect password")
    if not user.get("verified", False):
        raise HTTPException(status_code=403, detail="❌ Phone number not verified")

    return {"message": "✅ Login successful", "uid": req.email}

@app.post("/vote")
def vote(req: VoteRequest):
    user_ref = db.collection("users").document(req.uid)
    if not user_ref.get().exists:
        raise HTTPException(status_code=404, detail="❌ User not found")

    if datetime.now() > deadline:
        raise HTTPException(status_code=403, detail="❌ Voting has ended")

    voted_ref = db.collection("voted").document(req.uid)
    if voted_ref.get().exists:
        raise HTTPException(status_code=403, detail="❌ You have already voted")

    voted_ref.set({"voted": True})
    db.collection("votes").add({
        "uid": req.uid,
        "candidate_id": req.candidate_id,
        "timestamp": datetime.now()
    })
    return {"message": "✅ Vote submitted successfully"}

@app.get("/results")
def results():
    votes = db.collection("votes").stream()
    tally = {}
    for vote in votes:
        cid = vote.to_dict().get("candidate_id")
        if cid:
            tally[cid] = tally.get(cid, 0) + 1
    return {"tally": tally}

@app.get("/time_left")
def time_left():
    delta = deadline - datetime.now()
    return {"seconds": max(int(delta.total_seconds()), 0)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)


