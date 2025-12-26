// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyCIXBEG54d59SKoUOdXk9dd3xax9gCHuJs",
  authDomain: "ai-score-predict.firebaseapp.com",
  projectId: "ai-score-predict",
  storageBucket: "ai-score-predict.firebasestorage.app",
  messagingSenderId: "459011711152",
  appId: "1:459011711152:web:e23b84dd88d9c201abdb75"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// CRITICAL: Ensure 'export' is here!
export const auth = getAuth(app);