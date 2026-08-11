import path from "node:path";
import { readFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";

import { readState } from "./state.mjs";
import {
  commandResolvesToRenderer,
  homeDirectory,
  isMainModule,
  isPlainObject,
} from "./shared.mjs";

const INSTALL_METADATA_PATH = ["~", ".copilot", "plugin-data", "knowledge-tracking", "install.json"];
const STATE_BASE_PATH = ["~", ".copilot", "plugin-data", "knowledge-tracking"];
const BADGE_PREFIX = "●";
const COLORS = {
  jira: 34,
  project: 35,
};

function resolveHomePath(parts) {
  const [first, ...rest] = parts;
  if (first !== "~") {
    return path.join(...parts);
  }
  return path.join(homeDirectory(), ...rest);
}

function badgeLabel(state) {
  if (!isPlainObject(state) || typeof state.identifier !== "string" || state.identifier.trim() === "") {
    return "";
  }

  if (state.kind === "jira") {
    return `${BADGE_PREFIX} JIRA ${state.identifier}`;
  }

  if (state.kind === "project") {
    return `${BADGE_PREFIX} PROJECT ${state.identifier}`;
  }

  return "";
}

function colorize(label, kind, colorEnabled) {
  if (!label) {
    return "";
  }

  if (!colorEnabled) {
    return label;
  }

  const color = COLORS[kind];
  if (!color) {
    return label;
  }

  return `\u001b[${color}m${label}\u001b[0m`;
}

async function readPayload() {
  let raw = "";

  for await (const chunk of process.stdin) {
    raw += chunk;
  }

  try {
    const payload = JSON.parse(raw);
    if (!isPlainObject(payload)) {
      throw new TypeError("payload must be an object");
    }
    return { payload, raw };
  } catch {
    return { payload: null, raw };
  }
}

async function readInstallMetadata() {
  try {
    const contents = await readFile(resolveHomePath(INSTALL_METADATA_PATH), "utf8");
    return JSON.parse(contents);
  } catch (error) {
    if (error?.code === "ENOENT") {
      return null;
    }
    throw error;
  }
}

function previousCommandFromMetadata(metadata) {
  if (!isPlainObject(metadata)) {
    return null;
  }

  const candidates = [
    metadata.previousStatusLine,
    metadata.previousStatusline,
    metadata.statusLine,
    metadata.statusline,
  ];

  for (const candidate of candidates) {
    if (
      isPlainObject(candidate) &&
      candidate.type === "command" &&
      typeof candidate.command === "string" &&
      candidate.command.trim() !== ""
    ) {
      return candidate.command;
    }
  }

  if (typeof metadata.previousCommand === "string" && metadata.previousCommand.trim() !== "") {
    return metadata.previousCommand;
  }

  return null;
}

function logDiagnostic(message) {
  process.stderr.write(`knowledge-tracking: ${message}\n`);
}

function colorEnabled(env = process.env) {
  return !Object.prototype.hasOwnProperty.call(env ?? {}, "NO_COLOR");
}

function runPreviousCommand(previousCommand, rawPayload) {
  if (!previousCommand) {
    return "";
  }

  const result = spawnSync("/bin/sh", ["-c", previousCommand], {
    input: rawPayload,
    encoding: "utf8",
    timeout: 1000,
  });

  const output = typeof result.stdout === "string" ? result.stdout.trim() : "";

  if (result.error?.code === "ETIMEDOUT") {
    logDiagnostic("previous status-line command timed out");
    return output;
  }

  if (typeof result.status === "number" && result.status !== 0) {
    logDiagnostic(`previous status-line command failed (exit ${result.status})`);
    return output;
  }

  if (result.error) {
    logDiagnostic("previous status-line command failed");
    return output;
  }

  return output;
}

export function renderStatusLine(payload, state, previousOutput, colorEnabled) {
  void payload;

  const trimmedPreviousOutput =
    typeof previousOutput === "string" ? previousOutput.trim() : "";
  const label = badgeLabel(state);
  const badge = label ? colorize(label, state.kind, colorEnabled) : "";

  if (trimmedPreviousOutput && badge) {
    return `${trimmedPreviousOutput}  ${badge}`;
  }

  if (trimmedPreviousOutput) {
    return trimmedPreviousOutput;
  }

  return badge;
}

export async function main() {
  const { payload, raw } = await readPayload();
  if (!payload) {
    logDiagnostic("invalid status-line payload");
    return;
  }

  let previousOutput = "";
  try {
    const metadata = await readInstallMetadata();
    const previousCommand = previousCommandFromMetadata(metadata);

    if (previousCommand !== null && commandResolvesToRenderer(previousCommand)) {
      logDiagnostic(
        "refusing to run the previous status-line command because it starts this renderer again; " +
          "fix previousStatusLine in ~/.copilot/plugin-data/knowledge-tracking/install.json",
      );
    } else {
      previousOutput = runPreviousCommand(previousCommand, raw);
    }
  } catch {
    logDiagnostic("invalid install metadata");
  }

  let state = null;
  if (typeof payload.session_id === "string" && payload.session_id.length > 0) {
    try {
      state = await readState(resolveHomePath(STATE_BASE_PATH), payload.session_id);
    } catch {
      logDiagnostic("invalid tracking state");
    }
  }

  const line = renderStatusLine(payload, state, previousOutput, colorEnabled(process.env));
  if (line) {
    process.stdout.write(`${line}\n`);
  }
}

export { colorEnabled as _colorEnabled };
export { commandResolvesToRenderer as _commandResolvesToRenderer };
export { isMainModule as _isMainModule };

if (isMainModule(import.meta.url, process.argv[1])) {
  await main();
}
