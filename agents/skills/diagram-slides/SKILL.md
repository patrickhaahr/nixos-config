---
name: diagram-slides
description: Build an HTML slide deck whose diagrams come from diagram-design, inlined as SVG, with each diagram also saved as a standalone .svg.
disable-model-invocation: true
---

This skill joins two manual-only skills, so the Skill tool refuses them: read `~/.agents/skills/frontend-slides/SKILL.md` and `~/.agents/skills/diagram-design/SKILL.md` in full before step 1. `<dd>` below means `~/.agents/skills/diagram-design`.

1. **Plan the deck.** Run frontend-slides Phase 1 and Phase 2 as written. In the outline, mark each slide that carries a diagram with its diagram-design visual type and a slug. Done when the user has picked a style and every diagram slide has a type and slug.
2. **Draw each diagram.** Follow diagram-design for each marked slide, with these answers fixed:
   - Style guide gate: the user chose **(e) keep default**. Use the shipped default tokens and ask nothing.
   - Size preset: `slide-16x9`. Format: `html`.
   - Confirm before drawing: fold every diagram's type and planned cuts into one message with the deck outline, not one message per diagram.

   Write each to `diagrams/<slug>.html` next to the deck. Done when every diagram passes the diagram-design §9 checklist and `python3 <dd>/scripts/self_check.py diagrams/<slug>.html`.
3. **Export the SVGs.** For each diagram run `python3 <dd>/scripts/export_svg.py diagrams/<slug>.html diagrams/<slug>.svg`. The export carries the diagram's CSS and prefixes its IDs, so the file works on its own and several can share one page. Done when every diagram has a `.svg` beside its `.html`.
4. **Build the deck.** Run frontend-slides Phase 3. Paste each exported `<svg>…</svg>` inline into its slide, without the `<?xml …?>` line; an `<img>` or `<object>` pointing at the file loses the fonts and carried CSS. Inside the fixed 1920×1080 stage the stage scales as a whole, so give the SVG `width: 100%` of its slot and drop the `min-width` and scrolling wrapper from the diagram-design output spec. Done when frontend-slides' rendered-screenshot checks pass and every diagram label is readable at 1280×720.

Report the deck path and the `diagrams/` folder holding each `<slug>.html` and `<slug>.svg`.
