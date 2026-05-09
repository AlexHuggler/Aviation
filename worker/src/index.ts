import {
  buildBetaApplicationEmail,
  validateBetaApplication,
} from "./betaApplication";

const BETA_PATH = "/beta-application";
const MAX_BODY_BYTES = 12_000;

export default {
  async fetch(request, env): Promise<Response> {
    const origin = request.headers.get("Origin") || "";
    const corsHeaders = buildCorsHeaders(origin, env);

    if (origin !== env.ALLOWED_ORIGIN) {
      return jsonResponse(
        { ok: false, error: "Origin is not allowed." },
        403,
        { Vary: "Origin" },
      );
    }

    const url = new URL(request.url);
    if (url.pathname !== BETA_PATH) {
      return jsonResponse(
        { ok: false, error: "Not found." },
        404,
        corsHeaders,
      );
    }

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (request.method !== "POST") {
      return jsonResponse(
        { ok: false, error: "Method not allowed." },
        405,
        { ...corsHeaders, Allow: "POST, OPTIONS" },
      );
    }

    const length = Number(request.headers.get("Content-Length") || "0");
    if (Number.isFinite(length) && length > MAX_BODY_BYTES) {
      return jsonResponse(
        { ok: false, error: "Submission is too large." },
        413,
        corsHeaders,
      );
    }

    let payload: unknown;
    try {
      const body = await request.text();
      if (body.length > MAX_BODY_BYTES) {
        return jsonResponse(
          { ok: false, error: "Submission is too large." },
          413,
          corsHeaders,
        );
      }
      payload = JSON.parse(body);
    } catch {
      return jsonResponse(
        { ok: false, error: "Submit the form as valid JSON." },
        400,
        corsHeaders,
      );
    }

    const validation = validateBetaApplication(payload);
    if (!validation.ok) {
      return jsonResponse(
        { ok: false, error: validation.error },
        validation.status,
        corsHeaders,
      );
    }

    try {
      await env.EMAIL.send(buildBetaApplicationEmail(validation.data, env));
      return jsonResponse({ ok: true }, 200, corsHeaders);
    } catch (error) {
      console.error(
        JSON.stringify({
          event: "beta_application_email_failed",
          message: error instanceof Error ? error.message : String(error),
        }),
      );
      return jsonResponse(
        { ok: false, error: "We could not send your application. Please email Contact@solo-track.com." },
        502,
        corsHeaders,
      );
    }
  },
} satisfies ExportedHandler<Env>;

function buildCorsHeaders(origin: string, env: Env): Record<string, string> {
  const headers: Record<string, string> = {
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Content-Type": "application/json; charset=utf-8",
    Vary: "Origin",
  };

  if (origin === env.ALLOWED_ORIGIN) {
    headers["Access-Control-Allow-Origin"] = env.ALLOWED_ORIGIN;
  }

  return headers;
}

function jsonResponse(
  body: { ok: boolean; error?: string },
  status: number,
  headers: Record<string, string>,
): Response {
  return new Response(JSON.stringify(body), { status, headers });
}
