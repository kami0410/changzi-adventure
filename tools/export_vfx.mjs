#!/usr/bin/env node
// Exports the combat VFX the game uses from pixelfx (MIT, https://github.com/patch-gg/pixelfx,
// snapshot in the studio asset library) into assets/vfx/: one sprite sheet per effect, recoloured to
// the game palette, trailing empty frames trimmed, long effects stepped down, every frame cropped to
// the effect's shared bounds. assets/vfx/vfx_manifest.json describes each sheet for scripts/presentation/vfx.gd.
//
//   node tools/export_vfx.mjs "<path to pixelfx/upstream>"
//
// Deterministic: fixed seeds, fixed recipes.

import { writeFileSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const PXF = process.argv[2];
if (!PXF) {
  console.error("usage: node tools/export_vfx.mjs <pixelfx upstream dir>");
  process.exit(1);
}
const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const OUT = join(ROOT, "assets", "vfx");
const lib = await import(pathToFileURL(join(PXF, "tools", "lib", "fxlib.mjs")).href);
const { encodePNG } = await import(pathToFileURL(join(PXF, "tools", "lib", "png.mjs")).href);

// Game palette ramps (dark -> light), see docs/memory/decisions/2026-11-02-art-spec.md.
const TEAL = ["#0e2a2c", "#16494a", "#1f7a74", "#3fb4a6", "#8fe8dc", "#d8fff6", "#ffffff"];
const GOLD = ["#3a2208", "#6e4210", "#b0741e", "#e0a83a", "#f3cf87", "#fff1c8", "#ffffff"];
const BLOOD = ["#2a0608", "#5a1016", "#93222a", "#c8463e", "#f49287", "#ffd6cc", "#ffffff"];
const INK = ["#0b0f14", "#1d1630", "#352a58", "#5a4a8a", "#8f7fc0", "#d6ccf2", "#ffffff"];
const BONE = ["#1a1814", "#3a342c", "#6e6454", "#a89c84", "#d8ccb0", "#f2ead8", "#ffffff"];

// id: [pixelfx effect, palette or null (keep its own), max frames, frame step]
const RECIPES = {
  slash_light: ["melee/sword-slash", TEAL, 24, 1],
  slash_heavy: ["melee/heavy-cleave", GOLD, 30, 1],
  slash_spin: ["melee/spin-slash", GOLD, 25, 1],
  smash: ["melee/hammer-smash", BONE, 34, 1],
  whip: ["melee/whip-crack", BLOOD, 27, 1],
  flurry: ["melee/dagger-flurry", TEAL, 30, 1],
  thrust: ["melee/thrust", TEAL, 24, 1],
  claw: ["melee/claw-swipe", BLOOD, 28, 1],
  hit_spark: ["impacts/hit-spark", TEAL, 16, 1],
  hit_crit: ["impacts/crit-hit", GOLD, 28, 1],
  hit_blunt: ["impacts/blunt-hit", BONE, 28, 1],
  hit_player: ["impacts/hit-flash", BLOOD, 16, 1],
  parry: ["impacts/parry", GOLD, 31, 1],
  land_heavy: ["impacts/heavy-landing", BONE, 30, 1],
  enemy_die: ["spawn/poof", INK, 49, 1],
  elite_die: ["explosions/implosion", GOLD, 70, 2],
  boss_die: ["shadow/dark-explosion", BLOOD, 115, 2],
  enemy_spawn: ["spawn/summon-rise", INK, 60, 2],
  respawn: ["holy/holy-pillar", TEAL, 70, 2],
  soul_rise: ["spawn/soul-rise", TEAL, 97, 2],
  chest_open: ["pickups/collect-burst", GOLD, 40, 1],
  heal: ["holy/heal-aoe", TEAL, 60, 2],
  cast_circle: ["arcane/magic-circle-cast", TEAL, 50, 2],
  mana_burst: ["arcane/mana-burst", TEAL, 55, 2],
  spell_fire: ["explosions/small-explosion", null, 40, 1],
  spell_lightning: ["lightning/zap-hit", null, 28, 1],
  spell_ice: ["ice/frost-nova", null, 50, 2],
  spell_shadow: ["shadow/dark-explosion", INK, 80, 2],
  spell_holy: ["holy/smite", null, 60, 2],
  spell_poison: ["nature/acid-splash", null, 40, 1],
  status_burning: ["status/burning", null, 36, 1],
  status_slowed: ["status/slowed", INK, 72, 2],
  status_stunned: ["status/stunned", GOLD, 60, 2],
  status_poisoned: ["status/poisoned", null, 48, 1],
  boss_phase: ["lightning/thunderclap", BLOOD, 58, 1],
  // Creature loops used as enemy art (0.15 roster), recoloured to the chapter moods.
  creature_eye: ["critters/eyeball", BLOOD, 96, 2],
  creature_skull: ["critters/flying-skull", BONE, 72, 2],
  creature_wisp: ["critters/wisp", TEAL, 96, 2],
  creature_jelly: ["critters/jellyfish", ["#061a24", "#0c3a4a", "#156b78", "#2fb4b0", "#7ff0dc", "#d6fff4", "#ffffff"], 96, 2],
  creature_slime: ["critters/slime", INK, 54, 1],
  creature_snake: ["critters/snake", BLOOD, 72, 2],
  creature_bat: ["critters/bat", INK, 72, 2],
  creature_crow: ["critters/bird", BONE, 72, 2],
};

function alphaCount(rgba) {
  let n = 0;
  for (let i = 3; i < rgba.length; i += 4) if (rgba[i] > 8) n++;
  return n;
}

function bounds(frames, w, h) {
  let x0 = w, y0 = h, x1 = -1, y1 = -1;
  for (const f of frames) {
    const c = f.clear;
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
      if (c[(y * w + x) * 4 + 3] > 8) {
        if (x < x0) x0 = x; if (y < y0) y0 = y; if (x > x1) x1 = x; if (y > y1) y1 = y;
      }
    }
  }
  if (x1 < 0) return { x: 0, y: 0, w, h };
  const pad = 2;
  x0 = Math.max(0, x0 - pad); y0 = Math.max(0, y0 - pad);
  x1 = Math.min(w - 1, x1 + pad); y1 = Math.min(h - 1, y1 + pad);
  return { x: x0, y: y0, w: x1 - x0 + 1, h: y1 - y0 + 1 };
}

