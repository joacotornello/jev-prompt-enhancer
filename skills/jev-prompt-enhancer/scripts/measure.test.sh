#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export JEV_API_KEY=test
unset JEV_ENV_FILE
node() {
  command node -e '
    global.fetch = async (url, options) => {
      const assert = require("node:assert/strict");
      assert.equal(url, "https://api.typesafe.ai/v1/systemone");
      assert.equal(options.method, "POST");
      assert.equal(options.headers.Authorization, `Bearer ${process.env.EXPECTED_KEY || "test"}`);
      assert.equal(options.headers["Content-Type"], "application/json");
      assert.ok(options.signal instanceof AbortSignal);
      if (process.env.FETCH_FAILURE === "network") throw new Error("fetch failed");
      return { ok: !process.env.FETCH_FAILURE, status: 401, text: async () => options.body };
    };
    const code = process.argv.splice(1, 2)[1];
    eval(code);
  ' -- "$@"
}
export -f node

node -e '
  const text = "  Quotes: \"\u0027; backslash: \\; shell: $HOME $(exit 99) `exit 99`\r\n\t\u0000Unicode: \u00f1\ud83d\ude80\n  ";
  process.stdout.write(JSON.stringify({ prompt: text, context: text }));
' | bash "$SCRIPT_DIR/measure.sh" | node -e '
  const assert = require("node:assert/strict");
  const fs = require("node:fs");
  const payload = JSON.parse(fs.readFileSync(0, "utf8"));
  const text = "  Quotes: \"\u0027; backslash: \\; shell: $HOME $(exit 99) `exit 99`\r\n\t\u0000Unicode: \u00f1\ud83d\ude80\n  ";
  assert.deepEqual(payload, {
    model: "jev-latest", state: { prompt: text, context: text },
    questions: JSON.parse(fs.readFileSync(process.argv[1], "utf8"))
  });
' "$SCRIPT_DIR/../assets/questions.json"

printf '%s' '{"prompt":"test"}' | bash "$SCRIPT_DIR/measure.sh" | node -e '
  require("node:assert/strict").equal(JSON.parse(require("node:fs").readFileSync(0, "utf8")).state.context, "");
'
for input in '{' 'null' '{}' '{"prompt":" "}' '{"prompt":42}' '{"prompt":"test","context":null}'; do
  if printf '%s' "$input" | bash "$SCRIPT_DIR/measure.sh" >/dev/null 2>&1; then
    echo "Expected invalid input to fail: $input" >&2
    exit 1
  fi
done
for failure in http network; do
  if printf '%s' '{"prompt":"test"}' | FETCH_FAILURE="$failure" bash "$SCRIPT_DIR/measure.sh" >/dev/null 2>&1; then
    echo "Expected $failure failure to exit nonzero" >&2
    exit 1
  fi
done

TEST_ROOT="$(mktemp -d)"
TEST_SKILL="$TEST_ROOT/.agents/skills/jev-prompt-enhancer"
TEST_WORKSPACE="$TEST_ROOT/workspace"
trap 'rm -f -- "$TEST_ROOT/.env" "$TEST_WORKSPACE/.env" "$TEST_WORKSPACE/marker" "$TEST_SKILL/scripts/measure.sh" "$TEST_SKILL/assets/questions.json"; rmdir -- "$TEST_WORKSPACE" "$TEST_SKILL/scripts" "$TEST_SKILL/assets" "$TEST_SKILL" "$TEST_ROOT/.agents/skills" "$TEST_ROOT/.agents" "$TEST_ROOT"' EXIT
mkdir -p "$TEST_SKILL/scripts" "$TEST_SKILL/assets" "$TEST_WORKSPACE"
cp "$SCRIPT_DIR/measure.sh" "$TEST_SKILL/scripts/measure.sh"
cp "$SCRIPT_DIR/../assets/questions.json" "$TEST_SKILL/assets/questions.json"
(
  cd "$TEST_WORKSPACE"
  unset JEV_API_KEY
  # A shared installation must not read the .env above its own directory.
  printf 'JEV_API_KEY=wrong-project\n' > "$TEST_ROOT/.env"
  if printf '%s' '{"prompt":"test"}' | bash "$TEST_SKILL/scripts/measure.sh" >/dev/null 2>&1; then
    echo 'Expected missing API key to fail' >&2
    exit 1
  fi
  printf '# Test Windows line endings and quoted values\r\nexport JEV_API_KEY="test"\r\n' > .env
  printf '%s' '{"prompt":"test"}' | bash "$TEST_SKILL/scripts/measure.sh" >/dev/null
  printf '%s' '{"prompt":"test"}' | JEV_API_KEY= bash "$TEST_SKILL/scripts/measure.sh" >/dev/null
  printf '%s' '{"prompt":"test"}' | JEV_ENV_FILE="$TEST_WORKSPACE/.env" bash -c 'cd "$1"; bash scripts/measure.sh' -- "$TEST_SKILL" >/dev/null
  printf 'JEV_API_KEY=from-file\n' > .env
  printf '%s' '{"prompt":"test"}' | JEV_API_KEY=test bash "$TEST_SKILL/scripts/measure.sh" >/dev/null
  printf 'JEV_API_KEY=\n' > .env
  if printf '%s' '{"prompt":"test"}' | bash "$TEST_SKILL/scripts/measure.sh" >/dev/null 2>&1; then
    echo 'Expected empty API key to fail' >&2
    exit 1
  fi
  for assignment in 'JEV_API_KEY=test' "JEV_API_KEY='test'" '  export JEV_API_KEY = "test" # comment'; do
    printf '%s\n' 'echo contaminated' 'touch marker' 'UNRELATED=$(touch marker)' "$assignment" > .env
    printf '%s' '{"prompt":"test"}' | bash "$TEST_SKILL/scripts/measure.sh" | node -e '
      JSON.parse(require("node:fs").readFileSync(0, "utf8"));
    '
    [[ ! -e marker ]]
  done
  # Shell expansions inside the key remain literal, too.
  printf '%s\n' 'JEV_API_KEY="$(touch marker)`touch marker`$HOME"' > .env
  printf '%s' '{"prompt":"test"}' | EXPECTED_KEY='$(touch marker)`touch marker`$HOME' bash "$TEST_SKILL/scripts/measure.sh" >/dev/null
  [[ ! -e marker ]]
)
echo 'measure.sh checks passed'
