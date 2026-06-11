const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onUserDeleted } = require("firebase-functions/v2/auth");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

// 1. onUserDeleted: Cleans up Firestore documents and Storage objects recursively when a user deletes their account.
exports.onUserDeleted = onUserDeleted(async (event) => {
  const uid = event.data.uid;
  const db = admin.firestore();
  const bucket = admin.storage().bucket();

  console.log(`User ${uid} deleted. Starting recursive cleanup...`);

  // Delete all Firestore documents under users/{uid} recursively
  const userDocRef = db.collection("users").doc(uid);
  try {
    await db.recursiveDelete(userDocRef);
    console.log(`Firestore documents for user ${uid} recursively deleted.`);
  } catch (error) {
    console.error(`Error deleting firestore documents for user ${uid}:`, error);
  }

  // Delete files in Storage users/{uid}/
  try {
    await bucket.deleteFiles({
      prefix: `users/${uid}/`,
    });
    console.log(`Storage files for user ${uid} deleted.`);
  } catch (error) {
    console.error(`Error deleting storage files for user ${uid}:`, error);
  }

  console.log(`Cleanup completed for user ${uid}.`);
});

// 2. aggregateDownloadStats: Increments model download counters when a task is completed.
exports.aggregateDownloadStats = onDocumentWritten("users/{userId}/downloads/{downloadId}", async (event) => {
  const db = admin.firestore();
  
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  // status 3 represents DownloadStatus.completed
  const wasCompleted = beforeData && beforeData.status === 3;
  const isCompleted = afterData && afterData.status === 3;

  if (!wasCompleted && isCompleted) {
    const modelName = afterData.modelName || "unknown_model";
    const statsRef = db.collection("global_stats").doc("downloads");

    try {
      await db.runTransaction(async (transaction) => {
        const statsDoc = await transaction.get(statsRef);
        const data = statsDoc.exists ? statsDoc.data() : {};
        const modelCount = (data[modelName] || 0) + 1;
        const totalCount = (data.total || 0) + 1;

        transaction.set(statsRef, {
          ...data,
          [modelName]: modelCount,
          total: totalCount,
        }, { merge: true });
      });
      console.log(`Successfully aggregated download stats for model: ${modelName}`);
    } catch (error) {
      console.error("Failed to aggregate download stats:", error);
    }
  }
});

// 3. cleanupOldCompareSessions: Triggers scheduled cleanup on compare sessions older than 30 days.
exports.cleanupOldCompareSessions = onSchedule("0 0 * * *", async (event) => {
  const db = admin.firestore();
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  console.log("Starting scheduled cleanup of compare sessions older than 30 days...");

  try {
    const usersSnapshot = await db.collection("users").get();
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const compareSessionsRef = db.collection("users").doc(userId).collection("compare_sessions");
      
      const oldSessionsSnapshot = await compareSessionsRef
        .where("lastActiveTime", "<", thirtyDaysAgo.toISOString())
        .get();

      for (const sessionDoc of oldSessionsSnapshot.docs) {
        await db.recursiveDelete(sessionDoc.ref);
        console.log(`Deleted old compare session: ${sessionDoc.id} for user: ${userId}`);
      }
    }
    console.log("Scheduled compare sessions cleanup finished successfully.");
  } catch (error) {
    console.error("Scheduled compare sessions cleanup failed:", error);
  }
});
