// app/frontend/entrypoints/auth.js
import { auth } from "./firebase_config";
import { onAuthStateChanged, signOut } from "firebase/auth";
import * as firebaseui from "firebaseui";
import "firebaseui/dist/firebaseui.css";
import { EmailAuthProvider, GoogleAuthProvider } from "firebase/auth";

const ui = new firebaseui.auth.AuthUI(auth);
const signInBtn = document.getElementById('sign-in-btn');
const signOutBtn = document.getElementById('sign-out-btn');

const uiConfig = {
  signInOptions: [
    GoogleAuthProvider.PROVIDER_ID,
    EmailAuthProvider.PROVIDER_ID
  ],
  signInFlow: 'popup',
  signInSuccessUrl: '/', // Where to go after login
};

onAuthStateChanged(auth, async (user) => {
  if (user) {
    // User is logged in: Hide Sign In, Show Sign Out
    signInBtn?.classList.add('d-none');
    signOutBtn?.classList.remove('d-none');

    const token = await user.getIdToken();
    const response = await fetch('/api/v1/profile', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    // ... update UI with profile data ...
  } else {
    // No user: Show Sign In, Hide Sign Out
    signInBtn?.classList.remove('d-none');
    signOutBtn?.classList.add('d-none');
  }
});

// Trigger login widget when button is clicked
signInBtn?.addEventListener('click', () => {
  ui.start('#firebaseui-auth-container', uiConfig);
});

signOutBtn?.addEventListener('click', () => {
  signOut(auth).then(() => window.location.reload());
});
