# Triage Labels

Five canonical state roles. Applied as values in the `labels:` frontmatter field of `.scratch/` issue files.

| Role | Label string |
|------|-------------|
| needs evaluation | `needs-triage` |
| waiting on reporter | `needs-info` |
| agent-ready | `ready-for-agent` |
| human-ready | `ready-for-human` |
| closed no-action | `wontfix` |

State machine: unlabeled -> `needs-triage` -> `needs-info` | `ready-for-agent` | `ready-for-human` | `wontfix`. `needs-info` returns to `needs-triage` once reporter replies.
