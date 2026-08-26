const fs = require("fs");
const path = require("path");
const axios = require("axios");
const https = require("https");
const { io } = require("socket.io-client");

function parseArgs() {
  const args = {};
  for (const arg of process.argv.slice(2)) {
    const [k, v] = arg.replace(/^--/, "").split("=");
    args[k] = v;
  }
  return args;
}

const args = parseArgs();
const protocol = args.protocol || "http";
const direction = args.direction || "send";
const copiesList = (args.copies || "1,3,10,30,100,300,1000,3000")
  .split(",")
  .map((n) => parseInt(n, 10));
const runs = parseInt(args.runs || "10", 10);
const overhead = parseInt(args.overhead || "0", 10);
const host = args.host || "server";
const isSecure = protocol === "https" || protocol === "wss";
const isWebSocket = protocol === "ws" || protocol === "wss";

const HTTP_PORT = 3000;
const HTTPS_PORT = 3443;
const port = isSecure ? HTTPS_PORT : HTTP_PORT;

const SAMPLE_TEXT =
  "1234567890123456789012345678901234567" +
  "8901234567890123456789012345678901234" +
  "56789012345678901234567890";

// Para HTTPS/WSS com certificado autoassinado
const httpsAgent = new https.Agent({ rejectUnauthorized: false });

function buildOverheadHeaders(n) {
  const headers = {};
  for (let i = 0; i < n; i++) {
    headers[`x-overhead-${i}`] = "content";
  }
  return headers;
}

async function runHttpBatch(copies) {
  const baseURL = `${isSecure ? "https" : "http"}://${host}:${port}`;
  const client = axios.create({
    baseURL,
    httpsAgent: isSecure ? httpsAgent : undefined,
    headers: buildOverheadHeaders(overhead),
  });

  const start = process.hrtime.bigint();
  for (let i = 0; i < copies; i++) {
    if (direction === "send") {
      await client.post("/text", { text: SAMPLE_TEXT });
    } else {
      await client.get("/text");
    }
  }
  const end = process.hrtime.bigint();
  return Number(end - start) / 1e6; // ms
}

function connectSocket() {
  const url = `${isSecure ? "wss" : "ws"}://${host}:${port}`;
  return io(url, {
    rejectUnauthorized: false,
    transports: ["websocket"],
  });
}

async function runWsBatch(copies, socket) {
  const start = process.hrtime.bigint();
  for (let i = 0; i < copies; i++) {
    await new Promise((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error("timeout")), 15000);
      if (direction === "send") {
        socket.emit("text:send", { text: SAMPLE_TEXT }, () => {
          clearTimeout(timeout);
          resolve();
        });
      } else {
        socket.emit("text:request", () => {
          clearTimeout(timeout);
          resolve();
        });
      }
    });
  }
  const end = process.hrtime.bigint();
  return Number(end - start) / 1e6; // ms
}

async function main() {
  console.log(
    `[benchmark] protocolo=${protocol} direção=${direction} overhead=${overhead} runs=${runs}`
  );

  let socket = null;
  if (isWebSocket) {
    socket = connectSocket();
    await new Promise((resolve, reject) => {
      socket.on("connect", resolve);
      socket.on("connect_error", reject);
    });
  }

  const rows = [["copies", "run", "time_ms"]];
  const summary = [];

  for (const copies of copiesList) {
    const times = [];
    for (let run = 1; run <= runs; run++) {
      // limpa dados anteriores no servidor antes de cada rodada (evita
      // colisão de arquivos, como recomendado no artigo original)
      if (!isWebSocket) {
        await axios
          .delete(`${isSecure ? "https" : "http"}://${host}:${port}/text`, {
            httpsAgent: isSecure ? httpsAgent : undefined,
          })
          .catch(() => {});
      }
      const t = isWebSocket
        ? await runWsBatch(copies, socket)
        : await runHttpBatch(copies);
      times.push(t);
      rows.push([copies, run, t.toFixed(3)]);
      process.stdout.write(
        `\r  copies=${copies} run=${run}/${runs} -> ${t.toFixed(1)} ms      `
      );
    }
    const avg = times.reduce((a, b) => a + b, 0) / times.length;
    console.log(`\n  média para ${copies} cópias: ${avg.toFixed(2)} ms`);
    summary.push({ copies, avg_ms: avg });
  }

  if (socket) socket.close();

  const outDir = path.join(__dirname, 'results');
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
  const outFile =
    args.out || path.join(outDir, `${protocol}-${direction}-oh${overhead}.csv`);
  fs.writeFileSync(outFile, rows.map((r) => r.join(",")).join("\n"));
  console.log(`\n[benchmark] CSV salvo em ${outFile}`);
  console.table(summary.map((s) => ({ copies: s.copies, media_ms: s.avg_ms.toFixed(2) })));
}

main().catch((err) => {
  console.error("[benchmark] erro:", err.message);
  process.exit(1);
});
