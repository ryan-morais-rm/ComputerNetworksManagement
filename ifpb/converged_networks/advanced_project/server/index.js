const fs = require("fs");
const path = require("path");
const http = require("http");
const https = require("https");
const express = require("express");
const { Server } = require("socket.io");

const DATA_DIR = path.join(__dirname, 'results');
if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
const LOG_FILE = path.join(DATA_DIR, "received.log");

// Texto de 100 caracteres, igual ao usado no artigo original
const SAMPLE_TEXT =
  "1234567890123456789012345678901234567" +
  "8901234567890123456789012345678901234" +
  "56789012345678901234567890";

const app = express();
app.use(express.json({ limit: "5mb" }));

let receivedCount = 0;

app.post("/text", (req, res) => {
  const { text } = req.body || {};
  receivedCount++;
  // Grava em disco para reproduzir o mesmo tipo de I/O do artigo original
  fs.appendFile(LOG_FILE, (text || "") + "\n", () => {});
  res.status(200).json({ ok: true, received: receivedCount });
});

app.get("/text", (_req, res) => {
  res.status(200).json({ text: SAMPLE_TEXT });
});

app.delete("/text", (_req, res) => {
  receivedCount = 0;
  fs.writeFile(LOG_FILE, "", () => {});
  res.status(200).json({ ok: true });
});

app.get("/health", (_req, res) => res.send("ok"));

// --- Servidores HTTP e HTTPS (a mesma app Express nos dois) ---
const httpServer = http.createServer(app);

let httpsServer = null;
const certPath = path.join(__dirname, "certs", "cert.pem");
const keyPath = path.join(__dirname, "certs", "key.pem");
if (fs.existsSync(certPath) && fs.existsSync(keyPath)) {
  httpsServer = https.createServer(
    { cert: fs.readFileSync(certPath), key: fs.readFileSync(keyPath) },
    app
  );
}

// --- Socket.IO nos dois servidores (ws:// e wss://) ---
function attachSocketIO(server) {
  const io = new Server(server, { cors: { origin: "*" } });
  io.on("connection", (socket) => {
    socket.on("text:send", (payload, ack) => {
      const text = (payload && payload.text) || "";
      fs.appendFile(LOG_FILE, `${text}\n`, () => {});
      if (typeof ack === "function") ack({ ok: true });
    });
    socket.on("text:request", (ack) => {
      if (typeof ack === "function") ack({ text: SAMPLE_TEXT });
    });
  });
  return io;
}

attachSocketIO(httpServer);
if (httpsServer) attachSocketIO(httpsServer);

const HTTP_PORT = process.env.HTTP_PORT || 3000;
const HTTPS_PORT = process.env.HTTPS_PORT || 3443;

httpServer.listen(HTTP_PORT, () =>
  console.log(`[server] HTTP + WS ouvindo na porta ${HTTP_PORT}`)
);

if (httpsServer) {
  httpsServer.listen(HTTPS_PORT, () =>
    console.log(`[server] HTTPS + WSS ouvindo na porta ${HTTPS_PORT}`)
  );
} else {
  console.log("[server] Certificado não encontrado — HTTPS/WSS desativado.");
}
