import os from "node:os";
import path from "node:path";
import { mkdir, open, readFile, rename, rm } from "node:fs/promises";
import { randomBytes } from "node:crypto";
import { isDeepStrictEqual } from "node:util";

import {
  INSTALLED_STATUS_LINE,
  isMainModule,
  isPlainObject,
  isTrackingStatusLine,
} from "./shared.mjs";

const SETTINGS_PATH = ["~", ".copilot", "settings.json"];
const INSTALL_METADATA_PATH = ["~", ".copilot", "plugin-data", "knowledge-tracking", "install.json"];

export { INSTALLED_STATUS_LINE };

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

function cloneJson(value) {
  return value === null ? null : JSON.parse(JSON.stringify(value));
}

function logError(message) {
  process.stderr.write(`knowledge-tracking: ${message}\n`);
}

async function readJsonFile(filePath) {
  try {
    return await readFile(filePath, "utf8");
  } catch (error) {
    if (error?.code === "ENOENT") {
      return null;
    }
    throw error;
  }
}

async function atomicWriteJson(filePath, value) {
  await mkdir(path.dirname(filePath), { recursive: true });

  const tempPath = path.join(
    path.dirname(filePath),
    `.${path.basename(filePath)}.${process.pid}.${Date.now()}.${randomBytes(6).toString("hex")}.tmp`,
  );

  const handle = await open(tempPath, "wx", 0o600);
  try {
    try {
      await handle.writeFile(`${JSON.stringify(value, null, 2)}\n`, "utf8");
    } finally {
      await handle.close();
    }

    await rename(tempPath, filePath);
  } finally {
    await rm(tempPath, { force: true });
  }
}

async function loadSettings(settingsPath) {
  const rawSettings = await readJsonFile(settingsPath);
  if (rawSettings === null) {
    return {};
  }

  try {
    const settings = JSON.parse(rawSettings);
    if (!isPlainObject(settings)) {
      throw new TypeError("settings must be an object");
    }
    return settings;
  } catch {
    throw new Error("settings.json is not strict JSON; manual /statusline configuration is required");
  }
}

async function loadMetadata(metadataPath) {
  const rawMetadata = await readJsonFile(metadataPath);
  if (rawMetadata === null) {
    return null;
  }

  const metadata = JSON.parse(rawMetadata);
  if (!isPlainObject(metadata)) {
    throw new TypeError("install metadata must be an object");
  }
  return metadata;
}

function buildMetadata(previousStatusLine) {
  return {
    version: 1,
    previousStatusLine: previousStatusLine === undefined ? null : cloneJson(previousStatusLine),
    installedStatusLine: cloneJson(INSTALLED_STATUS_LINE),
  };
}

function describeError(error) {
  return error instanceof Error ? error.message : String(error);
}

function recordedPreviousStatusLine(metadata) {
  if (
    !isPlainObject(metadata) ||
    !Object.prototype.hasOwnProperty.call(metadata, "previousStatusLine")
  ) {
    return null;
  }

  if (isTrackingStatusLine(metadata.previousStatusLine)) {
    return null;
  }

  return metadata.previousStatusLine;
}

export async function installStatusLine({
  settingsPath = resolveHomePath(SETTINGS_PATH),
  metadataPath = resolveHomePath(INSTALL_METADATA_PATH),
} = {}) {
  const settings = await loadSettings(settingsPath);
  let metadata = null;

  try {
    metadata = await loadMetadata(metadataPath);
  } catch (error) {
    metadata = null;
    logError(
      `install metadata at ${metadataPath} is unreadable (${describeError(error)}); rebuilding it, ` +
        "so uninstall will remove the tracking status line instead of restoring an earlier one",
    );
  }

  const currentStatusLine = Object.prototype.hasOwnProperty.call(settings, "statusLine")
    ? settings.statusLine
    : undefined;

  const previousStatusLine = isTrackingStatusLine(currentStatusLine)
    ? recordedPreviousStatusLine(metadata)
    : currentStatusLine;

  settings.statusLine = cloneJson(INSTALLED_STATUS_LINE);

  await atomicWriteJson(metadataPath, buildMetadata(previousStatusLine));
  await atomicWriteJson(settingsPath, settings);
}

export async function uninstallStatusLine({
  settingsPath = resolveHomePath(SETTINGS_PATH),
  metadataPath = resolveHomePath(INSTALL_METADATA_PATH),
} = {}) {
  const settings = await loadSettings(settingsPath);
  const currentStatusLine = Object.prototype.hasOwnProperty.call(settings, "statusLine")
    ? settings.statusLine
    : undefined;

  if (!isDeepStrictEqual(currentStatusLine, INSTALLED_STATUS_LINE)) {
    throw new Error(
      `settings.statusLine was changed outside this installer, so ${settingsPath} and ${metadataPath} ` +
        "were left untouched; restore the tracking status line with /statusline (or re-run install) " +
        "before uninstalling, or delete the install metadata if you no longer need it",
    );
  }

  let metadata = null;
  try {
    metadata = await loadMetadata(metadataPath);
  } catch (error) {
    metadata = null;
    logError(
      `install metadata at ${metadataPath} is unreadable (${describeError(error)}); removing the ` +
        "tracking status line without restoring an earlier one",
    );
  }

  const previousStatusLine = recordedPreviousStatusLine(metadata);

  if (previousStatusLine === null || previousStatusLine === undefined) {
    delete settings.statusLine;
  } else {
    settings.statusLine = cloneJson(previousStatusLine);
  }

  await atomicWriteJson(settingsPath, settings);
  await rm(metadataPath, { force: true });
}

export async function main(argv = process.argv.slice(2)) {
  const command = argv[0];

  if (command !== "install" && command !== "uninstall") {
    logError("usage: node install.mjs <install|uninstall>");
    return 1;
  }

  try {
    if (command === "install") {
      await installStatusLine();
    } else {
      await uninstallStatusLine();
    }
    return 0;
  } catch (error) {
    logError(error instanceof Error ? error.message : String(error));
    return 1;
  }
}

if (isMainModule(import.meta.url, process.argv[1])) {
  process.exitCode = await main();
}
