// Signs in anonymously against the live Supabase project over REST and
// injects the resulting session straight into the open tab's localStorage,
// then reloads — so an authenticated screen can be reached without clicking
// through the sign-in UI at all. Existing session on that Supabase project
// works the same way for a real (non-anonymous) session if you already hold
// one; this script only covers minting a fresh guest.
//
// Exists because driving "Continue as guest" via synthetic CDP clicks is
// fragile (see SKILL.md) and this is what the click was for anyway in most
// cases — reaching an authenticated screen, not testing the click itself.
// It is also the only way to test session *persistence* (surviving a
// killed-and-relaunched browser) deterministically, since it removes the
// click's own reliability from the thing being measured.
//
//   node inject_session.mjs <out.png> [waitMs]
//
// Requires Chrome already listening on --remote-debugging-port (CDP_PORT env,
// default 9333) with an open page target already navigated to the app (any
// screen — sign-in or already authenticated).

import { readFileSync, writeFileSync } from 'node:fs';

const [, , out, waitMs = '7000'] = process.argv;
const PORT = process.env.CDP_PORT || '9333';

const env = readFileSync(new URL('../../../assets/.env', import.meta.url), 'utf8');
const url = env.match(/^SUPABASE_URL=(.+)$/m)[1].trim();
const apikey = env.match(/^SUPABASE_PUBLISHABLE_KEY=(.+)$/m)[1].trim();
const projectRef = new URL(url).host.split('.')[0];
const storageKey = `sb-${projectRef}-auth-token`;

const raw = await (
  await fetch(`${url}/auth/v1/signup`, {
    method: 'POST',
    headers: { apikey, 'Content-Type': 'application/json' },
    body: '{}',
  })
).json();

// Shape must match gotrue's Session.toJson(), which is what
// supabase_flutter's SharedPreferencesLocalStorage persists and what
// GoTrueClient.recoverSession() parses back on boot — see
// supabase_flutter's local_storage.dart / supabase_auth.dart and gotrue's
// session.dart if this drifts on a package upgrade.
const session = {
  access_token: raw.access_token,
  expires_in: raw.expires_in,
  expires_at: raw.expires_at,
  refresh_token: raw.refresh_token,
  token_type: raw.token_type,
  provider_token: null,
  provider_refresh_token: null,
  user: raw.user,
};

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

await send('Emulation.setDeviceMetricsOverride', {
  width: 440,
  height: 900,
  deviceScaleFactor: 2,
  mobile: false,
});
await send('Page.enable');

await send('Runtime.evaluate', {
  expression: `window.localStorage.setItem(${JSON.stringify(storageKey)}, ${JSON.stringify(
    JSON.stringify(session),
  )})`,
});

await send('Page.reload', {});
await new Promise((resolve) => setTimeout(resolve, +waitMs));

const { data } = await send('Page.captureScreenshot', { format: 'png' });
writeFileSync(out, Buffer.from(data, 'base64'));
console.log('wrote', out, '— guest user', raw.user.id);

ws.close();
