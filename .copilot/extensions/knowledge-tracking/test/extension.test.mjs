import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";
import { promisify } from "node:util";

import {
  createKnowledgeTrackingTool,
  handleTrackingState,
  joinTrackingSession,
  shouldAutoStart,
} from "../extension.mjs";
import { readState } from "../state.mjs";

const execFileAsync = promisify(execFile);
const testDir = path.dirname(fileURLToPath(import.meta.url));
const scratchRoot = path.join(testDir, ".scratch-extension");
const extensionPath = path.join(testDir, "..", "extension.mjs");
const extensionUrl = pathToFileURL(extensionPath).href;

function makeBaseDir(label) {
  const baseDir = path.join(
    scratchRoot,
    `${label}-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`,
  );
  fs.mkdirSync(path.join(baseDir, "sessions"), { recursive: true });
  return baseDir;
}

function makeSession(onSetName) {
  const calls = [];
  const session = {
    sessionId: "session-1",
    rpc: {
      name: {
        set: async (value) => {
          calls.push(value);
          await onSetName?.(value);
        },
      },
    },
  };

  return { calls, session };
}

test("handleTrackingState activation writes state and sets the session name", async () => {
  const baseDir = makeBaseDir("activate");
  const { calls, session } = makeSession();

  try {
    const result = await handleTrackingState(session, baseDir, {
      action: "activate",
      kind: "jira",
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
    });

    assert.match(result, /activated/i);
    assert.deepEqual(calls, [{ name: "INFRA-4821 - Fix Redis failover downtime" }]);
    const storedState = await readState(baseDir, "session-1");

    assert.deepEqual(storedState, {
      version: 1,
      action: "activate",
      kind: "jira",
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
      updatedAt: storedState?.updatedAt,
    });
    assert.match(storedState?.updatedAt ?? "", /^\d{4}-\d{2}-\d{2}T.*Z$/);
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});

test("handleTrackingState update replaces state and sets the replacement session name", async () => {
  const baseDir = makeBaseDir("update");
  const { calls, session } = makeSession();

  try {
    await handleTrackingState(session, baseDir, {
      action: "activate",
      kind: "jira",
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
    });

    const result = await handleTrackingState(session, baseDir, {
      action: "update",
      kind: "project",
      identifier: "barcolabs-software-switcher",
      summary: "Tracking integration smoke test",
    });

    assert.match(result, /updated/i);
    assert.deepEqual(calls, [
      { name: "INFRA-4821 - Fix Redis failover downtime" },
      { name: "barcolabs-software-switcher - Tracking integration smoke test" },
    ]);
    const storedState = await readState(baseDir, "session-1");

    assert.deepEqual(storedState, {
      version: 1,
      action: "update",
      kind: "project",
      identifier: "barcolabs-software-switcher",
      summary: "Tracking integration smoke test",
      updatedAt: storedState?.updatedAt,
    });
    assert.match(storedState?.updatedAt ?? "", /^\d{4}-\d{2}-\d{2}T.*Z$/);
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});

test("handleTrackingState stop clears state without changing the session name", async () => {
  const baseDir = makeBaseDir("stop");
  const { calls, session } = makeSession();

  try {
    await handleTrackingState(session, baseDir, {
      action: "activate",
      kind: "jira",
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
    });

    const result = await handleTrackingState(session, baseDir, {
      action: "stop",
      kind: "project",
      identifier: "ignored",
      summary: "ignored",
    });

    assert.match(result, /stopped/i);
    assert.deepEqual(calls, [{ name: "INFRA-4821 - Fix Redis failover downtime" }]);
    assert.equal(await readState(baseDir, "session-1"), null);
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});

test("handleTrackingState rejects invalid activation input without writing state", async () => {
  const baseDir = makeBaseDir("invalid");
  const { calls, session } = makeSession();

  try {
    await assert.rejects(
      () =>
        handleTrackingState(session, baseDir, {
          action: "activate",
          kind: "jira",
          identifier: "INFRA-4821",
        }),
      /summary/i,
    );

    assert.deepEqual(calls, []);
    assert.equal(await readState(baseDir, "session-1"), null);
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});

test("handleTrackingState removes the just-written state when session naming fails", async () => {
  const baseDir = makeBaseDir("rollback");
  const { calls, session } = makeSession(async () => {
    throw new Error("rpc unavailable");
  });

  try {
    await assert.rejects(
      () =>
        handleTrackingState(session, baseDir, {
          action: "activate",
          kind: "jira",
          identifier: "INFRA-4821",
          summary: "Fix Redis failover downtime",
        }),
      /rpc unavailable/i,
    );

    assert.deepEqual(calls, [{ name: "INFRA-4821 - Fix Redis failover downtime" }]);
    assert.equal(await readState(baseDir, "session-1"), null);
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});

test("createKnowledgeTrackingTool exposes the planned schema", () => {
  const tool = createKnowledgeTrackingTool({ session: { sessionId: "session-1" }, stateDir: "/state" });

  assert.equal(tool.name, "knowledge_tracking_state");
  assert.equal(tool.defer, "never");
  assert.equal(tool.parameters.type, "object");
  assert.equal(tool.parameters.additionalProperties, false);
  assert.deepEqual(tool.parameters.required, ["action"]);
  assert.deepEqual(tool.parameters.properties.action.enum, ["activate", "update", "stop"]);
  assert.deepEqual(tool.parameters.properties.kind.enum, ["jira", "project"]);
  assert.equal(typeof tool.handler, "function");
});

test("joinTrackingSession registers the knowledge tracking tool through joinSession", async () => {
  const fakeSession = {
    sessionId: "session-1",
    rpc: { name: { set: async () => {} } },
  };
  const joinSessionCalls = [];

  const returnedSession = await joinTrackingSession({
    joinSession: async (options) => {
      joinSessionCalls.push(options);
      return fakeSession;
    },
    stateDir: "/state",
  });

  assert.equal(returnedSession, fakeSession);
  assert.equal(joinSessionCalls.length, 1);
  assert.equal(joinSessionCalls[0].tools.length, 1);
  assert.equal(joinSessionCalls[0].tools[0].name, "knowledge_tracking_state");
});

test("shouldAutoStart runs the extension when the CLI host imports it via EXTENSION_PATH", () => {
  assert.equal(
    shouldAutoStart({
      moduleUrl: extensionUrl,
      argv1: "/home/karlie/.cache/copilot/pkg/linux-x64/1.0.79/preloads/extension_bootstrap.mjs",
      extensionPath,
    }),
    true,
  );
});

test("shouldAutoStart runs the extension when it is executed directly", () => {
  assert.equal(
    shouldAutoStart({ moduleUrl: extensionUrl, argv1: extensionPath, extensionPath: undefined }),
    true,
  );
});

test("shouldAutoStart resolves a relative EXTENSION_PATH against the working directory", () => {
  assert.equal(
    shouldAutoStart({
      moduleUrl: extensionUrl,
      argv1: undefined,
      extensionPath: "./extension.mjs",
      cwd: path.dirname(extensionPath),
    }),
    true,
  );
});

test("shouldAutoStart stays inert when the module is only imported", () => {
  assert.equal(
    shouldAutoStart({
      moduleUrl: extensionUrl,
      argv1: "/usr/lib/node_modules/npm/bin/node-test.js",
      extensionPath: path.join(testDir, "..", "..", "other-extension", "extension.mjs"),
    }),
    false,
  );
  assert.equal(shouldAutoStart({ moduleUrl: extensionUrl }), false);
  assert.equal(shouldAutoStart({}), false);
  assert.equal(shouldAutoStart(), false);
  assert.equal(
    shouldAutoStart({ moduleUrl: extensionUrl, argv1: "", extensionPath: "" }),
    false,
  );
});

test("the extension joins the session when the CLI bootstrap imports it", async () => {
  const baseDir = path.join(
    scratchRoot,
    `bootstrap-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`,
  );
  fs.mkdirSync(baseDir, { recursive: true });

  const stubPath = path.join(baseDir, "sdk-stub.mjs");
  const resolverPath = path.join(baseDir, "resolver.mjs");
  const bootstrapPath = path.join(baseDir, "bootstrap.mjs");

  fs.writeFileSync(
    stubPath,
    [
      "export async function joinSession(config) {",
      "  process.stdout.write(",
      "    `${JSON.stringify({ joined: true, tools: config.tools.map((tool) => tool.name) })}\\n`,",
      "  );",
      '  return { sessionId: "stub-session", rpc: { name: { set: async () => {} } } };',
      "}",
      "",
    ].join("\n"),
    "utf8",
  );

  fs.writeFileSync(
    resolverPath,
    [
      "let stubUrl;",
      "export async function initialize(data) {",
      "  stubUrl = data.stubUrl;",
      "}",
      "export async function resolve(specifier, context, nextResolve) {",
      '  if (specifier === "@github/copilot-sdk/extension") {',
      "    return { url: stubUrl, shortCircuit: true };",
      "  }",
      "  return nextResolve(specifier, context);",
      "}",
      "",
    ].join("\n"),
    "utf8",
  );

  fs.writeFileSync(
    bootstrapPath,
    [
      'import { register } from "node:module";',
      'import { pathToFileURL } from "node:url";',
      'register("./resolver.mjs", import.meta.url, {',
      "  data: { stubUrl: pathToFileURL(process.env.SDK_STUB_PATH).href },",
      "});",
      "await import(pathToFileURL(process.env.EXTENSION_PATH).href);",
      "",
    ].join("\n"),
    "utf8",
  );

  try {
    const { stdout } = await execFileAsync(process.execPath, [bootstrapPath], {
      env: {
        ...process.env,
        EXTENSION_PATH: extensionPath,
        SDK_STUB_PATH: stubPath,
      },
      timeout: 20000,
    });

    assert.deepEqual(JSON.parse(stdout.trim()), {
      joined: true,
      tools: ["knowledge_tracking_state"],
    });
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});

test("shouldAutoStart matches when EXTENSION_PATH is a symlink to the real extension", () => {
  const baseDir = path.join(
    scratchRoot,
    `symlink-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`,
  );
  fs.mkdirSync(baseDir, { recursive: true });

  const symlinkPath = path.join(baseDir, "extension-link.mjs");
  fs.symlinkSync(extensionPath, symlinkPath);

  try {
    assert.equal(
      shouldAutoStart({
        moduleUrl: extensionUrl,
        argv1: undefined,
        extensionPath: symlinkPath,
      }),
      true,
    );
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});

test("end-to-end bootstrap through a symlinked extension path joins the session", async () => {
  const baseDir = path.join(
    scratchRoot,
    `symlink-e2e-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`,
  );
  fs.mkdirSync(baseDir, { recursive: true });

  const symlinkDir = path.join(baseDir, "linked-ext");
  fs.symlinkSync(path.resolve(testDir, ".."), symlinkDir);

  const symlinkedExtension = path.join(symlinkDir, "extension.mjs");

  const stubPath = path.join(baseDir, "sdk-stub.mjs");
  const resolverPath = path.join(baseDir, "resolver.mjs");
  const bootstrapPath = path.join(baseDir, "bootstrap.mjs");

  fs.writeFileSync(
    stubPath,
    [
      "export async function joinSession(config) {",
      "  process.stdout.write(",
      "    `${JSON.stringify({ joined: true, tools: config.tools.map((tool) => tool.name) })}\\n`,",
      "  );",
      '  return { sessionId: "stub-session", rpc: { name: { set: async () => {} } } };',
      "}",
      "",
    ].join("\n"),
    "utf8",
  );

  fs.writeFileSync(
    resolverPath,
    [
      "let stubUrl;",
      "export async function initialize(data) {",
      "  stubUrl = data.stubUrl;",
      "}",
      "export async function resolve(specifier, context, nextResolve) {",
      '  if (specifier === "@github/copilot-sdk/extension") {',
      "    return { url: stubUrl, shortCircuit: true };",
      "  }",
      "  return nextResolve(specifier, context);",
      "}",
      "",
    ].join("\n"),
    "utf8",
  );

  fs.writeFileSync(
    bootstrapPath,
    [
      'import { register } from "node:module";',
      'import { pathToFileURL } from "node:url";',
      'register("./resolver.mjs", import.meta.url, {',
      "  data: { stubUrl: pathToFileURL(process.env.SDK_STUB_PATH).href },",
      "});",
      "await import(pathToFileURL(process.env.EXTENSION_PATH).href);",
      "",
    ].join("\n"),
    "utf8",
  );

  try {
    const { stdout } = await execFileAsync(process.execPath, [bootstrapPath], {
      env: {
        ...process.env,
        EXTENSION_PATH: symlinkedExtension,
        SDK_STUB_PATH: stubPath,
      },
      timeout: 20000,
    });

    assert.deepEqual(JSON.parse(stdout.trim()), {
      joined: true,
      tools: ["knowledge_tracking_state"],
    });
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});
