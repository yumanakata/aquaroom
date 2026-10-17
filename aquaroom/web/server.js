'use strict';
// AquaRoom Web版サーバー。依存パッケージなし（Node 18+）。
// 受信: Server-Sent Events (/events)  送信: POST (/send)。データはメモリのみ。
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = process.env.PORT || 3000;
const LIFE = 15 * 60 * 1000;
const AD_LIFE = 60 * 60 * 1000;
const CATS = ['雑談', 'グルメ', 'イベント', '相談'];
const INDEX = path.join(__dirname, 'public', 'index.html');
const areas = new Map();
const rate = new Map();

function getArea(key) {
  let a = areas.get(key);
  if (!a) {
    if (areas.size >= 5000) return null;
    a = { threads: new Map(), messages: new Map(), ads: [], clients: new Map() };
    areas.set(key, a);
  }
  return a;
}
const participants = (a, t) => {
  const s = new Set([t.creator, ...t.votes]);
  for (const m of a.messages.get(t.id) || []) s.add(m.senderId);
  return s;
};
const need = (a, t) => Math.floor(participants(a, t).size / 2) + 1;
const view = (a, t) => ({
  id: t.id, title: t.title, category: t.category, createdAt: t.createdAt, expiresAt: t.expiresAt,
  votes: t.votes.size, need: need(a, t), participants: participants(a, t).size,
});
const sse = (res, obj) => res.write('data: ' + JSON.stringify(obj) + '\n\n');
const broadcast = (a, obj) => { for (const res of a.clients.values()) sse(res, obj); };
const str = (v, n) => String(v == null ? '' : v).trim().slice(0, n);
const limited = (id) => {
  const now = Date.now();
  const arr = (rate.get(id) || []).filter((t) => now - t < 10000);
  arr.push(now); rate.set(id, arr);
  return arr.length > 15;
};

function handleEvents(req, res, q) {
  const key = str(q.get('area'), 64), id = str(q.get('id'), 40);
  const a = key && id ? getArea(key) : null;
  if (!a) { res.writeHead(400); return res.end(); }
  res.writeHead(200, {
    'Content-Type': 'text/event-stream; charset=utf-8', 'Cache-Control': 'no-cache, no-transform',
    Connection: 'keep-alive', 'X-Accel-Buffering': 'no',
  });
  a.clients.set(id, res);
  sse(res, {
    type: 'sync', now: Date.now(),
    threads: [...a.threads.values()].map((t) => view(a, t)),
    messages: [...a.messages.values()].flat(), ads: a.ads,
  });
  broadcast(a, { type: 'peers', count: a.clients.size });
  req.on('close', () => {
    if (a.clients.get(id) === res) a.clients.delete(id);
    broadcast(a, { type: 'peers', count: a.clients.size });
  });
}

function handleSend(req, res, q) {
  const key = str(q.get('area'), 64), id = str(q.get('id'), 40);
  const a = areas.get(key);
  if (!a || !a.clients.has(id)) { res.writeHead(400); return res.end(); }
  let body = '';
  req.on('data', (c) => { body += c; if (body.length > 4096) req.destroy(); });
  req.on('end', () => {
    let p;
    try { p = JSON.parse(body); } catch (e) { res.writeHead(400); return res.end(); }
    if (limited(id)) { res.writeHead(429); return res.end(); }
    const now = Date.now();
    if (p.type === 'thread') {
      const title = str(p.title, 40);
      if (title && a.threads.size < 200) {
        const t = {
          id: crypto.randomUUID(), title, category: CATS.includes(p.category) ? p.category : CATS[0],
          createdAt: now, expiresAt: now + LIFE, creator: id, votes: new Set(),
        };
        a.threads.set(t.id, t);
        broadcast(a, { type: 'thread', thread: view(a, t) });
      }
    } else if (p.type === 'message') {
      const t = a.threads.get(p.threadId), text = str(p.text, 500);
      const list = t ? a.messages.get(t.id) || [] : [];
      if (t && text && list.length < 500) {
        const m = { id: crypto.randomUUID(), threadId: t.id, senderId: id, senderName: str(p.name, 20) || '名無し', text, date: now };
        list.push(m); a.messages.set(t.id, list);
        broadcast(a, { type: 'message', message: m });
        broadcast(a, { type: 'thread', thread: view(a, t) });
      }
    } else if (p.type === 'vote') {
      const t = a.threads.get(p.threadId);
      if (t) {
        t.votes.add(id);
        if (t.votes.size >= need(a, t)) { t.expiresAt += LIFE; t.votes.clear(); }
        broadcast(a, { type: 'thread', thread: view(a, t) });
      }
    } else if (p.type === 'ad') {
      const title = str(p.title, 40);
      if (title && a.ads.length < 50) {
        const ad = { id: crypto.randomUUID(), title, body: str(p.body, 200), expiresAt: now + AD_LIFE };
        a.ads.push(ad);
        broadcast(a, { type: 'ad', ad });
      }
    }
    res.writeHead(204); res.end();
  });
}

setInterval(() => {
  const now = Date.now();
  for (const [key, a] of areas) {
    const gone = [];
    for (const [tid, t] of a.threads) {
      if (t.expiresAt < now) { a.threads.delete(tid); a.messages.delete(tid); gone.push(tid); }
    }
    const n = a.ads.length;
    a.ads = a.ads.filter((x) => x.expiresAt >= now);
    if (gone.length) broadcast(a, { type: 'expire', ids: gone });
    if (n !== a.ads.length) broadcast(a, { type: 'ads', ads: a.ads });
    if (!a.clients.size && !a.threads.size) areas.delete(key);
  }
  for (const [id, arr] of rate) if (!arr.length || now - arr[arr.length - 1] > 10000) rate.delete(id);
}, 1000);
setInterval(() => { for (const a of areas.values()) for (const r of a.clients.values()) r.write(': ping\n\n'); }, 20000);

http.createServer((req, res) => {
  const u = new URL(req.url, 'http://localhost');
  if (req.method === 'GET' && u.pathname === '/events') return handleEvents(req, res, u.searchParams);
  if (req.method === 'POST' && u.pathname === '/send') return handleSend(req, res, u.searchParams);
  if (req.method === 'GET' && (u.pathname === '/' || u.pathname === '/index.html')) {
    res.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-cache',
      'Content-Security-Policy': "default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'",
    });
    return fs.createReadStream(INDEX).pipe(res);
  }
  res.writeHead(404); res.end();
}).listen(PORT, () => console.log('AquaRoom web: http://localhost:' + PORT));
