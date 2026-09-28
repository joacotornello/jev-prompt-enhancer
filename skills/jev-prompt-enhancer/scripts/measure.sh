#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ $# -ne 0 ]]; then
  echo 'Usage: measure.sh < input.json (prompt and optional context)' >&2
  exit 1
fi

QUESTIONS_FILE="$SCRIPT_DIR/../assets/questions.json"

node -e '
  (async () => {
  const fs = require("node:fs");
  let apiKey = process.env.JEV_API_KEY;
  const envFile = process.argv[2];
  if (!apiKey && fs.existsSync(envFile)) {
    // Read only literal, single-line assignments.
    for (const line of fs.readFileSync(envFile, "utf8").split(/\r?\n/)) {
      const match = line.match(/^\s*(?:export\s+)?JEV_API_KEY\s*=\s*(?:"([^"]*)"|\x27([^\x27]*)\x27|([^\s#"\x27]*))\s*(?:#.*)?$/);
      if (match) apiKey = match[1] ?? match[2] ?? match[3];
    }
  }
  if (!apiKey) throw new Error("JEV_API_KEY is required");
  const { prompt, context = "" } = JSON.parse(fs.readFileSync(0, "utf8"));
  if (typeof prompt !== "string" || !prompt.trim() || typeof context !== "string") {
    throw new Error("Expected a nonblank prompt string and optional context string");
  }
  const questions = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const response = await fetch("https://api.typesafe.ai/v1/systemone", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ model: "jev-latest", state: { prompt, context }, questions }),
    signal: AbortSignal.timeout(5000)
  });
  if (!response.ok) throw new Error(`Jev HTTP ${response.status}`);
  process.stdout.write(await response.text());
  })().catch(error => {
    console.error(error.message);
    process.exitCode = 1;
  });
' "$QUESTIONS_FILE" "${JEV_ENV_FILE:-$PWD/.env}"
