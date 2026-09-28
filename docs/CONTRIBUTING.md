# Contributing

Use Bash and Node.js 18 or newer; on Windows, use Git Bash. There are no npm
dependencies. Set `JEV_API_KEY` in the agent environment or the working project's
`.env` for real requests. Run from that project root or set `JEV_ENV_FILE` to its
absolute `.env` path. The script parses literal key assignments when the
environment key is missing or empty; it never executes `.env` as shell code.

The implementation lives in `skills/jev-enhancer/`: `SKILL.md` defines
the workflow, `scripts/measure.sh` calls Jev, and `assets/questions.json` holds
the scoring questions. Keep the implementation small and preserve user intent.

Pass a JSON object containing `prompt` and optional `context` through stdin.
Preserve input text, validate input before sending it, and keep credentials
out of logs and errors. The agent interprets the raw response and handles revisions.

Run `npm test` before submitting changes. The existing Bash checks mock fetch
and cover request serialization, invalid input, and HTTP/network failures.
Keep checks alongside the measurement script. Never commit real tokens,
`.env`, `node_modules`, or enhancement logs.
