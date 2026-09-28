# Prompt best practices
## Preserve intent

- Keep the user's facts, goals, requirements, and requested deliverables intact.
- Clarify using supplied context. Never invent a budget, deadline, audience, tool, or extra deliverable.
- If an essential detail cannot be inferred, ask a focused question instead of presenting a guess as a requirement.
- Choose the smallest useful revision; do not paste this entire checklist into the prompt.

## Task definition

- State the action and desired result directly: summarize, compare, extract, explain, or implement.
- Define what successful completion means using the user's stated goal.
- Split a complex task into a few ordered steps when dependencies matter. Avoid a forced process for a simple request. [Accuracy optimization](https://developers.openai.com/api/docs/guides/optimizing-llm-accuracy)

## Context

- Include relevant inputs, background, and audience when known.
- Supply reference material for private, current, or specialized facts; more wording cannot replace missing information.
- Separate instructions from source text with headings, fenced blocks, or XML tags. Label what each block contains. [Prompt engineering](https://developers.openai.com/api/docs/guides/prompt-engineering)

## Constraints

- Make existing limits explicit: scope, exclusions, budget, length, language, or tools.
- Replace vague goals such as "high quality" with concrete success criteria supported by the request.
- Resolve conflicting instructions using the user's stated priorities; ask if the conflict changes the intended result. [Reasoning best practices](https://developers.openai.com/api/docs/guides/reasoning-best-practices)

## Output definition

- Specify the requested format: prose, bullets, table, code, or JSON.
- State required sections or fields and the desired detail level when known.
- Add a small output example only if the format would otherwise be ambiguous. Keep examples consistent with the instructions.

## Examples and reasoning

- Start with direct instructions; add representative input/output examples only when they help explain a difficult pattern or format.

## Revise and check

- Fix the weakness Jev identified first; remove repetition and contradictions.
- Compare the revision with the original: no lost requirements, invented facts, or additional work.
- Remeasure within the skill's attempt limit and keep the highest-scoring eligible prompt according to `SKILL.md`.
- Treat Jev's score as a prompt-quality signal, not proof that the eventual answer is correct.
