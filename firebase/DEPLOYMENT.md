# Firebase Backend Deployment Guide

This guide explains how to deploy the Security Rules, Firestore Composite Indexes, and Cloud Functions for the Nexa AI production backend.

## Prerequisites

1. Install the [Firebase CLI](https://firebase.google.com/docs/cli):
   ```bash
   npm install -g firebase-tools
   ```
2. Authenticate the CLI:
   ```bash
   firebase login
   ```
3. Initialize or link your Firebase project:
   ```bash
   firebase use --add
   ```

---

## 1. Firebase Configuration

Make sure your `firebase.json` at the root of the project maps to the files we have created:
```json
{
  "firestore": {
    "rules": "firebase/firestore.rules",
    "indexes": "firebase/firestore.indexes.json"
  },
  "storage": {
    "rules": "firebase/storage.rules"
  },
  "functions": {
    "source": "firebase/functions"
  }
}
```

---

## 2. Deploying Security Rules & Indexes

### Deploy Firestore Security Rules
```bash
firebase deploy --only firestore:rules
```

### Deploy Firestore Composite Indexes
```bash
firebase deploy --only firestore:indexes
```

### Deploy Storage Security Rules
```bash
firebase deploy --only storage:rules
```

---

## 3. Deploying Cloud Functions

1. Navigate to the functions directory:
   ```bash
   cd firebase/functions
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Deploy functions to production:
   ```bash
   firebase deploy --only functions
   ```

---

## 4. Verification

* **Firestore Rules**: Verify in the Firebase Console under **Firestore Database > Rules** that the rules match `firebase/firestore.rules`.
* **Storage Rules**: Verify in the Firebase Console under **Storage > Rules** that the rules match `firebase/storage.rules`.
* **Functions**: Verify in the Firebase Console under **Functions** that `onUserDeleted`, `aggregateDownloadStats`, and `cleanupOldCompareSessions` are active and listed.
