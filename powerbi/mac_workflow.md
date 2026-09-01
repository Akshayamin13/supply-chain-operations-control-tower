# Mac-compatible Power BI workflow

## Recommended browser-first path

Power BI Desktop requires Windows, but Microsoft supports creating import semantic models, relationships, DAX measures, and reports in the Power BI service's web experience. Use the generated `control_tower_powerbi_browser_source.xlsx` workbook as the portfolio snapshot source.

1. Open `https://app.powerbi.com` in a supported browser and sign in.
2. In a workspace, choose the create/new semantic-model workflow and select Excel.
3. Upload the generated workbook from `outputs/01a05dcc-9968-7a81-be26-ed89df7d1a66/`.
4. Select all eight named tables.
5. Confirm numeric, date, text, and true/false data types. Convert the two order-summary flag columns to true/false if Power Query initially reads them as text.
6. Create the Mac/browser aggregate relationships in `model_relationships.md`.
7. Add the measures from `measures_browser_aggregate.dax` and apply their display formats.
8. Build the four pages in `dashboard_specification.md`.
9. Reconcile the unfiltered measures to `data/processed/executive_kpis.csv` before taking screenshots.

Official references:

- Power BI service web modelling: https://learn.microsoft.com/en-us/power-bi/transform-model/service-edit-data-models
- Browser report creation tutorial: https://learn.microsoft.com/en-us/power-bi/fundamentals/service-get-started
- Power BI Desktop requirements: https://learn.microsoft.com/en-au/power-bi/fundamentals/desktop-get-the-desktop

## Refresh limitation of the workbook path

The Excel workbook is a controlled snapshot. To refresh it, rerun the PostgreSQL pipeline, rebuild the workbook, and replace/reimport the source according to the capabilities available in the user's Power BI workspace.

For workbook performance, all three event areas use monthly reporting summaries. The export carries exact order/shipment counts, KPI numerators and denominators, stockout counts, throughput, shipped cost, and inventory-value day sums. Full-grain facts remain available in PostgreSQL for detailed investigation and the direct-connection/Windows route.

## Direct PostgreSQL option

Power Query supports PostgreSQL in Desktop and online experiences. Connecting Power Query Online to PostgreSQL running only on this Mac requires an on-premises data gateway. Microsoft's gateway requirements list supported Windows operating systems, so the gateway cannot be hosted natively on this Mac.

Official references:

- PostgreSQL connector: https://learn.microsoft.com/en-us/power-query/connectors/postgresql
- Gateway installation requirements: https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-install

Practical alternatives are:

- temporary access to a Windows machine or virtual machine for Power BI Desktop;
- a Windows machine that can host the gateway;
- moving the PostgreSQL analytics layer to an appropriately secured cloud database;
- importing the generated workbook as a portfolio snapshot.

The workbook snapshot is the lowest-friction route for this project. A gateway or cloud database adds refresh capability but is not required to demonstrate the model and analysis.

## Licensing note

Microsoft's browser tutorial states that reports can be created in My workspace with a free Fabric/Power BI licence, while sharing to other people or shared workspaces generally requires the relevant paid licence or capacity. Availability can also depend on tenant settings.
