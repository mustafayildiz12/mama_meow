import * as functions from "firebase-functions/v2";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";

admin.initializeApp();

// OpenAI anahtarı istemcide değil, Cloud Functions secret'ında tutulur.
// Bir kez ayarlamak için: firebase functions:secrets:set OPENAI_API_KEY
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

// Proxy fonksiyonlarının ortak runtime ayarları (wipeUser ile aynı bölge).
const PROXY_OPTS = {
  region: "us-central1",
  memory: "256MiB" as const,
  timeoutSeconds: 120,
  // Kötüye kullanımda maliyeti sınırlamak için üst sınır.
  maxInstances: 10,
  secrets: [OPENAI_API_KEY],
};

// ---- Kötüye kullanım koruması: model allowlist + boyut/token tavanı + kota ----

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
const ALLOWED_ROLES = new Set<string>(["system", "user", "assistant"]);
const ALLOWED_RESPONSE_FORMATS = new Set<string>(["text", "json_object"]);

const DEFAULT_CHAT_MODEL = "gpt-4o-mini";
const DEFAULT_TRANSCRIBE_MODEL = "gpt-4o-mini-transcribe";

// Rapor 650 + askMia 600'ü kapsar; üstünü sunucu kırpar.
const MAX_TOKENS_CAP = 800;

// İstek boyutu sınırları (callable gövdesi en fazla ~10 MB olabilir).
const MAX_MESSAGES = 20;
const MAX_TEXT_CHARS = 40_000;
const MAX_IMAGES = 1;
const MAX_IMAGE_URL_CHARS = 6_000_000; // ~4.5 MB görsel (base64 data URL)
const MAX_AUDIO_BASE64_CHARS = 9_000_000; // ~6.7 MB ses

// Kullanıcı başına günlük limitler (premiumdan bağımsız). İhtiyaca göre ayarlanır.
const DAILY_CHAT_LIMIT = 60;
const DAILY_TRANSCRIBE_LIMIT = 40;

type QuotaKind = "chat" | "transcribe";

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

/** Bugünün kota sayacı referansı: usage/{uid}/{yyyy-mm-dd UTC}/{kind}. */
function quotaRef(uid: string, kind: QuotaKind) {
  const day = new Date().toISOString().slice(0, 10);
  return admin.database().ref(`usage/${uid}/${day}/${kind}`);
}

/**
 * RTDB transaction ile kullanıcı başına günlük çağrı sayacını arttırır.
 * Limit aşılırsa resource-exhausted fırlatır.
 */
async function enforceQuota(
  uid: string,
  kind: QuotaKind,
  limit: number,
): Promise<void> {
  const res = await quotaRef(uid, kind).transaction((cur) => (cur || 0) + 1);
  const count = (res.snapshot.val() as number | null) ?? 0;
  if (count > limit) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      "Daily AI limit reached. Please try again tomorrow.",
    );
  }
}

/** OpenAI çağrısı başarısız olduysa harcanan kotayı geri verir. */
async function refundQuota(uid: string, kind: QuotaKind): Promise<void> {
  try {
    await quotaRef(uid, kind).transaction((cur) =>
      Math.max(0, (cur || 0) - 1),
    );
  } catch (e) {
    console.warn("refundQuota failed", e);
  }
}

/** OpenAI HTTP durum kodunu HttpsError koduna eşler. */
function mapUpstreamStatus(
  status: number,
): "resource-exhausted" | "unavailable" | "invalid-argument" | "internal" {
  if (status === 429) return "resource-exhausted";
  if (status >= 500) return "unavailable";
  if (status === 400) return "invalid-argument";
  return "internal";
}

/**
 * İstemciden gelen sohbet mesajlarını doğrular: rol izin listesi, mesaj
 * sayısı, toplam metin uzunluğu ve görsel sayısı/boyutu.
 */
