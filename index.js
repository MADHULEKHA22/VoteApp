/**
 * Node.js Express backend for voting app
 * Fully modified for Firebase Cloud Functions
 */

const functions = require("firebase-functions");
const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const dotenv = require("dotenv");
const bodyParser = require("body-parser");
const path = require("path");

dotenv.config();

const app = express();
app.use(cors());
app.use(bodyParser.json());

// ======================
//     Firebase Setup
// ======================
const serviceAccount = require(path.join(__dirname, "firebase_config.json"));
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// ======================
//     Email Setup
// ======================
const EMAIL_ADDRESS = process.env.GMAIL_USER;
const EMAIL_PASSWORD = process.env.GMAIL_PASS;

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: EMAIL_ADDRESS,
    pass: EMAIL_PASSWORD,
  },
});

// ======================
//     In-Memory Store
// ======================
const otpStore = {}; // {phone: otp}
const deadline = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000); // 2 days from now

// ======================
//     Routes
// ======================

// Register
app.post("/api/register", async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    otpStore[phone] = otp;

    await db.collection("users").doc(email).set({
      name,
      email,
      phone,
      password,
      verified: false,
    });

    const mailOptions = {
      from: EMAIL_ADDRESS,
      to: email,
      subject: "Your OTP for Digital Voting",
      text: `Your OTP for Digital Voting App is: ${otp}`,
    };

    transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        console.error(error);
        return res.status(500).json({ detail: "❌ Failed to send OTP" });
      }
      res.json({ message: "✅ OTP sent to your email" });
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ detail: "❌ Internal server error" });
  }
});

// Verify
app.post("/api/verify", async (req, res) => {
  try {
    const { phone, otp } = req.body;
    if (otpStore[phone] !== otp) {
      return res.status(400).json({ detail: "❌ Invalid OTP" });
    }

    const users = await db
      .collection("users")
      .where("phone", "==", phone)
      .get();

    if (users.empty) {
      return res.status(404).json({ detail: "User not found" });
    }

    users.forEach((doc) => doc.ref.update({ verified: true }));
    res.json({ message: "✅ Phone number verified" });
  } catch (e) {
    console.error(e);
    res.status(500).json({ detail: "❌ Internal server error" });
  }
});

// Login
app.post("/api/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const userDoc = await db.collection("users").doc(email).get();

    if (!userDoc.exists) {
      return res.status(404).json({ detail: "❌ User not found" });
    }

    const user = userDoc.data();
    if (user.password !== password) {
      return res.status(401).json({ detail: "❌ Incorrect password" });
    }
    if (!user.verified) {
      return res.status(403).json({ detail: "❌ Phone number not verified" });
    }

    res.json({ message: "✅ Login successful", uid: email });
  } catch (e) {
    console.error(e);
    res.status(500).json({ detail: "❌ Internal server error" });
  }
});

// Vote
app.post("/api/vote", async (req, res) => {
  try {
    const { uid, candidate_id } = req.body;
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return res.status(404).json({ detail: "❌ User not found" });
    }

    if (new Date() > deadline) {
      return res.status(403).json({ detail: "❌ Voting has ended" });
    }

    const votedRef = db.collection("voted").doc(uid);
    if ((await votedRef.get()).exists) {
      return res.status(403).json({ detail: "❌ You have already voted" });
    }

    await votedRef.set({ voted: true });
    await db.collection("votes").add({
      uid,
      candidate_id,
      timestamp: new Date(),
    });

    res.json({ message: "✅ Vote submitted successfully" });
  } catch (e) {
    console.error(e);
    res.status(500).json({ detail: "❌ Internal server error" });
  }
});

// Results
app.get("/api/results", async (req, res) => {
  try {
    const votes = await db.collection("votes").get();
    const tally = {};
    votes.forEach((doc) => {
      const cid = doc.data().candidate_id;
      if (cid) tally[cid] = (tally[cid] || 0) + 1;
    });
    res.json({ tally });
  } catch (e) {
    console.error(e);
    res.status(500).json({ detail: "❌ Internal server error" });
  }
});

// Time Left
app.get("/api/time_left", (req, res) => {
  try {
    const delta = Math.max(
      Math.floor((deadline - new Date()) / 1000),
      0
    );
    res.json({ seconds: delta });
  } catch (e) {
    console.error(e);
    res.status(500).json({ detail: "❌ Internal server error" });
  }
});

// ======================
//     Export as Function
// ======================
exports.api = functions.https.onRequest(app);
