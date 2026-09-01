#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";


const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(scriptDir, "..");
const inputDir = path.join(projectRoot, "data", "tmp", "powerbi_source");
const outputDir = path.join(
  projectRoot,
  "outputs",
  "01a05dcc-9968-7a81-be26-ed89df7d1a66",
);
const previewDir = path.join(projectRoot, "data", "tmp", "powerbi_source", "previews");

const definitions = [
  { sheetName: "DimDate", fileName: "DimDate.csv", tableName: "tblDimDate" },
  { sheetName: "DimProduct", fileName: "DimProduct.csv", tableName: "tblDimProduct" },
  { sheetName: "DimWarehouse", fileName: "DimWarehouse.csv", tableName: "tblDimWarehouse" },
  { sheetName: "DimCarrier", fileName: "DimCarrier.csv", tableName: "tblDimCarrier" },
  { sheetName: "OrderSummary", fileName: "OrderSummary.csv", tableName: "tblOrderSummary" },
  { sheetName: "ShipmentSummary", fileName: "ShipmentSummary.csv", tableName: "tblShipmentSummary" },
  { sheetName: "InventorySummary", fileName: "InventorySummary.csv", tableName: "tblInventorySummary" },
  { sheetName: "ExecutiveKPIs", fileName: "ExecutiveKPIs.csv", tableName: "tblExecutiveKPIs" },
];


function columnLetter(number) {
  let result = "";
  let value = number;
  while (value > 0) {
    value -= 1;
    result = String.fromCharCode(65 + (value % 26)) + result;
    value = Math.floor(value / 26);
  }
  return result;
}


function columnWidth(header) {
  let baseWidth = 15;
  if (header.includes("quality_note")) baseWidth = 38;
  else if (header.includes("name") || header.includes("reason") || header.includes("category")) baseWidth = 24;
  else if (header.includes("segment")) baseWidth = 20;
  else if (header.endsWith("_id") || header.endsWith("_key")) baseWidth = 16;
  else if (header.includes("date") || header === "full_date") baseWidth = 14;
  else if (header.includes("status") || header.includes("channel") || header.includes("level")) baseWidth = 18;
  return Math.min(34, Math.max(baseWidth, header.length + 2));
}


function numberFormat(header) {
  if (header.endsWith("_key")) return "0";
  if (header.endsWith("_eur")) return '"€"#,##0.00';
  if (header.endsWith("_pct")) return "0.00";
  if (header === "full_date" || header.endsWith("_date")) return "yyyy-mm-dd";
  if (header.startsWith("average_") || header.endsWith("_ratio")) return "#,##0.00";
  if (header.endsWith("_days") || header.includes("quantity") || header.includes("stock")) return "#,##0";
  return null;
}


await fs.mkdir(outputDir, { recursive: true });
await fs.mkdir(previewDir, { recursive: true });

let workbook;
const sheetShapes = [];

for (let index = 0; index < definitions.length; index += 1) {
  const definition = definitions[index];
  const csvText = await fs.readFile(path.join(inputDir, definition.fileName), "utf8");
  const lines = csvText.trimEnd().split(/\r?\n/);
  const headers = lines[0].split(",");
  const rowCount = lines.length;
  const lastColumn = columnLetter(headers.length);

  console.log(`Importing ${definition.sheetName}: ${rowCount - 1} data rows`);

  if (index === 0) {
    workbook = await Workbook.fromCSV(csvText, { sheetName: definition.sheetName });
  } else {
    await workbook.fromCSV(csvText, { sheetName: definition.sheetName });
  }
  console.log(`Imported ${definition.sheetName}`);

  const sheet = workbook.worksheets.getItem(definition.sheetName);
  const headerRange = sheet.getRange(`A1:${lastColumn}1`);

  sheet.showGridLines = false;
  sheet.freezePanes.freezeRows(1);
  headerRange.format = {
    fill: "#0F766E",
    font: { bold: true, color: "#FFFFFF" },
    rowHeight: 46,
    wrapText: true,
    verticalAlignment: "center",
  };

  for (let columnIndex = 0; columnIndex < headers.length; columnIndex += 1) {
    const letter = columnLetter(columnIndex + 1);
    sheet.getRange(`${letter}1`).format.columnWidth = columnWidth(headers[columnIndex]);
    const format = numberFormat(headers[columnIndex]);
    if (format && rowCount > 1 && rowCount <= 50_000) {
      sheet.getRange(`${letter}2:${letter}${rowCount}`).format.numberFormat = format;
    }
  }

  if (rowCount <= 50_000) {
    const table = sheet.tables.add(`A1:${lastColumn}${rowCount}`, true, definition.tableName);
    table.style = "TableStyleMedium2";
    table.showBandedRows = true;
    table.showFilterButton = true;
  } else {
    console.log(`${definition.sheetName} retained as a worksheet range to avoid styling 262,800 rows`);
  }
  console.log(`Prepared ${definition.sheetName}`);

  sheetShapes.push({
    sheetName: definition.sheetName,
    rowCount,
    columnCount: headers.length,
    lastColumn,
  });
}

for (const shape of sheetShapes) {
  const inspect = await workbook.inspect({
    kind: "table",
    sheetId: shape.sheetName,
    range: `A1:${shape.lastColumn}${Math.min(shape.rowCount, 6)}`,
    include: "values,formulas",
    tableMaxRows: 6,
    tableMaxCols: Math.min(shape.columnCount, 20),
    maxChars: 4_000,
  });
  console.log(inspect.ndjson);

  const preview = await workbook.render({
    sheetName: shape.sheetName,
    range: `A1:${shape.lastColumn}${Math.min(shape.rowCount, 20)}`,
    scale: 1,
    format: "png",
  });
  await fs.writeFile(
    path.join(previewDir, `${shape.sheetName}.png`),
    new Uint8Array(await preview.arrayBuffer()),
  );
}

const formulaErrors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 100 },
  summary: "final formula error scan",
  maxChars: 2_000,
});
console.log(formulaErrors.ndjson);

const outputPath = path.join(outputDir, "control_tower_powerbi_browser_source.xlsx");
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);

console.log(JSON.stringify({ outputPath, sheets: sheetShapes }, null, 2));
