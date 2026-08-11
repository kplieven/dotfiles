import os from "node:os";
import path from "node:path";

import { clearState, formatSessionName, validateState, writeState } from "./state.mjs";
import { moduleHref } from "./shared.mjs";

const STATE_BASE_PATH = ["~", ".copilot", "plugin-data", "knowledge-tracking"];

function homeDirectory() {
  return process.env.HOME || os.homedir();
}

function resolveHomePath(parts) {
  const [first, ...rest] = parts;
  if (first !== "~") {
    return path.join(...parts);
  }
  return path.join(homeDirectory(), ...rest);
}

function sessionNameSetter(session) {
  const setName = session?.rpc?.name?.set;
  if (typeof setName !== "function") {
    throw new TypeError("session.rpc.name.set must be available");
  }
  return setName.bind(session.rpc.name);
}

export async function handleTrackingState(session, baseDir, args) {
  const state = validateState(args);

  if (state.action === "stop") {
    await clearState(baseDir, session?.sessionId);
    return "Tracking stopped.";
  }

  await writeState(baseDir, session?.sessionId, state);

  try {
    const setName = sessionNameSetter(session);
    await setName({
      name: formatSessionName(state),
    });
  } catch (error) {
    await clearState(baseDir, session?.sessionId);
    throw error;
  }

  if (state.action === "activate") {
    return `Tracking activated for ${state.identifier}.`;
  }

  return `Tracking updated for ${state.identifier}.`;
}

export function createKnowledgeTrackingTool({ session, getSession = () => session, stateDir }) {
  return {
    name: "knowledge_tracking_state",
    description:
      "Update the active Jira or project knowledge tracker for this Copilot CLI session, including its session name and status-line state.",
    defer: "never",
    parameters: {
      type: "object",
      additionalProperties: false,
      required: ["action"],
      properties: {
        action: { enum: ["activate", "update", "stop"] },
        kind: { enum: ["jira", "project"] },
        identifier: { type: "string", minLength: 1 },
        summary: { type: "string", minLength: 1 },
      },
    },
    handler: (args) => handleTrackingState(getSession(), stateDir, args),
  };
}

export async function joinTrackingSession({
  joinSession,
  stateDir = resolveHomePath(STATE_BASE_PATH),
} = {}) {
  if (typeof joinSession !== "function") {
    throw new TypeError("joinSession must be a function");
  }

  let session;
  session = await joinSession({
    tools: [
      createKnowledgeTrackingTool({
        getSession: () => session,
        stateDir,
      }),
    ],
  });

  return session;
}

async function loadJoinSession() {
  const sdk = await import("@github/copilot-sdk/extension");
  return sdk.joinSession;
}

export async function startExtension() {
  return joinTrackingSession({
    joinSession: await loadJoinSession(),
  });
}

export function shouldAutoStart({
  moduleUrl,
  argv1,
  extensionPath,
  cwd = process.cwd(),
} = {}) {
  if (typeof moduleUrl !== "string" || moduleUrl === "") {
    return false;
  }

  return [argv1, extensionPath].some((candidate) => moduleHref(candidate, cwd) === moduleUrl);
}

if (
  shouldAutoStart({
    moduleUrl: import.meta.url,
    argv1: process.argv[1],
    extensionPath: process.env.EXTENSION_PATH,
  })
) {
  await startExtension();
}
