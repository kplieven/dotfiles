import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { fileURLToPath } from "node:url";

const testDir = path.dirname(fileURLToPath(import.meta.url));
const scratchRoot = path.join(testDir, ".scratch-install");
const installPath = path.resolve(testDir, "../install.mjs");
const installedStatusLine = {
  type: "command",
  command: "node ~/.copilot/extensions/knowledge-tracking/statusline.mjs",
  padding: 0,
};

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

function settingsPath(homeDir) {
  return path.join(homeDir, ".copilot", "settings.json");
}

function metadataPath(homeDir) {
  return path.join(homeDir, ".copilot", "plugin-data", "knowledge-tracking", "install.json");
}

function writeSettings(homeDir, contents) {
  fs.mkdirSync(path.dirname(settingsPath(homeDir)), { recursive: true });
  fs.writeFileSync(settingsPath(homeDir), contents, "utf8");
}

function readSettings(homeDir) {
  return fs.readFileSync(settingsPath(homeDir), "utf8");
}

function readMetadata(homeDir) {
  return JSON.parse(fs.readFileSync(metadataPath(homeDir), "utf8"));
}

function runInstaller(homeDir, command) {
  return spawnSync(process.execPath, [installPath, command], {
    encoding: "utf8",
    env: {
      ...process.env,
      HOME: homeDir,
    },
  });
}

