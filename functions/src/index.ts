import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

admin.initializeApp();

// Silinecek yolları tek noktadan yönet
const pathsFor = (uid: string): Record<string, null> => ({
    [`users/${uid}`]: null,
    [`solids/${uid}`]: null,
    [`sleeps/${uid}`]: null,
    [`questionAi/${uid}`]: null,
    [`pumpings/${uid}`]: null,
    [`nursing/${uid}`]: null,
    [`medicine/${uid}`]: null,
    [`journal/${uid}`]: null,
    [`diapers/${uid}`]: null,
    [`customSolids/${uid}`]: null,
});

// 2) İsteğe bağlı: Kullanıcı kendini silmeden önce verisini temizlemek isterse
export const wipeUser = functions.https.onCall(async (request) => {
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Login required");
    }

    const uid = request.auth.uid;
    await admin.database().ref().update(pathsFor(uid));

    return { ok: true };
});