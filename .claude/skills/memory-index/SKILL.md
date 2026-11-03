---
name: memory-index
description: Use when starting a work session, making a design or architecture decision, finishing a milestone, or when asked what was decided. Reads the compact docs/memory index first, loads only relevant topic files, and updates the index after every major task.
---

# Memory Index Protocol

GameCreateStudio uses a small resident index plus on-demand topic files, the same
progressive-disclosure idea as skills. The index is cheap to load; details are read
only when the task matches.

## Paths

- Studio index: `docs/memory/MEMORY.md`
- Studio topic files: `docs/memory/studio/`, `decisions/`, `sessions/`
- Game index: `games/<slug>/docs/memory/MEMORY.md`
- Game topic files: `games/<slug>/docs/memory/`

## Read order

1. Read the studio index first.
2. If the task touches a game, read that game's index next.
3. Load only files whose `load_when` matches the task. Do not read the whole
   memory tree.
4. Prefer the linked source of truth (GDD, setup doc, ADR) over a memory summary
   when they disagree.

## File format

Every memory file starts with frontmatter:

```yaml
---
name: short-kebab-case
description: one-line summary used for recall
type: studio | system | content | decision | session | reference
status: active | superseded | archived
updated: YYYY-MM-DD
load_when: when this file is relevant
---
```

One fact or decision per file. Link related files with relative markdown links.
Never store secrets, credentials, or large logs.

## Write rules

- Add one line to the index for each new memory: hook plus when to load it.
- Keep the index under 8 KB. Archive stale entries instead of letting the index grow.
- A stable design or architecture decision becomes an ADR in `decisions/` and is
  linked from the index.
- When a decision changes gameplay, update the GDD first, then the memory line.
  Memory points to the GDD; it does not duplicate it.
- After every major task or milestone, write a session summary and update the index:
  - Studio task: `docs/memory/sessions/YYYY-MM-DD-<topic>.md`
  - Game task: `games/<slug>/docs/memory/sessions/YYYY-MM-DD-<topic>.md`

## Major-task checklist

Before reporting a major task as done:

- [ ] Session summary written.
- [ ] Index updated with new or changed entries.
- [ ] Durable decisions promoted to an ADR.
- [ ] Links checked; stale entries archived.
- [ ] No secrets or large logs stored.

## What counts as a major task

A milestone, a completed system, a toolchain change, a batch of skills installed,
a GDD decision, or anything the user will expect to remember next session. Tiny
edits do not need a session file, but they may still update an existing memory.
