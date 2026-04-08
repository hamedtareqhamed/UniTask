export const firebaseConfig = {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || "unitask-mmu.firebaseapp.com",
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || "unitask-mmu",
    storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || "unitask-mmu.firebasestorage.app",
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || "1045468371720",
    appId: import.meta.env.VITE_FIREBASE_APP_ID
};
