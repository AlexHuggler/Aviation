import { describe, expect, it, vi } from "vitest";
import {
  buildBetaApplicationEmail,
  validateBetaApplication,
} from "./betaApplication";
import worker from "./index";

const validPayload = {
  name: "Alex Student",
  email: "alex@example.com",
  role: "Student pilot",
  training_stage: "Pre-solo",
  total_hours: "24.5",
  ios_device: "iPhone 15",
  current_logbook_method: "Paper logbook",
  next_flight_date: "2026-05-20",
  cfi_status: "I train with a CFI who may review it",
  feedback_call_willingness: "Yes, happy to do a call",
  import_needs: ["Paper", "CSV"],
  feedback_focus: "Currency math and CFI signatures.",
  source_page: "https://www.solo-track.com/#beta",
};

const env = {
  ALLOWED_ORIGIN: "https://www.solo-track.com",
  EMAIL_FROM: "beta@solo-track.com",
  EMAIL_FROM_NAME: "SoloTrack Beta",
  EMAIL_TO: "Contact@solo-track.com",
  EMAIL: {
    send: vi.fn(async () => ({ messageId: "test-message-id" })),
  },
} satisfies Env;

describe("validateBetaApplication", () => {
  it("accepts the expected beta application payload", () => {
    const result = validateBetaApplication(validPayload);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.email).toBe("alex@example.com");
      expect(result.data.import_needs).toEqual(["Paper", "CSV"]);
    }
  });

  it("rejects invalid email addresses", () => {
    const result = validateBetaApplication({ ...validPayload, email: "not-email" });

    expect(result).toEqual({
      ok: false,
      error: "Enter a valid email address.",
      status: 400,
    });
  });

  it("rejects missing required fields", () => {
    const result = validateBetaApplication({ ...validPayload, name: " " });

    expect(result).toEqual({
      ok: false,
      error: "Name is required.",
      status: 400,
    });
  });
});

describe("buildBetaApplicationEmail", () => {
  it("formats a replyable application email", () => {
    const result = validateBetaApplication(validPayload);
    if (!result.ok) throw new Error(result.error);

    const email = buildBetaApplicationEmail(result.data, env);

    expect(email).toMatchObject({
      to: "Contact@solo-track.com",
      from: { email: "beta@solo-track.com", name: "SoloTrack Beta" },
      replyTo: "alex@example.com",
      subject: "SoloTrack Beta Application: Alex Student",
    });
    expect(email.text).toContain("Import needs: Paper, CSV");
    expect(email.text).toContain("Source page: https://www.solo-track.com/#beta");
  });
});

describe("worker fetch", () => {
  it("rejects disallowed origins before reading the body", async () => {
    const response = await worker.fetch(
      new Request("https://forms.solo-track.com/beta-application", {
        method: "POST",
        headers: { Origin: "https://evil.example" },
        body: JSON.stringify(validPayload),
      }),
      env,
    );

    await expect(response.json()).resolves.toEqual({
      ok: false,
      error: "Origin is not allowed.",
    });
    expect(response.status).toBe(403);
    expect(env.EMAIL.send).not.toHaveBeenCalled();
  });

  it("sends a valid beta application email and returns ok", async () => {
    env.EMAIL.send.mockClear();

    const response = await worker.fetch(
      new Request("https://forms.solo-track.com/beta-application", {
        method: "POST",
        headers: {
          Origin: "https://www.solo-track.com",
          "Content-Type": "application/json",
        },
        body: JSON.stringify(validPayload),
      }),
      env,
    );

    await expect(response.json()).resolves.toEqual({ ok: true });
    expect(response.status).toBe(200);
    expect(response.headers.get("Access-Control-Allow-Origin")).toBe(
      "https://www.solo-track.com",
    );
    expect(env.EMAIL.send).toHaveBeenCalledTimes(1);
  });

  it("rejects non-POST requests", async () => {
    const response = await worker.fetch(
      new Request("https://forms.solo-track.com/beta-application", {
        method: "GET",
        headers: { Origin: "https://www.solo-track.com" },
      }),
      env,
    );

    await expect(response.json()).resolves.toEqual({
      ok: false,
      error: "Method not allowed.",
    });
    expect(response.status).toBe(405);
  });

  it("handles email delivery failures without leaking details", async () => {
    const consoleError = vi.spyOn(console, "error").mockImplementation(() => {});
    try {
      const failingEnv = {
        ...env,
        EMAIL: {
          send: vi.fn(async () => {
            throw new Error("provider timeout");
          }),
        },
      } satisfies Env;

      const response = await worker.fetch(
        new Request("https://forms.solo-track.com/beta-application", {
          method: "POST",
          headers: {
            Origin: "https://www.solo-track.com",
            "Content-Type": "application/json",
          },
          body: JSON.stringify(validPayload),
        }),
        failingEnv,
      );

      await expect(response.json()).resolves.toEqual({
        ok: false,
        error: "We could not send your application. Please email Contact@solo-track.com.",
      });
      expect(response.status).toBe(502);
      expect(consoleError).toHaveBeenCalledTimes(1);
    } finally {
      consoleError.mockRestore();
    }
  });

  it("rejects oversized payloads", async () => {
    const response = await worker.fetch(
      new Request("https://forms.solo-track.com/beta-application", {
        method: "POST",
        headers: {
          Origin: "https://www.solo-track.com",
          "Content-Type": "application/json",
          "Content-Length": "12001",
        },
        body: JSON.stringify(validPayload),
      }),
      env,
    );

    await expect(response.json()).resolves.toEqual({
      ok: false,
      error: "Submission is too large.",
    });
    expect(response.status).toBe(413);
  });
});
