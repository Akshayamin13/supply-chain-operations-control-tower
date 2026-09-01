#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(scriptDir, "..");
const workbookPath = path.join(
  projectRoot,
  "outputs",
  "01a05dcc-9968-7a81-be26-ed89df7d1a66",
  "control_tower_powerbi_browser_source.xlsx",
);

const input = await FileBlob.load(workbookPath);
const workbook = await SpreadsheetFile.importXlsx(input);
const summary = await workbook.inspect({
  kind: "workbook,sheet,table",
  maxChars: 8_000,
  tableMaxRows: 3,
  tableMaxCols: 20,
});
console.log(summary.ndjson);

const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 100 },
  summary: "saved workbook formula error scan",
  maxChars: 2_000,
});
console.log(errors.ndjson);

const preview = await workbook.render({
  sheetName: "ExecutiveKPIs",
  range: "A1:P2",
  scale: 1.5,
  format: "png",
});
await fs.writeFile(
  path.join(projectRoot, "data", "tmp", "powerbi_source", "previews", "ExecutiveKPIs-reopened.png"),
  new Uint8Array(await preview.arrayBuffer()),
);

console.log(JSON.stringify({ workbookPath, reopenStatus: "PASS" }));
