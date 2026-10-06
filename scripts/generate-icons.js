#!/usr/bin/env node
// Icon generator for gameblast — committed with the repo ON PURPOSE (never lose
// the generator; regenerating must always be one command). Pure Node, zero deps
// (PNG encoding via node:zlib). Run: node scripts/generate-icons.js
//
// Colors are derived deterministically from the slug so every project gets its
// own identity out of the box. To pick your own, hardcode BG / ACCENT below and
// re-run. Replace the mark (drawMark) when the real brand exists — keep the
// output contract (file list below) intact.

const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');

const SLUG = 'gameblast';
// Dev-install icon background (the dev-prod-variant pattern): loud on purpose
// so the dev and production installs are unmistakable on a launcher.
const DEV_COLOR = '#FF1493';

// ---------------------------------------------------------------- colors

function hashHue(s) {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0;
  return h % 360;
}

function hslToRgb(h, s, l) {
  const a = s * Math.min(l, 1 - l);
  const f = (n) => {
    const k = (n + h / 30) % 12;
    return Math.round(255 * (l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1))));
  };
  return [f(0), f(8), f(4)];
}

function hexToRgb(hex) {
  const m = /^#?([0-9a-f]{6})$/i.exec(hex);
  if (!m) return [255, 20, 147];
  const n = parseInt(m[1], 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}
const toHex = (rgb) => '#' + rgb.map((c) => c.toString(16).padStart(2, '0')).join('').toUpperCase();

const HUE = hashHue(SLUG);
const BG = hslToRgb(HUE, 0.45, 0.2); // deep background
const ACCENT = hslToRgb(HUE, 0.7, 0.62); // bright mark
const WHITE = [255, 255, 255];
const DEV_BG = hexToRgb(DEV_COLOR);

// ---------------------------------------------------------------- png encoder

const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}

// pixels: Uint8Array RGBA, length = w * h * 4
function encodePng(w, h, pixels) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // color type RGBA
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) {
    const rowStart = y * (w * 4 + 1);
    raw[rowStart] = 0; // filter: none
    raw.set(pixels.subarray(y * w * 4, (y + 1) * w * 4), rowStart + 1);
  }
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

// ---------------------------------------------------------------- drawing

// Analytic anti-aliasing via signed distance: coverage 1 inside, 0 outside,
// smooth over ~1px at the edge.
const coverage = (d) => Math.max(0, Math.min(1, 0.5 - d));

function makeCanvas(w, h, bg) {
  const px = new Uint8Array(w * h * 4);
  if (bg) {
    for (let i = 0; i < w * h; i++) {
      px[i * 4] = bg[0];
      px[i * 4 + 1] = bg[1];
      px[i * 4 + 2] = bg[2];
      px[i * 4 + 3] = 255;
    }
  }
  return px;
}

function blendLayer(px, w, h, color, sdf) {
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const a = coverage(sdf(x + 0.5, y + 0.5));
      if (a <= 0) continue;
      const i = (y * w + x) * 4;
      const outA = a + (px[i + 3] / 255) * (1 - a);
      for (let c = 0; c < 3; c++) {
        px[i + c] = Math.round(color[c] * a + px[i + c] * (1 - a));
      }
      px[i + 3] = Math.round(outA * 255);
    }
  }
}

const diamond = (cx, cy, r) => (x, y) => Math.abs(x - cx) + Math.abs(y - cy) - r;
const disc = (cx, cy, r) => (x, y) => Math.hypot(x - cx, y - cy) - r;

// The default mark: a diamond with a punched disc — geometric, legible at 48px,
// and clearly a placeholder for the real brand.
function render(w, h, { bg, mark, hole, unitRatio }) {
  const px = makeCanvas(w, h, bg);
  const unit = Math.min(w, h) * unitRatio;
  blendLayer(px, w, h, mark, diamond(w / 2, h / 2, unit));
  if (hole) blendLayer(px, w, h, hole, disc(w / 2, h / 2, unit * 0.38));
  return encodePng(w, h, px);
}

// ---------------------------------------------------------------- outputs

function write(file, buf) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, buf);
  console.log(`  wrote ${file}`);
}