test("install writes the tracking renderer when statusLine is absent", () => {
  const homeDir = makeHomeDir("install-fresh");
  const original = {
    model: "auto",
  };

  try {
    writeSettings(homeDir, `${JSON.stringify(original, null, 2)}\n`);

    const result = runInstaller(homeDir, "install");

    assert.equal(result.status, 0);
    assert.deepEqual(JSON.parse(readSettings(homeDir)), {
      ...original,
      statusLine: installedStatusLine,
    });
    assert.deepEqual(readMetadata(homeDir), {
      version: 1,
      previousStatusLine: null,
      installedStatusLine,
    });
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("install records the full original statusLine object before replacing it", () => {
  const homeDir = makeHomeDir("install-existing");
  const originalStatusLine = {
    type: "command",
    command: "printf 'model: gpt-5.6'",
    padding: 2,
    extra: {
      keep: true,
    },
  };

  try {
    writeSettings(
      homeDir,
      `${JSON.stringify(
        {
          model: "auto",
          statusLine: originalStatusLine,
        },
        null,
        2,
      )}\n`,
    );

    const result = runInstaller(homeDir, "install");

    assert.equal(result.status, 0);
    assert.deepEqual(JSON.parse(readSettings(homeDir)).statusLine, installedStatusLine);
    assert.deepEqual(readMetadata(homeDir).previousStatusLine, originalStatusLine);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("install is idempotent when run repeatedly", () => {
  const homeDir = makeHomeDir("install-repeat");

  try {
    writeSettings(
      homeDir,
      `${JSON.stringify(
        {
          model: "auto",
        },
        null,
        2,
      )}\n`,
    );

    const first = runInstaller(homeDir, "install");
    const firstSettings = readSettings(homeDir);
    const firstMetadata = fs.readFileSync(metadataPath(homeDir), "utf8");
    const second = runInstaller(homeDir, "install");

    assert.equal(first.status, 0);
    assert.equal(second.status, 0);
    assert.equal(readSettings(homeDir), firstSettings);
    assert.equal(fs.readFileSync(metadataPath(homeDir), "utf8"), firstMetadata);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("uninstall restores the exact original statusLine object", () => {
  const homeDir = makeHomeDir("uninstall-restore");
  const originalSettings = {
    model: "auto",
    statusLine: {
      type: "command",
      command: "printf 'model: gpt-5.6'",
      padding: 1,
      nested: {
        order: ["a", "b"],
      },
    },
  };
  const originalText = `${JSON.stringify(originalSettings, null, 2)}\n`;

  try {
    writeSettings(homeDir, originalText);

    assert.equal(runInstaller(homeDir, "install").status, 0);
    const result = runInstaller(homeDir, "uninstall");

    assert.equal(result.status, 0);
    assert.equal(readSettings(homeDir), originalText);
    assert.equal(fs.existsSync(metadataPath(homeDir)), false);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("uninstall removes only the installed statusLine when none existed before", () => {
  const homeDir = makeHomeDir("uninstall-remove");
  const originalSettings = {
    model: "auto",
    footer: {
      showBranch: true,
    },
  };
  const originalText = `${JSON.stringify(originalSettings, null, 2)}\n`;

  try {
    writeSettings(homeDir, originalText);

    assert.equal(runInstaller(homeDir, "install").status, 0);
    const result = runInstaller(homeDir, "uninstall");

    assert.equal(result.status, 0);
    assert.equal(readSettings(homeDir), originalText);
    assert.equal(fs.existsSync(metadataPath(homeDir)), false);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("install records null instead of its own renderer when metadata is missing", () => {
  const homeDir = makeHomeDir("install-already-no-metadata");
  const originalSettings = {
    model: "auto",
    statusLine: installedStatusLine,
  };
  const originalText = `${JSON.stringify(originalSettings, null, 2)}\n`;

  try {
    writeSettings(homeDir, originalText);
    assert.equal(fs.existsSync(metadataPath(homeDir)), false);

    const result = runInstaller(homeDir, "install");

    assert.equal(result.status, 0);
    assert.deepEqual(JSON.parse(readSettings(homeDir)).statusLine, installedStatusLine);
    assert.deepEqual(readMetadata(homeDir), {
      version: 1,
      previousStatusLine: null,
      installedStatusLine,
    });

    const uninstall = runInstaller(homeDir, "uninstall");

    assert.equal(uninstall.status, 0);
    assert.deepEqual(JSON.parse(readSettings(homeDir)), { model: "auto" });
    assert.equal(fs.existsSync(metadataPath(homeDir)), false);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("install warns and records null when metadata is corrupt and the renderer is already installed", () => {
  const homeDir = makeHomeDir("install-already-corrupt-metadata");

  try {
    writeSettings(
      homeDir,
      `${JSON.stringify({ model: "auto", statusLine: installedStatusLine }, null, 2)}\n`,
    );
    fs.writeFileSync(metadataPath(homeDir), "{ not json\n", "utf8");

    const result = runInstaller(homeDir, "install");

    assert.equal(result.status, 0);
    assert.match(result.stderr, /knowledge-tracking: .*install metadata/i);
    assert.match(result.stderr, /install\.json/);
    assert.deepEqual(readMetadata(homeDir), {
      version: 1,
      previousStatusLine: null,
      installedStatusLine,
    });

    const uninstall = runInstaller(homeDir, "uninstall");

    assert.equal(uninstall.status, 0);
    assert.deepEqual(JSON.parse(readSettings(homeDir)), { model: "auto" });
    assert.equal(fs.existsSync(metadataPath(homeDir)), false);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("install never records a status line that points at the tracking renderer", () => {
  const homeDir = makeHomeDir("install-already-variant");
  const rendererVariant = {
    type: "command",
    command: `node ${path.resolve(testDir, "../statusline.mjs")}`,
    padding: 4,
  };

  try {
    writeSettings(
      homeDir,
      `${JSON.stringify({ model: "auto", statusLine: rendererVariant }, null, 2)}\n`,
    );

    const result = runInstaller(homeDir, "install");

    assert.equal(result.status, 0);
    assert.deepEqual(JSON.parse(readSettings(homeDir)).statusLine, installedStatusLine);
    assert.equal(readMetadata(homeDir).previousStatusLine, null);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("install warns about corrupt metadata but still records a real previous status line", () => {
  const homeDir = makeHomeDir("install-corrupt-metadata");
  const originalStatusLine = {
    type: "command",
    command: "printf 'model: gpt-5.6'",
    padding: 2,
  };

  try {
    writeSettings(
      homeDir,
      `${JSON.stringify({ model: "auto", statusLine: originalStatusLine }, null, 2)}\n`,
    );
    fs.writeFileSync(metadataPath(homeDir), "]]not-json[[\n", "utf8");

    const result = runInstaller(homeDir, "install");

    assert.equal(result.status, 0);
    assert.match(result.stderr, /knowledge-tracking: .*install metadata/i);
    assert.deepEqual(readMetadata(homeDir).previousStatusLine, originalStatusLine);

    const uninstall = runInstaller(homeDir, "uninstall");

    assert.equal(uninstall.status, 0);
    assert.deepEqual(JSON.parse(readSettings(homeDir)).statusLine, originalStatusLine);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("uninstall drops a recorded previous status line that points at the tracking renderer", () => {
  const homeDir = makeHomeDir("uninstall-poisoned-metadata");

  try {
    writeSettings(
      homeDir,
      `${JSON.stringify({ model: "auto", statusLine: installedStatusLine }, null, 2)}\n`,
    );
    fs.writeFileSync(
      metadataPath(homeDir),
      `${JSON.stringify(
        {
          version: 1,
          previousStatusLine: installedStatusLine,
          installedStatusLine,
        },
        null,
        2,
      )}\n`,
      "utf8",
    );

    const result = runInstaller(homeDir, "uninstall");

    assert.equal(result.status, 0);
    assert.deepEqual(JSON.parse(readSettings(homeDir)), { model: "auto" });
    assert.equal(fs.existsSync(metadataPath(homeDir)), false);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("uninstall removes the tracking status line when metadata is missing", () => {
  const homeDir = makeHomeDir("uninstall-missing-metadata");
  const originalText = `${JSON.stringify({ model: "auto" }, null, 2)}\n`;

  try {
    writeSettings(homeDir, originalText);
    assert.equal(runInstaller(homeDir, "install").status, 0);
    fs.rmSync(metadataPath(homeDir));

    const result = runInstaller(homeDir, "uninstall");

    assert.equal(result.status, 0);
    assert.equal(readSettings(homeDir), originalText);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("uninstall refuses to overwrite a status line changed outside the installer", () => {  const homeDir = makeHomeDir("uninstall-lost-update");
  const originalStatusLine = {
    type: "command",
    command: "printf 'model: gpt-5.6'",
    padding: 1,
  };

  try {
    writeSettings(
      homeDir,
      `${JSON.stringify({ model: "auto", statusLine: originalStatusLine }, null, 2)}\n`,
    );
    assert.equal(runInstaller(homeDir, "install").status, 0);

    const externalSettings = {
      model: "auto",
      statusLine: {
        type: "command",
        command: "printf 'chosen by the user'",
        padding: 3,
      },
    };
    const externalText = `${JSON.stringify(externalSettings, null, 2)}\n`;
    writeSettings(homeDir, externalText);
    const metadataText = fs.readFileSync(metadataPath(homeDir), "utf8");

    const result = runInstaller(homeDir, "uninstall");

    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /statusLine/);
    assert.match(result.stderr, /changed|modified|not the tracking renderer/i);
    assert.equal(readSettings(homeDir), externalText);
    assert.equal(fs.readFileSync(metadataPath(homeDir), "utf8"), metadataText);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("uninstall refuses when the status line was removed outside the installer", () => {
  const homeDir = makeHomeDir("uninstall-removed-externally");

  try {
    writeSettings(homeDir, `${JSON.stringify({ model: "auto" }, null, 2)}\n`);
    assert.equal(runInstaller(homeDir, "install").status, 0);

    const externalText = `${JSON.stringify({ model: "auto" }, null, 2)}\n`;
    writeSettings(homeDir, externalText);
    const metadataText = fs.readFileSync(metadataPath(homeDir), "utf8");

    const result = runInstaller(homeDir, "uninstall");

    assert.notEqual(result.status, 0);
    assert.equal(readSettings(homeDir), externalText);
    assert.equal(fs.readFileSync(metadataPath(homeDir), "utf8"), metadataText);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("install and uninstall run through a symlinked install.mjs", () => {
  const homeDir = makeHomeDir("install-symlink");
  const linkDir = path.join(homeDir, "links");
  const linkPath = path.join(linkDir, "install-link.mjs");
  const originalSettings = { model: "auto" };
  const originalText = `${JSON.stringify(originalSettings, null, 2)}\n`;

  try {
    fs.mkdirSync(linkDir, { recursive: true });
    fs.symlinkSync(installPath, linkPath);
    writeSettings(homeDir, originalText);

    const install = spawnSync(process.execPath, [linkPath, "install"], {
      encoding: "utf8",
      env: { ...process.env, HOME: homeDir },
    });

    assert.equal(install.status, 0, `stderr: ${install.stderr}`);
    assert.deepEqual(JSON.parse(readSettings(homeDir)).statusLine, installedStatusLine);
    assert.deepEqual(readMetadata(homeDir), {
      version: 1,
      previousStatusLine: null,
      installedStatusLine,
    });

    const uninstall = spawnSync(process.execPath, [linkPath, "uninstall"], {
      encoding: "utf8",
      env: { ...process.env, HOME: homeDir },
    });

    assert.equal(uninstall.status, 0, `stderr: ${uninstall.stderr}`);
    assert.equal(readSettings(homeDir), originalText);
    assert.equal(fs.existsSync(metadataPath(homeDir)), false);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});

test("install refuses invalid JSONC and leaves settings untouched", () => {
  const homeDir = makeHomeDir("invalid-jsonc");
  const original = '{\n  // comments require manual /statusline setup\n  "model": "auto"\n}\n';

  try {
    writeSettings(homeDir, original);

    const result = runInstaller(homeDir, "install");

    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /manual .*\/statusline/i);
    assert.equal(readSettings(homeDir), original);
    assert.equal(fs.existsSync(metadataPath(homeDir)), false);
  } finally {
    fs.rmSync(homeDir, { recursive: true, force: true });
  }
});