mkdirSync(OUT, { recursive: true });
const manifest = {
  source: "pixelfx 0.3.0 (MIT) - https://github.com/patch-gg/pixelfx; sim adapted from Sprite Fusion pixel-art VFX (MIT)",
  effects: {},
};
for (const [id, [fxId, palette, maxFrames, step]] of Object.entries(RECIPES)) {
  const fx = await lib.loadEffect(fxId, join(PXF, "src", "fx"));
  const options = palette ? { palette } : {};
  const r = lib.renderFrames(fx, { bg: "none", seed: 7, options });
  let frames = r.frames.slice(0, maxFrames);
  if (!fx.meta.loop) {
    const peak = Math.max(...frames.map((f) => alphaCount(f.clear)));
    while (frames.length > 6 && alphaCount(frames[frames.length - 1].clear) < peak * 0.02) frames.pop();
  }
  frames = frames.filter((_, i) => i % step === 0);
  const b = bounds(frames, r.w, r.h);
  const cols = Math.min(frames.length, Math.max(1, Math.ceil(Math.sqrt((frames.length * b.h) / b.w))));
  const rows = Math.ceil(frames.length / cols);
  const W = cols * b.w, H = rows * b.h;
  const sheet = new Uint8ClampedArray(W * H * 4);
  frames.forEach((f, i) => {
    const ox = (i % cols) * b.w, oy = Math.floor(i / cols) * b.h;
    for (let y = 0; y < b.h; y++) {
      const src = ((b.y + y) * r.w + b.x) * 4;
      sheet.set(f.clear.subarray(src, src + b.w * 4), ((oy + y) * W + ox) * 4);
    }
  });
  writeFileSync(join(OUT, `${id}.png`), encodePNG(W, H, sheet));
  const [px, py] = fx.meta.origin;
  manifest.effects[id] = {
    source: fxId,
    frames: frames.length,
    fps: r.fps / step,
    loop: !!fx.meta.loop,
    columns: cols,
    frame_size: [b.w, b.h],
    pivot: [px - b.x, py - b.y],
  };
  process.stdout.write(`${id} ${frames.length}f ${b.w}x${b.h}\n`);
}
writeFileSync(join(OUT, "vfx_manifest.json"), JSON.stringify(manifest, null, 1));
console.log(`${Object.keys(RECIPES).length} effects -> assets/vfx/`);