function readAppJsonPaths(mobileDir) {
  // Resolve icon paths from app.json when possible so this keeps working across
  // Expo SDK template changes; fall back to the standard names.
  const fallback = {
    icon: 'assets/images/icon.png',
    foreground: 'assets/images/android-icon-foreground.png',
    background: 'assets/images/android-icon-background.png',
    monochrome: 'assets/images/android-icon-monochrome.png',
    splash: 'assets/images/splash-icon.png',
    favicon: 'assets/images/favicon.png',
  };
  try {
    const appJson = JSON.parse(fs.readFileSync(path.join(mobileDir, 'app.json'), 'utf8'));
    const expo = appJson.expo ?? {};
    const adaptive = (expo.android && expo.android.adaptiveIcon) || {};
    const splashPlugin = (expo.plugins || []).find((p) => Array.isArray(p) && p[0] === 'expo-splash-screen');
    const clean = (p, fb) => (typeof p === 'string' && !p.endsWith('.icon') ? p.replace(/^\.\//, '') : fb);
    return {
      icon: clean(expo.icon && expo.icon.image ? expo.icon.image : expo.icon, fallback.icon),
      foreground: clean(adaptive.foregroundImage, fallback.foreground),
      background: clean(adaptive.backgroundImage, fallback.background),
      monochrome: clean(adaptive.monochromeImage, fallback.monochrome),
      splash: clean(splashPlugin && splashPlugin[1] && splashPlugin[1].image, fallback.splash),
      favicon: clean(expo.web && expo.web.favicon, fallback.favicon),
    };
  } catch {
    return fallback;
  }
}

console.log(`generate-icons: ${SLUG} (hue ${HUE})`);

const root = path.resolve(__dirname, '..');
const mobileDir = path.join(root, 'mobile');
const androidRes = path.join(mobileDir, 'android', 'app', 'src', 'main', 'res');
const iosAssets = path.join(mobileDir, 'ios', 'Sources', 'Assets.xcassets');

const nativeLayout = fs.existsSync(androidRes) || fs.existsSync(iosAssets);

// ---- Expo layout (or a bare mobile stub): mobile/app.json + assets/images/*
if (fs.existsSync(mobileDir) && !nativeLayout) {
  const p = readAppJsonPaths(mobileDir);
  const out = (rel) => path.join(mobileDir, rel);
  // Full-bleed app icon.
  write(out(p.icon), render(1024, 1024, { bg: BG, mark: ACCENT, hole: BG, unitRatio: 0.34 }));
  // Adaptive triple: solid background; smaller foreground mark (launcher mask
  // safe zone: keep the mark inside the middle ~66%); white monochrome for
  // Android themed icons.
  write(out(p.background), render(1024, 1024, { bg: BG, mark: BG, hole: null, unitRatio: 0 }));
  write(out(p.foreground), render(1024, 1024, { bg: null, mark: ACCENT, hole: BG, unitRatio: 0.24 }));
  write(out(p.monochrome), render(1024, 1024, { bg: null, mark: WHITE, hole: null, unitRatio: 0.24 }));
  // Splash mark on transparent — expo-splash-screen paints the background color.
  write(out(p.splash), render(1024, 1024, { bg: null, mark: ACCENT, hole: BG, unitRatio: 0.28 }));
  write(out(p.favicon), render(48, 48, { bg: BG, mark: ACCENT, hole: BG, unitRatio: 0.36 }));
}

// ---- Native Android layout: adaptive-icon layers per density. The launcher
// XML (mipmap-anydpi-v26/ic_launcher.xml) references these by name; the
// background is a color resource so the dev flavor can override it.
if (fs.existsSync(androidRes)) {
  const densities = { mdpi: 108, hdpi: 162, xhdpi: 216, xxhdpi: 324, xxxhdpi: 432 };
  for (const [density, size] of Object.entries(densities)) {
    const dir = path.join(androidRes, `mipmap-${density}`);
    write(path.join(dir, 'ic_launcher_foreground.png'), render(size, size, { bg: null, mark: ACCENT, hole: BG, unitRatio: 0.24 }));
    write(path.join(dir, 'ic_launcher_monochrome.png'), render(size, size, { bg: null, mark: WHITE, hole: null, unitRatio: 0.24 }));
  }
  fs.mkdirSync(path.join(androidRes, 'values'), { recursive: true });
  write(
    path.join(androidRes, 'values', 'ic_launcher_background.xml'),
    Buffer.from(
      `<?xml version="1.0" encoding="utf-8"?>\n<!-- Generated by scripts/generate-icons.js — edit BG there, not here. -->\n<resources>\n    <color name="ic_launcher_background">${toHex(BG)}</color>\n</resources>\n`
    )
  );
}

// ---- Native iOS layout: single-size 1024 app icons (Xcode 14+). AppIcon-Dev is
// the Debug configuration's icon (dev-colored field, same mark).
if (fs.existsSync(iosAssets)) {
  write(path.join(iosAssets, 'AppIcon.appiconset', 'icon-1024.png'), render(1024, 1024, { bg: BG, mark: ACCENT, hole: BG, unitRatio: 0.34 }));
  write(path.join(iosAssets, 'AppIcon-Dev.appiconset', 'icon-1024.png'), render(1024, 1024, { bg: DEV_BG, mark: WHITE, hole: DEV_BG, unitRatio: 0.34 }));
}

// GitHub social preview (Settings -> General -> Social preview). 1280x640.
// No API exists for uploading it - drag this file in once.
write(path.join(root, 'assets', 'github-social-preview.png'), render(1280, 640, { bg: BG, mark: ACCENT, hole: BG, unitRatio: 0.28 }));

console.log('done.');
