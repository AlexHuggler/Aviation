const requiredFields = [
  ["name", "Name"],
  ["email", "Email"],
  ["role", "Role"],
  ["training_stage", "Training stage"],
  ["total_hours", "Total flight hours"],
  ["ios_device", "iOS device"],
  ["current_logbook_method", "Current logbook method"],
  ["next_flight_date", "Next expected flight"],
  ["cfi_status", "CFI status"],
  ["feedback_call_willingness", "15-minute feedback call"],
] as const;

const fieldLabels = {
  name: "Name",
  email: "Email",
  role: "Role",
  training_stage: "Training stage",
  total_hours: "Total flight hours",
  ios_device: "iOS device",
  current_logbook_method: "Current logbook method",
  next_flight_date: "Next expected flight",
  cfi_status: "CFI status",
  feedback_call_willingness: "15-minute feedback call",
  import_needs: "Import needs",
  feedback_focus: "What should SoloTrack get right",
  source_page: "Source page",
} as const;

export type BetaApplication = {
  name: string;
  email: string;
  role: string;
  training_stage: string;
  total_hours: string;
  ios_device: string;
  current_logbook_method: string;
  next_flight_date: string;
  cfi_status: string;
  feedback_call_willingness: string;
  import_needs: string[];
  feedback_focus: string;
  source_page: string;
};

export type ValidationResult =
  | { ok: true; data: BetaApplication }
  | { ok: false; error: string; status: number };

type EmailPayload = Parameters<Env["EMAIL"]["send"]>[0];

export function validateBetaApplication(payload: unknown): ValidationResult {
  if (!isRecord(payload)) {
    return { ok: false, error: "Submit the form as valid JSON.", status: 400 };
  }

  const data: Partial<BetaApplication> = {};

  for (const [key, label] of requiredFields) {
    const value = readString(payload[key]);
    if (!value) {
      return { ok: false, error: `${label} is required.`, status: 400 };
    }
    data[key] = value;
  }

  if (!isValidEmail(data.email ?? "")) {
    return { ok: false, error: "Enter a valid email address.", status: 400 };
  }

  const totalHours = Number(data.total_hours);
  if (!Number.isFinite(totalHours) || totalHours < 0) {
    return {
      ok: false,
      error: "Total flight hours must be zero or greater.",
      status: 400,
    };
  }

  data.import_needs = readStringArray(payload.import_needs);
  data.feedback_focus = readString(payload.feedback_focus);
  data.source_page = readString(payload.source_page);

  return { ok: true, data: data as BetaApplication };
}

export function buildBetaApplicationEmail(
  application: BetaApplication,
  env: Env,
): EmailPayload {
  const text = (Object.keys(fieldLabels) as Array<keyof typeof fieldLabels>)
    .map((key) => {
      const value = application[key];
      if (Array.isArray(value)) {
        return value.length ? `${fieldLabels[key]}: ${value.join(", ")}` : "";
      }
      return value ? `${fieldLabels[key]}: ${value}` : "";
    })
    .filter(Boolean)
    .join("\n");

  return {
    to: env.EMAIL_TO,
    from: { email: env.EMAIL_FROM, name: env.EMAIL_FROM_NAME },
    replyTo: application.email,
    subject: `SoloTrack Beta Application: ${application.name}`,
    text,
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function readString(value: unknown): string {
  return typeof value === "string" ? value.trim().slice(0, 1_000) : "";
}

function readStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map(readString)
    .filter(Boolean)
    .slice(0, 10);
}

function isValidEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}
