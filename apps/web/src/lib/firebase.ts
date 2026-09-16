// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";

// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyCktte8btwQq9Bd7yoVAoMdDqYegTco3l4",
  authDomain: "takwa-f86dc.firebaseapp.com",
  projectId: "takwa-f86dc",
  storageBucket: "takwa-f86dc.firebasestorage.app",
  messagingSenderId: "786070309719",
  appId: "1:786070309719:web:2330c8ba11e1abf7394c12",
  measurementId: "G-P0QT3GG9Y7",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

export { app, analytics };
