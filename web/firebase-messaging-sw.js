/* Keep the public Firebase web config aligned with lib/firebase_options.dart. */
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCArJbAeY3s5pEgJ977v3T8Pxg_PurehZE',
  appId: '1:544279218915:web:0c3764e2f94742eb71d3d6',
  messagingSenderId: '544279218915',
  projectId: 'basya-investama',
  authDomain: 'basya-investama.firebaseapp.com',
  storageBucket: 'basya-investama.firebasestorage.app',
});

// Notification payloads are displayed by the SDK while in the background.
firebase.messaging();