function validateMessages(raw: unknown): unknown[] {
  const invalid = (msg: string) =>
    new functions.https.HttpsError("invalid-argument", msg);

  if (!Array.isArray(raw) || raw.length === 0) throw invalid("messages required");
  if (raw.length > MAX_MESSAGES) throw invalid("too many messages");

  let textChars = 0;
  let images = 0;
  for (const m of raw) {
    if (typeof m !== "object" || m === null) throw invalid("invalid message");
    const { role, content } = m as { role?: unknown; content?: unknown };
    if (typeof role !== "string" || !ALLOWED_ROLES.has(role)) {
      throw invalid("invalid role");
    }
    if (typeof content === "string") {
      textChars += content.length;
    } else if (Array.isArray(content)) {
      for (const part of content) {
        const p = part as {
          type?: unknown;
          text?: unknown;
          image_url?: { url?: unknown };
        };
        if (p?.type === "text" && typeof p.text === "string") {
          textChars += p.text.length;
        } else if (p?.type === "image_url") {
          const url = p.image_url?.url;
          if (typeof url !== "string" || url.length > MAX_IMAGE_URL_CHARS) {
            throw invalid("image too large");
          }
          images++;
        } else {
          throw invalid("invalid content part");
        }
      }
    } else {
      throw invalid("invalid content");
    }
  }
  if (textChars > MAX_TEXT_CHARS) throw invalid("input too long");
  if (images > MAX_IMAGES) throw invalid("too many images");
  return raw;
}

// ---- Kullanıcı verisi ----

// Silinecek RTDB yollarını tek noktadan yönet.
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
  [`usage/${uid}`]: null,
});

// Kullanıcıya ait Storage önekleri (bebek fotoğrafı, özel yiyecek görselleri).
const storagePrefixesFor = (uid: string): string[] => [
  `users/${uid}/`,
  `customSolids/${uid}/`,
];

async function wipeUserData(uid: string): Promise<void> {
  await admin.database().ref().update(pathsFor(uid));
  const bucket = admin.storage().bucket();
  await Promise.all(
    storagePrefixesFor(uid).map((prefix) =>
      bucket.deleteFiles({ prefix }).catch((e) => {
        console.warn(`Storage cleanup failed for ${prefix}`, e);
      }),
    ),
  );
}

// Kullanıcının verilerini siler (hesap kalır).
export const wipeUser = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }
  await wipeUserData(request.auth.uid);
  return { ok: true };
});

// Hesabı tamamen siler: önce tüm veri, sonra Auth kullanıcısı. Sunucuda
// yapıldığı için istemcide "requires-recent-login" hatası oluşmaz.
export const deleteAccount = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }
  const uid = request.auth.uid;
  await wipeUserData(uid);
  await admin.auth().deleteUser(uid);
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

  const messages = validateMessages(d.messages);
  const model = coerceModel(d.model, ALLOWED_CHAT_MODELS, DEFAULT_CHAT_MODEL);
  const maxTokens = Math.min(
    Math.max(Number(d.maxTokens) || 600, 1),
    MAX_TOKENS_CAP,
  );
  const temperature =
    typeof d.temperature === "number" && Number.isFinite(d.temperature)
      ? Math.min(Math.max(d.temperature, 0), 1.5)
      : 0.7;
  const formatType = (d.responseFormat as { type?: unknown } | undefined)?.type;

  await enforceQuota(uid, "chat", DAILY_CHAT_LIMIT);

  const body: Record<string, unknown> = {
    model,
    messages,
    max_completion_tokens: maxTokens,
    temperature,
  };
  if (typeof formatType === "string" && ALLOWED_RESPONSE_FORMATS.has(formatType)) {
    body.response_format = { type: formatType };
  }

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
    await refundQuota(uid, "chat");
    throw new functions.https.HttpsError(
      "unavailable",
      "Upstream request failed",
    );
  }

  if (!resp.ok) {
    await refundQuota(uid, "chat");
    console.warn("OpenAI chat error", resp.status, await resp.text());
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
    if (d.audioBase64.length > MAX_AUDIO_BASE64_CHARS) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "audio too large",
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
      form.append("prompt", d.prompt.slice(0, 1000));
    }
    if (typeof d.temperature === "number" && Number.isFinite(d.temperature)) {
      form.append(
        "temperature",
        String(Math.min(Math.max(d.temperature, 0), 1)),
      );
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
      await refundQuota(uid, "transcribe");
      throw new functions.https.HttpsError(
        "unavailable",
        "Upstream request failed",
      );
    }

    if (!resp.ok) {
      await refundQuota(uid, "transcribe");
      console.warn("OpenAI transcribe error", resp.status, await resp.text());
      throw new functions.https.HttpsError(
        mapUpstreamStatus(resp.status),
        `OpenAI transcribe error ${resp.status}`,
      );
    }

    const data = (await resp.json()) as { text?: string };
    return { text: data?.text ?? "" };
  },
);
