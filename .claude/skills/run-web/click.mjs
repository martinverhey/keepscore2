// Clicks a point on the already-open CDP target and screenshots the result.
// Reuses the existing page — does NOT open or close a target, so it can
// follow a screenshot.mjs run and continue the same session (screenshot.mjs
// closes its own target when it's done, so it can't be chained directly).
//
//   node click.mjs <x> <y> <out.png> [waitMs] [width] [height]
//
// x/y are CSS pixels (the viewport size passed to Emulation.setDeviceMetricsOverride),
// NOT the device pixels you'd measure off a screenshot PNG — see the trap
// this exists to avoid, documented in SKILL.md.
//
// Requires Chrome already listening on --remote-debugging-port (CDP_PORT env,
// default 9333) with an open page target at the app (not about:blank).

import { writeFileSync } from 'node:fs';

const [, , x, y, out, waitMs = '4000', width = '440', height = '900'] = process.argv;
const PORT = process.env.CDP_PORT || '9333';

const targets = await (await fetch(`http://localhost:${PORT}/json/list`)).json();
const target = targets.find((t) => t.type === 'page' && t.url !== 'about:blank');

const ws = new WebSocket(target.webSocketDebuggerUrl);
const pending = new Map();
let id = 0;
const send = (method, params = {}) =>
  new Promise((resolve) => {
    pending.set(++id, resolve);
    ws.send(JSON.stringify({ id, method, params }));
  });
ws.addEventListener('message', (event) => {
  const message = JSON.parse(event.data);
  if (message.id && pending.has(message.id)) {
    pending.get(message.id)(message.result);
    pending.delete(message.id);
  }
});

await new Promise((resolve) => ws.addEventListener('open', resolve));

// Re-assert the same viewport the page was screenshotted at — the override
// is per-session, not per-target, so a fresh WebSocket connection to the same
// tab starts without it even though the tab's layout hasn't changed.
await send('Emulation.setDeviceMetricsOverride', {
  width: +width,
  height: +height,
  deviceScaleFactor: 2,
  mobile: false,
});

await send('Input.dispatchMouseEvent', {
  type: 'mousePressed',
  x: +x,
  y: +y,
  button: 'left',
  clickCount: 1,
});
await send('Input.dispatchMouseEvent', {
  type: 'mouseReleased',
  x: +x,
  y: +y,
  button: 'left',
  clickCount: 1,
});

await new Promise((resolve) => setTimeout(resolve, +waitMs));

const { data } = await send('Page.captureScreenshot', { format: 'png' });
writeFileSync(out, Buffer.from(data, 'base64'));
console.log('wrote', out);

ws.close();
