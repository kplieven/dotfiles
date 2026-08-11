import { mkdir, open, readFile, rename, rm } from "node:fs/promises";
import path from "node:path";
import { randomBytes } from "node:crypto";

const SESSION_ID_PATTERN = /^[A-Za-z0-9._-]+$/u;
const ACTIONS = new Set(["activate", "update", "stop"]);
const PERSISTED_ACTIONS = new Set(["activate", "update"]);
const KINDS = new Set(["jira", "project"]);
const CONTROL_CHARACTER_PATTERN = /[\x00-\x1F\x7F-\x9F]/u;
const MAX_SESSION_NAME_CODE_POINTS = 100;

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function validateSessionId(sessionId) {
  if (
    typeof sessionId !== "string" ||
    !SESSION_ID_PATTERN.test(sessionId) ||
    sessionId.includes("..")
  ) {
    throw new TypeError(
      "sessionId must match ^[A-Za-z0-9._-]+$ and not contain ..",
    );
  }
  return sessionId;
}

function assertNoControlCharacters(value, fieldName) {
  if (CONTROL_CHARACTER_PATTERN.test(value)) {
    throw new TypeError(`${fieldName} must not contain control characters`);
  }
}

function normalizeText(value, fieldName) {
  if (typeof value !== "string") {
    throw new TypeError(`${fieldName} must be a string`);
  }

  assertNoControlCharacters(value, fieldName);

  const normalized = value.replace(/\s+/gu, " ").trim();
  if (normalized.length === 0) {
    throw new TypeError(`${fieldName} must not be empty`);
  }

  return normalized;
}

function truncateCodePoints(value, maxCodePoints) {
  const codePoints = [...value];
  if (codePoints.length <= maxCodePoints) {
    return value;
  }
  return codePoints.slice(0, maxCodePoints).join("");
}

function stateFilePath(baseDir, sessionId) {
  validateSessionId(sessionId);
  return path.join(baseDir, "sessions", `${sessionId}.json`);
}

function validateStoredState(input) {
  if (!isPlainObject(input)) {
    throw new TypeError("state must be an object");
  }

  if (input.version !== 1) {
    throw new TypeError("state.version must be 1");
  }

  if (typeof input.updatedAt !== "string" || Number.isNaN(Date.parse(input.updatedAt))) {
    throw new TypeError("state.updatedAt must be an ISO timestamp");
  }

  if (!PERSISTED_ACTIONS.has(input.action)) {
    throw new TypeError("persisted state.action must be activate or update");
  }

  if (!KINDS.has(input.kind)) {
    throw new TypeError("state.kind must be jira or project");
  }

  return {
    version: 1,
    action: input.action,
    kind: input.kind,
    identifier: normalizeText(input.identifier, "state.identifier"),
    summary: normalizeText(input.summary, "state.summary"),
    updatedAt: input.updatedAt,
  };
}

export function validateState(input) {
  if (!isPlainObject(input)) {
    throw new TypeError("state must be an object");
  }

  if (!ACTIONS.has(input.action)) {
    throw new TypeError("state.action must be activate, update, or stop");
  }

  if (input.action === "stop") {
    return { action: "stop" };
  }

  if (!KINDS.has(input.kind)) {
    throw new TypeError("state.kind must be jira or project");
  }

  return {
    action: input.action,
    kind: input.kind,
    identifier: normalizeText(input.identifier, "state.identifier"),
    summary: normalizeText(input.summary, "state.summary"),
  };
}

export function formatSessionName({ identifier, summary }) {
  const normalizedIdentifier = normalizeText(identifier, "identifier");
  const normalizedSummary = normalizeText(summary, "summary");
  return truncateCodePoints(
    `${normalizedIdentifier} - ${normalizedSummary}`,
    MAX_SESSION_NAME_CODE_POINTS,
  );
}

export async function readState(baseDir, sessionId) {
  const filePath = stateFilePath(baseDir, sessionId);

  try {
    const contents = await readFile(filePath, "utf8");
    return validateStoredState(JSON.parse(contents));
  } catch (error) {
    if (error?.code === "ENOENT") {
      return null;
    }
    throw error;
  }
}

export async function writeState(baseDir, sessionId, state) {
  const normalized = validateState(state);
  const filePath = stateFilePath(baseDir, sessionId);

  if (normalized.action === "stop") {
    await clearState(baseDir, sessionId);
    return null;
  }

  await mkdir(path.dirname(filePath), { recursive: true });

  const storedState = {
    version: 1,
    action: normalized.action,
    kind: normalized.kind,
    identifier: normalized.identifier,
    summary: normalized.summary,
    updatedAt: new Date().toISOString(),
  };

  const tempPath = path.join(
    path.dirname(filePath),
    `.${path.basename(filePath)}.${process.pid}.${Date.now()}.${randomBytes(6).toString("hex")}.tmp`,
  );

  const handle = await open(tempPath, "wx", 0o600);
  try {
    try {
      await handle.writeFile(`${JSON.stringify(storedState, null, 2)}\n`, "utf8");
    } finally {
      await handle.close();
    }

    await rename(tempPath, filePath);
    return storedState;
  } finally {
    await rm(tempPath, { force: true });
  }
}

export async function clearState(baseDir, sessionId) {
  const filePath = stateFilePath(baseDir, sessionId);
  await rm(filePath, { force: true });
  return null;
}
