import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

import { writeState } from "../state.mjs";
import { renderStatusLine } from "../statusline.mjs";

const testDir = path.dirname(fileURLToPath(import.meta.url));
const scratchRoot = path.join(testDir, ".scratch-statusline");
const statuslinePath = path.resolve(testDir, "../statusline.mjs");

function makeHomeDir(label) {
  const homeDir = path.join(
    scratchRoot,
    `${label}-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`,
  );
  fs.mkdirSync(path.join(homeDir, ".copilot", "plugin-data", "knowledge-tracking"), {
    recursive: true,
  });
  return homeDir;
}

function pluginDataDir(homeDir) {
  return path.join(homeDir, ".copilot", "plugin-data", "knowledge-tracking");
}

function writeInstallMetadata(homeDir, metadata) {
  fs.writeFileSync(
    path.join(pluginDataDir(homeDir), "install.json"),
    `${JSON.stringify(metadata, null, 2)}\n`,
    "utf8",
  );
}

function runStatusLine({ homeDir, input, env = {} }) {
  const childEnv = { ...process.env };
  delete childEnv.NO_COLOR;

  return spawnSync(process.execPath, [statuslinePath], {
    input,
    encoding: "utf8",
    env: {
      ...childEnv,
      ...env,
      HOME: homeDir,
    },
  });
}

test("renderStatusLine colors Jira badges blue", () => {
  assert.equal(
    renderStatusLine(
      { session_id: "session-1" },
      {
        kind: "jira",
        identifier: "INFRA-4821",
      },
      "",
      true,
    ),
    "\u001b[34m● JIRA INFRA-4821\u001b[0m",
  );
});

test("renderStatusLine colors project badges magenta", () => {
  assert.equal(
    renderStatusLine(
      { session_id: "session-1" },
      {
        kind: "project",
        identifier: "barcolabs-software-switcher",
      },
      "",
      true,
    ),
    "\u001b[35m● PROJECT barcolabs-software-switcher\u001b[0m",
  );
});

test("renderStatusLine omits ANSI escapes when NO_COLOR is enabled", () => {
  assert.equal(
    renderStatusLine(
      { session_id: "session-1" },
      {
        kind: "jira",
        identifier: "INFRA-4821",
      },
      "",
      false,
    ),
    "● JIRA INFRA-4821",
  );
});

test("renderStatusLine preserves previous output when state is missing or invalid", () => {
  assert.equal(renderStatusLine({ session_id: "session-1" }, null, "model: gpt-5.6", true), "model: gpt-5.6");
  assert.equal(
    renderStatusLine(
      { session_id: "session-1" },
      { kind: "unknown", identifier: "INFRA-4821" },
      "model: gpt-5.6",
      true,
    ),
    "model: gpt-5.6",
  );
});

test("renderStatusLine appends the badge to previous output", () => {
  assert.equal(
    renderStatusLine(
      { session_id: "session-1" },
      {
        kind: "jira",
        identifier: "INFRA-4821",
      },
      "model: gpt-5.6",
      false,
    ),
    "model: gpt-5.6  ● JIRA INFRA-4821",
  );
});

