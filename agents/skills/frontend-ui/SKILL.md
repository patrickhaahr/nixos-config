---
name: frontend-ui
description: Invoke when working on frontend UI or UX design.
---

Design work belongs to the `ui` specialist, which carries the design skills (accessibility, layout, typography, color, polish, copy, motion, interface reviews) and real-site references this session lacks.

- Hand it any task that designs, builds, restyles, animates or reviews an interface: in T3 Code, delegate to the provider instance `pi-ui` with the model pinned to `claude-opus-5-5`; elsewhere run `pi-ui -p "<brief>"`.
- A brief names the project path, the screens or components, the goal, and what done looks like. The specialist sees only the brief.
- Do code-level UI work yourself (state, data flow, a prop or a bug fix with no design decision), with `react-best-practices` for React.
- When `pi-ui` is not on PATH, work from the project's existing tokens and components, and say in your report that the design pass was skipped.

Before you report, open the specialist's screenshots and diff and check them against the brief.
