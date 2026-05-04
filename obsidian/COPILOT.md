# Copilot Instructions for barco-labs vault

## Task Management

This vault uses the Obsidian Tasks plugin for task tracking.

### Task file

All tasks live in `TODO.md` at the vault root. This is the single source of truth.
`Dashboard.md` is a read-only live overview rendered by Obsidian — do not edit it directly.

### Task format

- [ ] Task description PRIORITY 📅 YYYY-MM-DD #context

Priority symbols (include at most one):
| Symbol | Priority |
|--------|----------|
| 🔺 | Highest |
| ⏫ | High |
| 🔼 | Medium |
| (none) | Normal |
| 🔽 | Low |

Due date: `📅 YYYY-MM-DD` (use the calendar emoji exactly)
Context tag: `#work` (add `#personal` for personal tasks when needed)

### Adding a task

Append to the end of `TODO.md`:

- [ ] Task description ⏫ 📅 2026-04-20 #work

### Completing a task

Replace `- [ ]` with `- [x]` and append `✅ YYYY-MM-DD` (today's date) after the task text:

- [x] Task description ⏫ 📅 2026-04-20 #work ✅ 2026-04-20

### Giving an overview

Read `TODO.md` and summarize:
1. Overdue tasks (past due date, not done)
2. Due today
3. Due this week
4. All other open tasks

Report counts and list each task with its priority and due date.

## Vault Structure

**barco-labs** is a work-only vault for the Barco Labs business unit. There is currently one vault; additional vaults may be created in the future for other employers or personal use.

```
barco-labs/
├── TODO.md           — task management (single source of truth)
├── Dashboard.md      — read-only task overview, do not edit
├── Meetings/         — meeting notes, named YYYY-MM-DD Topic.md
├── Projects/         — one subfolder per project, each with index.md
├── Knowledge/        — internal wiki: how-tos, processes, runbooks
└── Resources/        — tools, links, external references
```

### Placing new content

- **Meeting notes** → `Meetings/YYYY-MM-DD Topic.md`
- **Project docs** → `Projects/<project-name>/` (create subfolder + `index.md` if new)
- **How-tos / processes / reference** → `Knowledge/`
- **Tools / links / external refs** → `Resources/`

When unsure, ask the user. Structure can evolve — propose changes to the user before reorganising existing content.