test("CLI exits successfully for invalid JSON and emits a concise diagnostic", () => {
  const homeDir = makeHomeDir("invalid-json");
  try {
    const result = runStatusLine({
      homeDir,
      input: "{",
    });

    assert.equal(result.status, 0);
    assert.equal(result.stdout, "");
    assert.match(result.stderr, /^knowledge-tracking: invalid status-line payload\n$/u);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("CLI omits ANSI escapes when NO_COLOR is set", async () => {
  const homeDir = makeHomeDir("cli-no-color");
  try {
    await writeState(pluginDataDir(homeDir), "session-1", {
      action: "activate",
      kind: "jira",
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
    });

    const result = runStatusLine({
      homeDir,
      input: JSON.stringify({ session_id: "session-1" }),
      env: { NO_COLOR: "1" },
    });

    assert.equal(result.status, 0);
    assert.equal(result.stderr, "");
    assert.equal(result.stdout, "● JIRA INFRA-4821\n");
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("CLI preserves previous command output by replaying the same stdin payload", async () => {
  const homeDir = makeHomeDir("previous-command");
  try {
    await writeState(pluginDataDir(homeDir), "session-1", {
      action: "activate",
      kind: "jira",
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
    });

    writeInstallMetadata(homeDir, {
      previousStatusLine: {
        type: "command",
        command:
          "node -e 'const fs = require(\"node:fs\"); const payload = JSON.parse(fs.readFileSync(0, \"utf8\")); process.stdout.write(\"model: \" + payload.model);'",
      },
    });

    const result = runStatusLine({
      homeDir,
      input: JSON.stringify({
        session_id: "session-1",
        model: "gpt-5.6",
      }),
    });

    assert.equal(result.status, 0);
    assert.equal(result.stderr, "");
    assert.equal(
      result.stdout,
      "model: gpt-5.6  \u001b[34m● JIRA INFRA-4821\u001b[0m\n",
    );
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("CLI keeps the tracking badge when the previous command fails", async () => {
  const homeDir = makeHomeDir("previous-command-fails");
  try {
    await writeState(pluginDataDir(homeDir), "session-1", {
      action: "activate",
      kind: "jira",
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
    });

    writeInstallMetadata(homeDir, {
      previousStatusLine: {
        type: "command",
        command: "exit 7",
      },
    });

    const result = runStatusLine({
      homeDir,
      input: JSON.stringify({ session_id: "session-1" }),
    });

    assert.equal(result.status, 0);
    assert.equal(result.stdout, "\u001b[34m● JIRA INFRA-4821\u001b[0m\n");
    assert.match(
      result.stderr,
      /^knowledge-tracking: previous status-line command failed \(exit 7\)\n$/u,
    );
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("CLI keeps the tracking badge when the previous command times out", async () => {
  const homeDir = makeHomeDir("previous-command-timeout");
  try {
    await writeState(pluginDataDir(homeDir), "session-1", {
      action: "activate",
      kind: "project",
      identifier: "barcolabs-software-switcher",
      summary: "Tracking integration smoke test",
    });

    writeInstallMetadata(homeDir, {
      previousStatusLine: {
        type: "command",
        command: "node -e \"setTimeout(() => process.stdout.write('late'), 1500)\"",
      },
    });

    const result = runStatusLine({
      homeDir,
      input: JSON.stringify({ session_id: "session-1" }),
    });

    assert.equal(result.status, 0);
    assert.equal(
      result.stdout,
      "\u001b[35m● PROJECT barcolabs-software-switcher\u001b[0m\n",
    );
    assert.match(
      result.stderr,
      /^knowledge-tracking: previous status-line command timed out\n$/u,
    );
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("CLI leaves previous output unchanged when persisted state is invalid", () => {
  const homeDir = makeHomeDir("invalid-state");
  try {
    fs.mkdirSync(path.join(pluginDataDir(homeDir), "sessions"), { recursive: true });
    fs.writeFileSync(
      path.join(pluginDataDir(homeDir), "sessions", "session-1.json"),
      `${JSON.stringify(
        {
          version: 1,
          action: "stop",
          updatedAt: new Date().toISOString(),
        },
        null,
        2,
      )}\n`,
      "utf8",
    );

    writeInstallMetadata(homeDir, {
      previousStatusLine: {
        type: "command",
        command: "printf 'model: gpt-5.6\\n'",
      },
    });

    const result = runStatusLine({
      homeDir,
      input: JSON.stringify({ session_id: "session-1" }),
    });

    assert.equal(result.status, 0);
    assert.equal(result.stdout, "model: gpt-5.6\n");
    assert.match(result.stderr, /^knowledge-tracking: invalid tracking state\n$/u);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

import { _isMainModule } from "../statusline.mjs";

test("_isMainModule handles paths with spaces", () => {
  const baseDir = path.join(
    scratchRoot,
    `spaces-${process.pid}-${Date.now()}`,
    "path with spaces",
  );
  fs.mkdirSync(baseDir, { recursive: true });
  const scriptPath = path.join(baseDir, "script.mjs");
  fs.writeFileSync(scriptPath, "export default 1;\n", "utf8");

  const expectedUrl = pathToFileURL(scriptPath).href;

  assert.equal(_isMainModule(expectedUrl, scriptPath), true);
  fs.rmSync(path.dirname(baseDir), { recursive: true, force: true });
});

test("_isMainModule handles paths with non-ASCII characters", () => {
  const baseDir = path.join(
    scratchRoot,
    `unicode-${process.pid}-${Date.now()}`,
    "日本語パス",
  );
  fs.mkdirSync(baseDir, { recursive: true });
  const scriptPath = path.join(baseDir, "script.mjs");
  fs.writeFileSync(scriptPath, "export default 1;\n", "utf8");

  const expectedUrl = pathToFileURL(scriptPath).href;

  assert.equal(_isMainModule(expectedUrl, scriptPath), true);
  fs.rmSync(path.dirname(baseDir), { recursive: true, force: true });
});

test("_isMainModule resolves symlinked argv1", () => {
  const baseDir = path.join(
    scratchRoot,
    `symlink-main-${process.pid}-${Date.now()}`,
  );
  fs.mkdirSync(baseDir, { recursive: true });
  const symlinkPath = path.join(baseDir, "statusline-link.mjs");
  fs.symlinkSync(statuslinePath, symlinkPath);

  const expectedUrl = pathToFileURL(statuslinePath).href;

  assert.equal(_isMainModule(expectedUrl, symlinkPath), true);
  fs.rmSync(baseDir, { recursive: true, force: true });
});

import {
  _colorEnabled,
  _commandResolvesToRenderer,
} from "../statusline.mjs";

const extensionDir = path.resolve(testDir, "..");
const installedCommand = "node ~/.copilot/extensions/knowledge-tracking/statusline.mjs";

function makeLinkedHomeDir(label) {
  const homeDir = makeHomeDir(label);
  const extensionsDir = path.join(homeDir, ".copilot", "extensions");
  fs.mkdirSync(extensionsDir, { recursive: true });
  fs.symlinkSync(extensionDir, path.join(extensionsDir, "knowledge-tracking"));
  return homeDir;
}

test("_commandResolvesToRenderer detects the exact installed status-line command", () => {
  const homeDir = makeLinkedHomeDir("resolve-installed");
  try {
    assert.equal(_commandResolvesToRenderer(installedCommand, { home: homeDir }), true);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("_commandResolvesToRenderer detects absolute, quoted, and flagged renderer paths", () => {
  assert.equal(_commandResolvesToRenderer(`node ${statuslinePath}`), true);
  assert.equal(_commandResolvesToRenderer(`node --no-warnings "${statuslinePath}"`), true);
  assert.equal(_commandResolvesToRenderer(`node '${statuslinePath}'`), true);
  assert.equal(_commandResolvesToRenderer(`/usr/bin/env node ${statuslinePath} | cat`), true);
  assert.equal(
    _commandResolvesToRenderer(`node ${path.join(extensionDir, ".", "statusline.mjs")}`),
    true,
  );
});

test("_commandResolvesToRenderer detects $HOME and relative renderer paths", () => {
  const homeDir = makeLinkedHomeDir("resolve-home-var");
  try {
    assert.equal(
      _commandResolvesToRenderer(
        "node $HOME/.copilot/extensions/knowledge-tracking/statusline.mjs",
        { home: homeDir },
      ),
      true,
    );
    assert.equal(
      _commandResolvesToRenderer(
        "node ${HOME}/.copilot/extensions/knowledge-tracking/statusline.mjs",
        { home: homeDir },
      ),
      true,
    );
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
  assert.equal(
    _commandResolvesToRenderer("node ./statusline.mjs", { cwd: extensionDir }),
    true,
  );
});

test("_commandResolvesToRenderer detects a symlink that points at the renderer", () => {
  const homeDir = makeHomeDir("resolve-symlink");
  try {
    const symlinkPath = path.join(homeDir, "renderer-link.mjs");
    fs.symlinkSync(statuslinePath, symlinkPath);
    assert.equal(_commandResolvesToRenderer(`node ${symlinkPath}`), true);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("_commandResolvesToRenderer leaves unrelated commands alone", () => {
  assert.equal(_commandResolvesToRenderer("printf 'model: gpt-5.6'"), false);
  assert.equal(_commandResolvesToRenderer("node /nonexistent/statusline.mjs"), false);
  assert.equal(
    _commandResolvesToRenderer(`node ${path.join(extensionDir, "state.mjs")}`),
    false,
  );
  assert.equal(_commandResolvesToRenderer(""), false);
  assert.equal(_commandResolvesToRenderer(null), false);
  assert.equal(
    _commandResolvesToRenderer(installedCommand, { home: path.join(extensionDir, "no-such-home") }),
    false,
  );
});

test("CLI refuses to run the exact installed status-line command as the previous command", async () => {
  const homeDir = makeLinkedHomeDir("refuse-installed-command");
  const marker = path.join(homeDir, "recursion-marker");

  try {
    await writeState(pluginDataDir(homeDir), "session-1", {
      action: "activate",
      kind: "jira",
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
    });

    writeInstallMetadata(homeDir, {
      version: 1,
      previousStatusLine: {
        type: "command",
        command: `test -e "${marker}" || { touch "${marker}"; ${installedCommand}; }`,
        padding: 0,
      },
    });

    const result = runStatusLine({
      homeDir,
      input: JSON.stringify({ session_id: "session-1" }),
    });

    assert.equal(result.status, 0);
    assert.equal(fs.existsSync(marker), false);
    assert.equal(result.stdout, "\u001b[34m● JIRA INFRA-4821\u001b[0m\n");
    assert.match(
      result.stderr,
      /^knowledge-tracking: refusing to run the previous status-line command[^\n]*\n$/u,
    );
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("CLI refuses a previous command that reaches the renderer by absolute path", async () => {
  const homeDir = makeHomeDir("refuse-absolute-command");
  const marker = path.join(homeDir, "recursion-marker");

  try {
    await writeState(pluginDataDir(homeDir), "session-1", {
      action: "activate",
      kind: "project",
      identifier: "barcolabs-software-switcher",
      summary: "Tracking integration smoke test",
    });

    writeInstallMetadata(homeDir, {
      version: 1,
      previousStatusLine: {
        type: "command",
        command: `test -e "${marker}" || { touch "${marker}"; node "${statuslinePath}"; }`,
      },
    });

    const result = runStatusLine({
      homeDir,
      input: JSON.stringify({ session_id: "session-1" }),
    });

    assert.equal(result.status, 0);
    assert.equal(fs.existsSync(marker), false);
    assert.equal(result.stdout, "\u001b[35m● PROJECT barcolabs-software-switcher\u001b[0m\n");
    assert.equal(result.stderr.trimEnd().split("\n").length, 1);
    assert.match(result.stderr, /refusing to run the previous status-line command/u);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("_colorEnabled treats any NO_COLOR value, including an empty string, as disabling color", () => {
  assert.equal(_colorEnabled({}), true);
  assert.equal(_colorEnabled({ NO_COLOR: "1" }), false);
  assert.equal(_colorEnabled({ NO_COLOR: "" }), false);
  assert.equal(_colorEnabled({ NO_COLOR: "0" }), false);
  assert.equal(_colorEnabled({ NO_COLOR: "false" }), false);
});

test("CLI omits ANSI escapes when NO_COLOR is set to an empty string", async () => {
  const homeDir = makeHomeDir("cli-no-color-empty");
  try {
    await writeState(pluginDataDir(homeDir), "session-1", {
      action: "activate",
      kind: "jira",
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
    });

    const result = runStatusLine({
      homeDir,
      input: JSON.stringify({ session_id: "session-1" }),
      env: { NO_COLOR: "" },
    });

    assert.equal(result.status, 0);
    assert.equal(result.stderr, "");
    assert.equal(result.stdout, "● JIRA INFRA-4821\n");
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});
