// Screenshots the running web build over the Chrome DevTools Protocol.
//
//   node screenshot.mjs <url> <out.png> [waitMs] [width] [height]
//
// Requires Chrome already listening on --remote-debugging-port=9333.
// SCHEME=dark emulates prefers-color-scheme: dark.
//
// Do NOT reach for `chrome --screenshot --virtual-time-budget` instead: the
// virtual clock stalls Flutter's frame loop and every shot comes back as the
// splash spinner.

import { writeFileSync } from 'node:fs';

const [, , url, out, waitMs = '9000', width = '440', height = '900'] = process.argv;
const PORT = process.env.CDP_PORT || '9333';

const target = await (
  await fetch(`http://localhost:${PORT}/json/new?about:blank`, { method: 'PUT' })
).json();

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

await send('Emulation.setDeviceMetricsOverride', {
  width: +width,
  height: +height,
  deviceScaleFactor: 2,
  mobile: false,
});
await send('Emulation.setEmulatedMedia', {
  features: [{ name: 'prefers-color-scheme', value: process.env.SCHEME || 'light' }],
});
await send('Page.enable');
await send('Page.navigate', { url });

// Real wall-clock wait. The app has to boot Flutter, read assets/.env, bring up
// Supabase and settle the auth redirect before there is anything worth seeing.
await new Promise((resolve) => setTimeout(resolve, +waitMs));

const { data } = await send('Page.captureScreenshot', { format: 'png' });
writeFileSync(out, Buffer.from(data, 'base64'));
console.log('wrote', out);

await send('Page.close');
ws.close();
