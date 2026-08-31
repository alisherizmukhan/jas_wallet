// Renders the native splash logos from assets/logo.svg (vector -> crisp PNG).
//
// Produces two files consumed by flutter_native_splash.yaml:
//   assets/logo_splash.png            560x505  - main splash (Android <12, iOS, Web)
//   assets/logo_splash_android12.png  1152x1152 - padded logo for Android 12+ circle
//
// Requires the `sharp` package:  npm install sharp
// Run:  node tool/render_splash_logos.js
// Then: dart run flutter_native_splash:create   (and flutter clean + reinstall)
const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const svg = fs.readFileSync(path.join(ROOT, 'assets/logo.svg'));

// logo.svg native size is 317x286.
const ASPECT = 317 / 286;

async function main() {
  // 1) Main splash image. flutter_native_splash treats the source as a 4x
  //    asset (displayed dp = source/4). Welcome page renders the logo at
  //    140dp wide, so source width = 140 * 4 = 560.
  const mainW = 560;
  const mainH = Math.round(mainW / ASPECT); // 505
  await sharp(svg, { density: 600 })
    .resize(mainW, mainH, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toFile(path.join(ROOT, 'assets/logo_splash.png'));
  console.log(`logo_splash.png  ${mainW}x${mainH}`);

  // 2) Android 12+ padded version. Android masks the splash icon to a circle,
  //    so the full logo must fit inside the ~768px safe zone of a 1152 canvas.
  const canvas = 1152;
  const logoW = 700;
  const logoH = Math.round(logoW / ASPECT); // 632
  const logoBuf = await sharp(svg, { density: 600 })
    .resize(logoW, logoH, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toBuffer();
  await sharp({
    create: { width: canvas, height: canvas, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
  })
    .composite([{ input: logoBuf, gravity: 'centre' }])
    .png()
    .toFile(path.join(ROOT, 'assets/logo_splash_android12.png'));
  console.log(`logo_splash_android12.png  ${canvas}x${canvas} (logo ${logoW}x${logoH})`);
}

main();
