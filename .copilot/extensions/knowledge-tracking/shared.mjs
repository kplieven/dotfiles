import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { isDeepStrictEqual } from "node:util";
import { fileURLToPath, pathToFileURL } from "node:url";

export const INSTALLED_STATUS_LINE = Object.freeze({
  type: "command",
  command: "node ~/.copilot/extensions/knowledge-tracking/statusline.mjs",
  padding: 0,
});

const HOME_VARIABLE_PATTERN = /^(?:\$HOME|\$\{HOME\})(?=\/|$)/u;
const SHELL_TOKEN_PATTERN = /'([^']*)'|"((?:[^"\\]|\\.)*)"|([^\s;|&<>()]+)/gu;

export function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

export function homeDirectory() {
  return process.env.HOME || os.homedir();
}

export function realpathSafe(candidatePath) {
  try {
    return fs.realpathSync(candidatePath);
  } catch {
    return candidatePath;
  }
}

export function moduleHref(candidate, cwd = process.cwd()) {
  if (typeof candidate !== "string" || candidate === "") {
    return null;
  }

  try {
    return pathToFileURL(realpathSafe(path.resolve(cwd, candidate))).href;
  } catch {
    return null;
  }
}

export function isMainModule(moduleUrl, argv1, cwd = process.cwd()) {
  if (typeof moduleUrl !== "string" || moduleUrl === "") {
    return false;
  }

  return moduleHref(argv1, cwd) === moduleUrl;
}

export const RENDERER_PATH = realpathSafe(
  path.join(path.dirname(fileURLToPath(import.meta.url)), "statusline.mjs"),
);

export function shellTokens(command) {
  const tokens = [];

  for (const match of command.matchAll(SHELL_TOKEN_PATTERN)) {
    if (match[1] !== undefined) {
      tokens.push(match[1]);
    } else if (match[2] !== undefined) {
      tokens.push(match[2].replace(/\\(.)/gu, "$1"));
    } else if (match[3] !== undefined) {
      tokens.push(match[3]);
    }
  }

  return tokens;
}

function expandHomeToken(token, home) {
  if (token === "~") {
    return home;
  }

  if (token.startsWith("~/")) {
    return path.join(home, token.slice(2));
  }

  if (HOME_VARIABLE_PATTERN.test(token)) {
    return path.join(home, token.replace(HOME_VARIABLE_PATTERN, "").replace(/^\/+/u, ""));
  }

  return token;
}

export function commandResolvesToPath(
  command,
  targetPath,
  { home = homeDirectory(), cwd = process.cwd() } = {},
) {
  if (typeof command !== "string" || command.trim() === "" || typeof targetPath !== "string") {
    return false;
  }

  const target = realpathSafe(path.resolve(targetPath));

  for (const token of shellTokens(command)) {
    if (token === "") {
      continue;
    }

    try {
      if (realpathSafe(path.resolve(cwd, expandHomeToken(token, home))) === target) {
        return true;
      }
    } catch {
      continue;
    }
  }

  return false;
}

export function commandResolvesToRenderer(command, options = {}) {
  return commandResolvesToPath(command, RENDERER_PATH, options);
}

export function isTrackingStatusLine(value, options = {}) {
  if (isDeepStrictEqual(value, INSTALLED_STATUS_LINE)) {
    return true;
  }

  if (!isPlainObject(value) || value.type !== "command" || typeof value.command !== "string") {
    return false;
  }

  if (value.command.trim() === INSTALLED_STATUS_LINE.command) {
    return true;
  }

  return commandResolvesToRenderer(value.command, options);
}
