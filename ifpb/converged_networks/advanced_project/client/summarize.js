const fs = require("fs");
const path = require("path");

const DATA_DIR = path.join(__dirname, 'results');
const OUT_FILE = path.join(DATA_DIR, "summary.csv");

function parseFileName(fileName) {
  // <protocol>-<direction>-oh<overhead>.csv
  const match = fileName.match(/^([a-z]+)-(send|receive)-oh(\d+)\.csv$/);
  if (!match) return null;
  const [, protocol, direction, overhead] = match;
  return { protocol, direction, overhead: parseInt(overhead, 10) };
}

function main() {
  if (!fs.existsSync(DATA_DIR)) {
    console.error(`[summarize] Diretório não encontrado: ${DATA_DIR}`);
    process.exit(1);
  }

  const files = fs
    .readdirSync(DATA_DIR)
    .filter((f) => f.endsWith(".csv") && f !== "summary.csv");

  const rows = [
    ["protocol", "direction", "overhead", "copies", "runs", "avg_ms", "min_ms", "max_ms"],
  ];

  for (const file of files) {
    const meta = parseFileName(file);
    if (!meta) {
      console.warn(`[summarize] Ignorando arquivo fora do padrão: ${file}`);
      continue;
    }

    const content = fs.readFileSync(path.join(DATA_DIR, file), "utf-8").trim();
    const lines = content.split("\n").slice(1); // remove header
    const byCopies = {};

    for (const line of lines) {
      const [copiesStr, , timeStr] = line.split(",");
      const copies = parseInt(copiesStr, 10);
      const time = parseFloat(timeStr);
      if (!byCopies[copies]) byCopies[copies] = [];
      byCopies[copies].push(time);
    }

    for (const copies of Object.keys(byCopies).map(Number).sort((a, b) => a - b)) {
      const times = byCopies[copies];
      const avg = times.reduce((a, b) => a + b, 0) / times.length;
      const min = Math.min(...times);
      const max = Math.max(...times);
      rows.push([
        meta.protocol,
        meta.direction,
        meta.overhead,
        copies,
        times.length,
        avg.toFixed(3),
        min.toFixed(3),
        max.toFixed(3),
      ]);
    }
  }

  fs.writeFileSync(OUT_FILE, rows.map((r) => r.join(",")).join("\n"));
  console.log(`[summarize] ${rows.length - 1} linhas escritas em ${OUT_FILE}`);
}

main();