---
name: jev-prompt-enhancer
description: Evaluate and improve a prompt using Jev.
disable-model-invocation: true
---

# Enhance your prompts using Jev

Give your coding agent a clearer task before it writes the first line. Jev evaluates your prompt and pinpoints where the task, context, constraints, or expected output need more clarity. This skill uses that feedback to sharpen your instructions, then continues with the work you asked for.

For developers, the payoff is less room for guesswork and fewer rounds of "that's not what I meant." Whether you're fixing a bug, building a feature, or requesting a code review, Jev helps turn your intent into actionable instructions while preserving your requirements and scope.

## The loop

**Measure, refine, recheck, then build.** The skill sends your prompt to Jev for a quality score and focused feedback. If the score falls below the target, it revises the prompt to address the identified weakness and measures it again.

The loop stops when the prompt reaches 80/100 by default, or a threshold you specify, or when all three enhancement attempts are used. At the limit, it selects the highest-scoring prompt. You see the resulting prompt, and your agent continues with your task.

### REQUIREMENTS

Bash and Node.js 18+ must be available.

`JEV_API_KEY` must be set to a nonempty value in the agent's process environment or the working project's `.env` file.

- If it is missing or empty in both places, explain how to set it in `.env` or the environment that launches the agent: `export JEV_API_KEY='your-api-key'` in Bash or `$env:JEV_API_KEY = 'your-api-key'` in PowerShell, then launch the agent from that shell. If configuring it through the agent application's environment settings, restart the agent afterward.
- `scripts/measure.sh` reads `.env` from the current working directory when the environment key is missing or empty. To select a file explicitly, set `JEV_ENV_FILE` to its absolute path. Only literal, single-line `JEV_API_KEY` assignments are read: unquoted values without whitespace, single- or double-quoted values, optional `export`, and trailing `#` comments. Shell commands, variable expansion, and escape processing are never executed. A nonempty environment key takes precedence. Never ask the user to paste their key into chat or print it when checking availability.

If any requirement is missing (Bash, Node.js 18+, or a nonempty `JEV_API_KEY`), report what is missing and how to install or configure it, and stop. Do not call Jev, enhance the prompt, or continue the requested workflow with the original prompt. Resume only after the requirements are satisfied.

#### EVERY TIME this skill is invoked, you MUST continue with the following enumerated instruction, in order. The main prompt will be enhanced and modified before letting you continue with your normal process.

1. Read the user prompt.
2. Verify that Bash is available and Node.js is version 18 or newer. Let `scripts/measure.sh` validate `JEV_API_KEY` after loading `.env`; do not reject a missing process-environment key before the script can load it. If any requirement check fails, follow the requirements guidance above and abort. If not:

```md
**/jev-prompt-enhancer ❯ processing prompt**
```

3. Build a JSON object containing only `prompt` and optional `context` (a string, defaulting to `""`). Use `JSON.stringify` to encode text read from files or stdin; do not interpolate prompt text into JavaScript or manually escape JSON.
4. From the working project root, pass that object through stdin to `bash /absolute/path/to/jev-prompt-enhancer/scripts/measure.sh`, using the actual installed skill path. This also works for shared installations outside the project. If invoking from another directory, set `JEV_ENV_FILE` to the working project's absolute `.env` path. Use a file redirect or a quoted heredoc (`<<'JSON'`) so the shell does not expand prompt content. Do not pass prompt or context as command-line arguments.
5. If the quality is below the threshold and attempts remain, read the prompting reference as directed under "Low-score guidance" below, improve the prompt based on the script's feedback, and call it again with the improved prompt.

```md
**/jev-prompt-enhancer ❯❯ enhancing prompt**
```

6. Output the result to the user:

```md
## Enhanced prompt: << new enhanced prompt >>

**/jev-prompt-enhancer ❯❯❯ proceeding with your task**
```

7. Continue the user requested workflow with your improved prompt.

Example (from the working project root; replace the script path with its installed location):

```sh
bash /absolute/path/to/jev-prompt-enhancer/scripts/measure.sh <<'JSON'
{
  "prompt": "Plan the paper...",
  "context": "Scientific paper about..."
}
JSON
```

## Reading the response

- The script returns Jev's raw JSON response. Read `answers.prompt_quality.score` (0–2); multiply by 50 for a score out of 100. Use 80 as the threshold unless the user specifies another.
- Read `answers.primary_improvement.choice`: focus on `task_definition`, `context`, `constraints`, or `output_definition`. `no_major_improvement` means no specific change was identified; if the score is still low, review those areas yourself.
- At or above the threshold, continue with the task. Otherwise, revise without inventing requirements and measure again, respecting _MAX_ENHANCEMENT_ATTEMPTS_.
- If the script fails because a requirement is missing, follow the requirements guidance above and abort. For other script failures or missing or invalid expected answers, report the issue and continue with the original prompt; do not invent a score.

# ENHANCEMENT

## Low-score guidance

After a valid score below the threshold, read [Prompt best practices](references/prompt-best-practices.md) before revising. Start with "Preserve intent" and the section matching `answers.primary_improvement.choice`:

- `task_definition`: [Task definition](references/prompt-best-practices.md#task-definition).
- `context`: [Context](references/prompt-best-practices.md#context).
- `constraints`: [Constraints](references/prompt-best-practices.md#constraints).
- `output_definition`: [Output definition](references/prompt-best-practices.md#output-definition).
- `no_major_improvement` with a low score: review all four areas and fix the clearest weakness.

Use "Examples and reasoning" only when relevant, then follow "Revise and check" before remeasuring. Apply only tips that address the request; do not expand its scope to improve the score. This reference is not needed when the score meets the threshold, the script fails, or no attempts remain; follow the existing stop/fallback rules.

When enhancing the prompt, focus on wording, phrasing, best prompt engineering practices, adding more context, and treat
the initial user prompt as critical information. No user information must be lost in this process -- instead, this process
should enhance and improve the engineering quality of any prompt the user has given.
The final outcome should be a prompt that is better suit for what the user is trying to acchieve. The improved prompt should NOT generate new artifacts or undesired results that the user didn't expect.

# IMPORTANT

- The maximum enhancements attempts you are allowed to execute is _MAX_ENHANCEMENT_ATTEMPTS_. Once reached, you must use the prompt with the highest score. Default to the user prompt.
- If the user prompt is extremely vague, it lacks meaning or actionable purpose, and you lack context to understand _how_ to actually enhance, abort the process
  and give the feedback to the user (i.e "hello" -> this is not something you can 'improve').

# RULES

_MAX_ENHANCEMENT_ATTEMPTS_: 3
