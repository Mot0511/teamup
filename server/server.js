// server.js
const WebSocket = require("ws");
const wss = new WebSocket.Server({ port: 8080 });
const rooms = new Map(); // roomId -> Map(peerId, ws)

function send(ws, msg) { ws.send(JSON.stringify(msg)); }
function broadcast(room, except, msg) {
  const data = JSON.stringify(msg);
  for (const [_, peerWs] of room) {
    if (peerWs !== except && peerWs.readyState === WebSocket.OPEN) {
      peerWs.send(data);
    }
  }
}

wss.on("connection", (ws) => {
  let roomId, peerId;
  ws.on("message", (raw) => {
    const msg = JSON.parse(raw);
    if (msg.type === "join") {
      roomId = msg.roomId;
      peerId = msg.peerId;
      if (!rooms.has(roomId)) rooms.set(roomId, new Map());
      const room = rooms.get(roomId);
      room.set(peerId, ws);

      // сообщаем новому о существующих
      send(ws, { type: "peers", peers: [...room.keys()].filter(p => p !== peerId) });
      // остальным — о новом
      broadcast(room, ws, { type: "peer-joined", peerId });
      return;
    }
    if (["offer", "answer", "candidate"].includes(msg.type)) {
      const room = rooms.get(roomId);
      if (!room) return;
      const to = room.get(msg.to);
      if (to) send(to, { ...msg, from: peerId });
    }
    if (msg.type === "leave") {
      roomCleanup();
    }
  });
  ws.on("close", roomCleanup);
  function roomCleanup() {
    if (!roomId || !peerId) return;
    const room = rooms.get(roomId);
    if (!room) return;
    room.delete(peerId);
    broadcast(room, ws, { type: "peer-left", peerId });
    if (room.size === 0) rooms.delete(roomId);
  }
});

console.log("Signaling server ws://192.168.0.127:8080");