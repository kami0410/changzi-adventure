class_name UIPalette
extends RefCounted

## Colour roles for UI text, from docs/memory/decisions/2026-11-02-ui-direction.md.
## Modal windows are paper pages: dark ink text on aged paper. The HUD and
## in-world labels sit on ink: light bone/cyan text. Never mix the two sets.

# On paper (modal windows, menus, dialogue).
const INK := Color(0.106, 0.122, 0.141)
const INK_SOFT := Color(0.290, 0.290, 0.271)
const INK_FAINT := Color(0.420, 0.400, 0.360)
const CINNABAR := Color(0.659, 0.196, 0.180)
const SEAL_GOLD := Color(0.520, 0.380, 0.120)
const VERDIGRIS := Color(0.160, 0.420, 0.390)
const ABYSS := Color(0.380, 0.180, 0.470)

# On ink (HUD, world labels, title screen).
const BONE := Color(0.910, 0.882, 0.812)
const BONE_DIM := Color(0.620, 0.640, 0.640)
const CYAN := Color(0.561, 0.910, 0.863)
const GOLD := Color(0.847, 0.706, 0.416)
const DANGER := Color(0.930, 0.420, 0.360)

# Surfaces.
const INK_NIGHT := Color(0.051, 0.071, 0.094)
const PAPER := Color(0.788, 0.749, 0.651)
## Behind a modal page: the scene stays faintly visible, the HUD is hidden.
const SHADE := Color(0.051, 0.071, 0.094, 0.84)
