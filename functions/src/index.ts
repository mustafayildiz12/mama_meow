import * as functions from "firebase-functions/v2";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";

admin.initializeApp();

// OpenAI anahtarı artık istemcide değil, Cloud Functions secret'ında tutulur.
// Bir kez ayarlamak için: firebase functions:secrets:set OPENAI_API_KEY
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

// Proxy fonksiyonlarının ortak runtime ayarları (wipeUser ile aynı bölge).
const PROXY_OPTS = {
    region: "us-central1",
    memory: "256MiB" as const,
    timeoutSeconds: 120,
    secrets: [OPENAI_API_KEY],
};

// ---- Kötüye kullanım koruması: model allowlist + token tavanı + günlük kota ----

const ALLOWED_CHAT_MODELS = new Set<string>([
    "gpt-4o",
    "gpt-4o-mini",
    "gpt-4o-mini-2024-07-18",
    "gpt-4.1",
    "gpt-4.1-mini",
    "gpt-4.1-nano",
]);
const ALLOWED_TRANSCRIBE_MODELS = new Set<string>([
    "gpt-4o-mini-transcribe",
    "gpt-4o-transcribe",
    "whisper-1",
]);

const DEFAULT_CHAT_MODEL = "gpt-4o-mini";
const DEFAULT_TRANSCRIBE_MODEL = "gpt-4o-mini-transcribe";

// Rapor 650 + askMia 600'ü kapsar; üstünü sunucu kırpar.
const MAX_TOKENS_CAP = 800;

// Kullanıcı başına günlük limitler (premiumdan bağımsız). İhtiyaca göre ayarlanır.
const DAILY_CHAT_LIMIT = 60;
const DAILY_TRANSCRIBE_LIMIT = 40;

/**
 * Bilinmeyen/geçersiz model id'sini güvenli varsayılana düşürür.
 * (örn. appInfo'daki boşluklu 'gpt-4o mini' geçersizdir → DEFAULT_CHAT_MODEL)
 */
function coerceModel(
    requested: unknown,
    allowed: Set<string>,
    fallback: string,
): string {
    return typeof requested === "string" && allowed.has(requested)
        ? requested
        : fallback;
}

/**
 * RTDB transaction ile kullanıcı başına günlük çağrı sayacını arttırır.
 * Limit aşılırsa resource-exhausted fırlatır.
 */
async function enforceQuota(
    uid: string,
    kind: "chat" | "transcribe",
    limit: number,
): Promise<void> {
    const day = new Date().toISOString().slice(0, 10); // yyyy-mm-dd (UTC)
    const ref = admin.database().ref(`usage/${uid}/${day}/${kind}`);
    const res = await ref.transaction((cur) => (cur || 0) + 1);
    const count = (res.snapshot.val() as number | null) ?? 0;
    if (count > limit) {
        throw new functions.https.HttpsError(
            "resource-exhausted",
            "Daily AI limit reached. Please try again tomorrow.",
        );
    }
}

/** OpenAI HTTP durum kodunu HttpsError koduna eşler. */
function mapUpstreamStatus(
    status: number,
): "resource-exhausted" | "unavailable" | "internal" {
    if (status === 429) return "resource-exhausted";
    if (status >= 500) return "unavailable";
    return "internal";
}

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

// ============================================================================
// OpenAI proxy: anahtar sunucuda, auth zorunlu, model allowlist + günlük kota.
// Tüm sohbet çağrıları (askMia, suggestions, 6 rapor servisi) openaiChat'ten,
// ses transkripsiyonu openaiTranscribe'tan geçer.
// ============================================================================

export const openaiChat = functions.https.onCall(PROXY_OPTS, async (request) => {
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Login required");
    }
    const uid = request.auth.uid;
    const d = (request.data ?? {}) as {
        messages?: unknown;
        model?: unknown;
        maxTokens?: unknown;
        temperature?: unknown;
        responseFormat?: unknown;
    };

    if (!Array.isArray(d.messages) || d.messages.length === 0) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "messages required",
        );
    }

    const model = coerceModel(d.model, ALLOWED_CHAT_MODELS, DEFAULT_CHAT_MODEL);
    const maxTokens = Math.min(Number(d.maxTokens) || 600, MAX_TOKENS_CAP);
    const temperature =
        typeof d.temperature === "number" ? d.temperature : 0.7;

    await enforceQuota(uid, "chat", DAILY_CHAT_LIMIT);

    const body: Record<string, unknown> = {
        model,
        messages: d.messages,
        max_tokens: maxTokens,
        temperature,
    };
    if (d.responseFormat) body.response_format = d.responseFormat;

    let resp: Response;
    try {
        resp = await fetch("https://api.openai.com/v1/chat/completions", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${OPENAI_API_KEY.value()}`,
            },
            body: JSON.stringify(body),
        });
    } catch (e) {
        throw new functions.https.HttpsError(
            "unavailable",
            "Upstream request failed",
        );
    }

    if (!resp.ok) {
        throw new functions.https.HttpsError(
            mapUpstreamStatus(resp.status),
            `OpenAI error ${resp.status}`,
        );
    }

    const data = (await resp.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
    };
    const content = data?.choices?.[0]?.message?.content ?? "";
    return { content };
});

export const openaiTranscribe = functions.https.onCall(
    PROXY_OPTS,
    async (request) => {
        if (!request.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "Login required",
            );
        }
        const uid = request.auth.uid;
        const d = (request.data ?? {}) as {
            audioBase64?: unknown;
            filename?: unknown;
            mimeType?: unknown;
            model?: unknown;
            language?: unknown;
            prompt?: unknown;
            temperature?: unknown;
        };

        if (typeof d.audioBase64 !== "string" || d.audioBase64.length === 0) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "audioBase64 required",
            );
        }

        const model = coerceModel(
            d.model,
            ALLOWED_TRANSCRIBE_MODELS,
            DEFAULT_TRANSCRIBE_MODEL,
        );

        await enforceQuota(uid, "transcribe", DAILY_TRANSCRIBE_LIMIT);

        const bytes = Buffer.from(d.audioBase64, "base64");
        const form = new FormData();
        form.append(
            "file",
            new Blob([bytes], {
                type: typeof d.mimeType === "string" ? d.mimeType : "audio/mp4",
            }),
            typeof d.filename === "string" ? d.filename : "audio.m4a",
        );
        form.append("model", model);
        if (typeof d.language === "string" && d.language) {
            form.append("language", d.language);
        }
        if (typeof d.prompt === "string" && d.prompt) {
            form.append("prompt", d.prompt);
        }
        if (typeof d.temperature === "number") {
            form.append("temperature", String(d.temperature));
        }

        let resp: Response;
        try {
            resp = await fetch("https://api.openai.com/v1/audio/transcriptions", {
                method: "POST",
                // Content-Type yok: FormData boundary'i kendi koyar.
                headers: { "Authorization": `Bearer ${OPENAI_API_KEY.value()}` },
                body: form,
            });
        } catch (e) {
            throw new functions.https.HttpsError(
                "unavailable",
                "Upstream request failed",
            );
        }

        if (!resp.ok) {
            throw new functions.https.HttpsError(
                mapUpstreamStatus(resp.status),
                `OpenAI transcribe error ${resp.status}`,
            );
        }

        const data = (await resp.json()) as { text?: string };
        return { text: data?.text ?? "" };
    },
);
