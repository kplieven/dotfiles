import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import {
  clearState,
  formatSessionName,
  readState,
  validateState,
  writeState,
} from "../state.mjs";

const testDir = path.dirname(fileURLToPath(import.meta.url));
const scratchRoot = path.join(testDir, ".scratch-state");

function makeBaseDir(label) {
  const baseDir = path.join(
    scratchRoot,
    `${label}-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`,
  );
  fs.mkdirSync(path.join(baseDir, "sessions"), { recursive: true });
  return baseDir;
}

test("formatSessionName joins identifier and summary", () => {
  assert.equal(
    formatSessionName({
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
    }),
    "INFRA-4821 - Fix Redis failover downtime",
  );
});

test("formatSessionName normalizes whitespace", () => {
  assert.equal(
    formatSessionName({
      identifier: "  INFRA-4821  ",
      summary: "Fix   Redis   failover   downtime",
    }),
    "INFRA-4821 - Fix Redis failover downtime",
  );
});

test("formatSessionName truncates to 100 Unicode code points", () => {
  const result = formatSessionName({
    identifier: "PROJECT",
    summary: "🧪".repeat(200),
  });

  assert.equal([...result].length, 100);
  assert.equal(result, [..."PROJECT - ".concat("🧪".repeat(200))].slice(0, 100).join(""));
});

test("formatSessionName rejects control characters", () => {
  assert.throws(
    () =>
      formatSessionName({
        identifier: "INFRA-4821\n",
        summary: "Fix Redis failover downtime",
      }),
    /control/i,
  );
});

test("validateState accepts supported kinds and actions", () => {
  assert.deepEqual(
    validateState({
      action: "activate",
      kind: "jira",
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
    }),
    {
      action: "activate",
      kind: "jira",
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
    },
  );

  assert.deepEqual(
    validateState({
      action: "update",
      kind: "project",
      identifier: "barcolabs-software-switcher",
      summary: "Tracking integration smoke test",
    }),
    {
      action: "update",
      kind: "project",
      identifier: "barcolabs-software-switcher",
      summary: "Tracking integration smoke test",
    },
  );

  assert.deepEqual(validateState({ action: "stop" }), { action: "stop" });
});

test("validateState rejects unsupported kinds and actions", () => {
  assert.throws(
    () =>
      validateState({
        action: "activate",
        kind: "milestone",
        identifier: "INFRA-4821",
        summary: "Fix Redis failover downtime",
      }),
    /kind/i,
  );

  assert.throws(() => validateState({ action: "pause" }), /action/i);
});

test("readState and writeState reject invalid session IDs", async () => {
  const baseDir = makeBaseDir("invalid-session-id");
  try {
    const invalidSessionIds = ["", "foo/bar", "..", "foo bar"];

    for (const sessionId of invalidSessionIds) {
      await assert.rejects(() => readState(baseDir, sessionId), /sessionId/i);
      await assert.rejects(
        () =>
          writeState(baseDir, sessionId, {
            action: "activate",
            kind: "jira",
            identifier: "INFRA-4821",
            summary: "Fix Redis failover downtime",
          }),
        /sessionId/i,
      );
    }
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});

test("writeState replaces state atomically", async () => {
  const baseDir = makeBaseDir("atomic");
  try {
    await writeState(baseDir, "session-1", {
      action: "activate",
      kind: "jira",
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
    });

    const first = await readState(baseDir, "session-1");
    assert.equal(first?.kind, "jira");
    assert.equal(first?.identifier, "INFRA-4821");

    await writeState(baseDir, "session-1", {
      action: "update",
      kind: "project",
      identifier: "barcolabs-software-switcher",
      summary: "Tracking integration smoke test",
    });

    const second = await readState(baseDir, "session-1");
    assert.equal(second?.kind, "project");
    assert.equal(second?.identifier, "barcolabs-software-switcher");
    assert.equal(second?.summary, "Tracking integration smoke test");
    assert.equal(second?.action, "update");
    assert.equal(second?.version, 1);
    assert.match(second?.updatedAt ?? "", /^\d{4}-\d{2}-\d{2}T.*Z$/);
    assert.notDeepEqual(second, first);
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});

test("writeState with stop clears state", async () => {
  const baseDir = makeBaseDir("stop");
  try {
    await writeState(baseDir, "session-1", {
      action: "activate",
      kind: "jira",
      identifier: "INFRA-4821",
      summary: "Fix Redis failover downtime",
    });

    await writeState(baseDir, "session-1", { action: "stop" });

    assert.equal(await readState(baseDir, "session-1"), null);
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});

test("readState rejects persisted stop records", async () => {
  const baseDir = makeBaseDir("persisted-stop");
  try {
    fs.writeFileSync(
      path.join(baseDir, "sessions", "session-1.json"),
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

    await assert.rejects(() => readState(baseDir, "session-1"), /action/i);
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});

test("readState returns null when missing", async () => {
  const baseDir = makeBaseDir("missing");
  try {
    assert.equal(await readState(baseDir, "missing-session"), null);
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});

test("clearState is idempotent", async () => {
  const baseDir = makeBaseDir("clear");
  try {
    await clearState(baseDir, "session-1");
    await clearState(baseDir, "session-1");
    assert.equal(await readState(baseDir, "session-1"), null);
  } finally {
    fs.rmSync(baseDir, { recursive: true, force: true });
  }
});
