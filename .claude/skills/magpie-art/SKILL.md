---
name: magpie-art
description: Use when creating concept art, style boards, sprite drafts, UI mockups, reference images, or short concept videos for GameCreateStudio. Bridges the create-game-assets art-direction workflow to the Magpie image and video MCP tools.
---

# Magpie Art

Magpie is the image/video generation tool for this studio. It is a production aid,
not a final-asset stamp: every generated image still goes through the art-direction
brief, normalization, and in-game validation.

## Tools

- `mcp__magpie-image__generate_image` — text-to-image or edit/combine with reference images.
- `mcp__magpie-image__generation_result` — wait for an async generation.
- `mcp__magpie-image__generate_video` — short concept or motion reference.

## Workflow

1. Read the `create-game-assets` skill and its `assets/art-direction-brief.md`.
   Lock view, target size, palette roles, shape language, silhouette, and output format.
2. Generate one hero asset or a small style board first (1–4 variants). Judge it at
   actual game scale against a gameplay background.
3. After the target is approved, produce families with the approved image as a
   reference input. Keep palette, view, proportions, lighting, and line weight fixed.
4. Save into the game's `assets/concept/` or `assets/sprites/` via the `path`
   argument. Never leave deliverables in the default `generated-images/` folder.
5. For sprites, request a transparent background where the model supports it, then
   verify the alpha channel; prompt wording alone does not guarantee transparency.
6. Normalize and QA with `create-game-assets` scripts or Pixelorama/Aseprite:
   exact size, frame count, pivot, alpha, palette, no clipped edges.
7. Record prompt, tool, date, model, and license/provenance in
   `assets/asset-manifest.json`.
8. Treat video output as concept/reference only unless the game explicitly uses
   pre-rendered video.

## Prompt blocks

Use the blocks from `create-game-assets`:

```text
ROLE/PURPOSE: production asset for [gameplay role]
SUBJECT: [specific object/character and action]
VIEW: [orthographic/top-down/side/three-quarter], [camera and facing]
ART DIRECTION: [shape language], [palette roles], [materials], [edge treatment]
GAME-SCALE READ: [silhouette and focal details that must survive at WxH]
TECHNICAL OUTPUT: [dimensions/aspect], [transparent or scene background], [frame/slot count]
LOCKS: preserve [identity, proportions, palette, costume, lighting, line weight]
EXCLUDE: text, labels, mockup frames, scenery, duplicate objects, cropped edges, signatures
```

## If Magpie is unavailable

Say so, fall back to greybox placeholders, and still write the brief and manifest.
Do not invent generated assets or claim an asset exists when it does not.
