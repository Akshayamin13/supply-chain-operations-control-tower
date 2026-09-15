export const executiveKpis = {
  totalOrders: 29873,
  totalShipments: 28366,
  revenue: 3221285.15,
  averageOrderValue: 110.71,
  onTimeDelivery: 62.32,
  lateDelivery: 37.68,
  averageDelayDays: 0.76,
  fulfilmentLeadTime: 1.43,
  openBacklog: 688,
  backlogOverSevenDays: 499,
  slaBreach: 38.78,
  throughputUnits: 67281,
  stockoutRate: 0.35,
  inventoryTurnover: 4.3,
  exceptionRate: 28.14,
};

export const monthlyTrend = [
  { month: 'Sep 25', orders: 2183, revenue: 238701.78 },
  { month: 'Oct 25', orders: 2389, revenue: 261672.89 },
  { month: 'Nov 25', orders: 3039, revenue: 330937.52 },
  { month: 'Dec 25', orders: 3884, revenue: 419051.84 },
  { month: 'Jan 26', orders: 2075, revenue: 216647.93 },
  { month: 'Feb 26', orders: 1993, revenue: 212238.21 },
  { month: 'Mar 26', orders: 2314, revenue: 242727.41 },
  { month: 'Apr 26', orders: 2404, revenue: 266187.23 },
  { month: 'May 26', orders: 2523, revenue: 268026.72 },
  { month: 'Jun 26', orders: 2411, revenue: 269088.44 },
  { month: 'Jul 26', orders: 2242, revenue: 238774.69 },
  { month: 'Aug 26', orders: 2416, revenue: 257230.49 },
];

export const warehousePerformance = [
  { id: 'WH-003', name: 'Rhine-Ruhr', fullName: 'Rhine-Ruhr Fulfilment Centre', city: 'Cologne', orders: 5907, shipments: 5620, delivered: 5586, otd: 55.62, delay: 0.95, backlog: 126, breaches: 2593, exceptionRate: 36.81, revenue: 657576.85 },
  { id: 'WH-001', name: 'Spree', fullName: 'Spree Fulfilment Centre', city: 'Berlin', orders: 5373, shipments: 5103, delivered: 5067, otd: 61.59, delay: 0.78, backlog: 126, breaches: 2068, exceptionRate: 25.95, revenue: 567371.74 },
  { id: 'WH-006', name: 'Saxony', fullName: 'Saxony Distribution Hub', city: 'Leipzig', orders: 4627, shipments: 4420, delivered: 4390, otd: 63.60, delay: 0.70, backlog: 83, breaches: 1681, exceptionRate: 26.67, revenue: 494272.49 },
  { id: 'WH-004', name: 'Main Central', fullName: 'Main Central Hub', city: 'Frankfurt', orders: 6583, shipments: 6222, delivered: 6176, otd: 64.22, delay: 0.73, backlog: 190, breaches: 2383, exceptionRate: 26.47, revenue: 701585.18 },
  { id: 'WH-005', name: 'Isar South', fullName: 'Isar South Centre', city: 'Munich', orders: 3305, shipments: 3138, delivered: 3115, otd: 65.23, delay: 0.68, backlog: 79, breaches: 1162, exceptionRate: 26.29, revenue: 366076.35 },
  { id: 'WH-002', name: 'Elbe North', fullName: 'Elbe North Hub', city: 'Hamburg', orders: 4043, shipments: 3863, delivered: 3838, otd: 66.15, delay: 0.66, backlog: 84, breaches: 1384, exceptionRate: 24.26, revenue: 429881.42 },
];

export const carrierPerformance = [
  { id: 'CAR-04', name: 'Alpine Freight', service: 'Economy', shipments: 3675, delivered: 3646, otd: 27.98, delay: 1.59, exceptionRate: 34.88, cost: 4.19 },
  { id: 'CAR-06', name: 'EuroLink Standard', service: 'Economy', shipments: 3183, delivered: 3158, otd: 30.81, delay: 1.43, exceptionRate: 31.95, cost: 4.33 },
  { id: 'UNKNOWN', name: 'Unknown Carrier', service: 'Unknown', shipments: 35, delivered: 35, otd: 54.29, delay: 1.03, exceptionRate: 37.14, cost: 5.26 },
  { id: 'CAR-02', name: 'Nordstern Logistics', service: 'Standard', shipments: 5193, delivered: 5158, otd: 66.60, delay: 0.65, exceptionRate: 28.83, cost: 4.83 },
  { id: 'CAR-01', name: 'RheinParcel', service: 'Standard', shipments: 6039, delivered: 5997, otd: 67.18, delay: 0.62, exceptionRate: 26.91, cost: 4.96 },
  { id: 'CAR-05', name: 'Elbe Courier', service: 'Standard', shipments: 3971, delivered: 3950, otd: 68.96, delay: 0.60, exceptionRate: 26.01, cost: 5.12 },
  { id: 'CAR-07', name: 'RapidRoute', service: 'Express', shipments: 2533, delivered: 2518, otd: 85.90, delay: 0.29, exceptionRate: 24.20, cost: 9.12 },
  { id: 'CAR-03', name: 'Mainline Express', service: 'Express', shipments: 3737, delivered: 3710, otd: 86.09, delay: 0.25, exceptionRate: 24.11, cost: 9.41 },
];

export const exceptionAnalysis = [
  { reason: 'Warehouse Capacity', shipments: 4709, share: 59.00, delay: 2.00, late: 3822 },
  { reason: 'Carrier Delay', shipments: 2151, share: 26.95, delay: 2.42, late: 1867 },
  { reason: 'Inventory Shortage', shipments: 276, share: 3.46, delay: 3.85, late: 266 },
  { reason: 'Address Issue', shipments: 230, share: 2.88, delay: 0.82, late: 129 },
  { reason: 'Weather', shipments: 193, share: 2.42, delay: 1.61, late: 149 },
  { reason: 'Customer Request', shipments: 157, share: 1.97, delay: 0.72, late: 75 },
  { reason: 'System Error', shipments: 139, share: 1.74, delay: 0.79, late: 81 },
  { reason: 'Damaged Shipment', shipments: 126, share: 1.58, delay: 1.60, late: 100 },
];

export const backlogAgeing = [
  { bucket: '0–3 days', orders: 135, value: 14684.41, averageAge: 1.5 },
  { bucket: '4–7 days', orders: 54, value: 5149.22, averageAge: 5.6 },
  { bucket: '8–14 days', orders: 35, value: 3437.41, averageAge: 10.6 },
  { bucket: '15+ days', orders: 464, value: 52374.40, averageAge: 179.4 },
];

export const stockoutAssociation = [
  { position: 'Stock available', orders: 28709, delivered: 27826, lateRate: 36.98, delay: 0.73, leadTime: 1.38 },
  { position: 'Stockout on order date', orders: 345, delivered: 333, lateRate: 96.70, delay: 3.86, leadTime: 5.04 },
];

export const warehouseCapacity = [
  { id: 'WH-003', name: 'Rhine-Ruhr', city: 'Cologne', capacity: 18, average: 87.56, peak: 200.00, above90: 161, overCapacity: 117 },
  { id: 'WH-004', name: 'Main Central', city: 'Frankfurt', capacity: 24, average: 73.34, peak: 175.00, above90: 91, overCapacity: 53 },
  { id: 'WH-006', name: 'Saxony', city: 'Leipzig', capacity: 17, average: 72.85, peak: 170.59, above90: 81, overCapacity: 53 },
  { id: 'WH-001', name: 'Spree', city: 'Berlin', capacity: 19, average: 75.56, peak: 168.42, above90: 92, overCapacity: 52 },
  { id: 'WH-005', name: 'Isar South', city: 'Munich', capacity: 13, average: 67.90, peak: 215.38, above90: 90, overCapacity: 51 },
  { id: 'WH-002', name: 'Elbe North', city: 'Hamburg', capacity: 15, average: 72.11, peak: 166.67, above90: 95, overCapacity: 44 },
];

export const customerSegments = [
  { segment: 'Consumer', orders: 19176, units: 30305, revenue: 1439061.81, aov: 76.98, otd: 62.53 },
  { segment: 'Small Business', orders: 6812, units: 17804, revenue: 824202.82, aov: 124.43, otd: 62.68 },
  { segment: 'Mid-Market', orders: 2780, units: 11328, revenue: 516734.07, aov: 190.82, otd: 62.86 },
  { segment: 'Enterprise', orders: 1070, units: 10229, revenue: 436765.33, aov: 422.40, otd: 54.93 },
];

export const productRisk = [
  { id: 'PRD-0029', name: 'Kitchen Scale 09', category: 'Home & Kitchen', stockouts: 52, stockoutRate: 2.37, belowReorder: 127, shipped: 553, averageStock: 18.82 },
  { id: 'PRD-0041', name: 'Electric Toothbrush 01', category: 'Personal Care', stockouts: 48, stockoutRate: 2.19, belowReorder: 201, shipped: 1132, averageStock: 27.23 },
  { id: 'PRD-0003', name: 'Bluetooth Speaker 03', category: 'Electronics', stockouts: 26, stockoutRate: 1.19, belowReorder: 130, shipped: 752, averageStock: 22.95 },
  { id: 'PRD-0008', name: 'Bluetooth Speaker 08', category: 'Electronics', stockouts: 25, stockoutRate: 1.14, belowReorder: 99, shipped: 367, averageStock: 15.69 },
  { id: 'PRD-0083', name: 'Printer Paper 03', category: 'Office Supplies', stockouts: 23, stockoutRate: 1.05, belowReorder: 90, shipped: 675, averageStock: 25.78 },
  { id: 'PRD-0001', name: 'Wireless Mouse 01', category: 'Electronics', stockouts: 22, stockoutRate: 1.00, belowReorder: 131, shipped: 1131, averageStock: 33.11 },
  { id: 'PRD-0084', name: 'Marker Set 04', category: 'Office Supplies', stockouts: 21, stockoutRate: 0.96, belowReorder: 117, shipped: 723, averageStock: 24.70 },
  { id: 'PRD-0115', name: 'Charging Pouch 15', category: 'Accessories', stockouts: 20, stockoutRate: 0.91, belowReorder: 99, shipped: 540, averageStock: 19.91 },
  { id: 'PRD-0004', name: 'Webcam 04', category: 'Electronics', stockouts: 19, stockoutRate: 0.87, belowReorder: 147, shipped: 799, averageStock: 21.52 },
  { id: 'PRD-0120', name: 'Charging Pouch 20', category: 'Accessories', stockouts: 19, stockoutRate: 0.87, belowReorder: 107, shipped: 443, averageStock: 17.06 },
  { id: 'PRD-0117', name: 'Cable Set 17', category: 'Accessories', stockouts: 18, stockoutRate: 0.82, belowReorder: 80, shipped: 605, averageStock: 22.23 },
  { id: 'PRD-0048', name: 'Skin Care Set 08', category: 'Personal Care', stockouts: 18, stockoutRate: 0.82, belowReorder: 104, shipped: 513, averageStock: 19.23 },
  { id: 'PRD-0053', name: 'Skin Care Set 13', category: 'Personal Care', stockouts: 18, stockoutRate: 0.82, belowReorder: 99, shipped: 497, averageStock: 19.47 },
  { id: 'PRD-0033', name: 'Desk Lamp 13', category: 'Home & Kitchen', stockouts: 18, stockoutRate: 0.82, belowReorder: 81, shipped: 483, averageStock: 18.20 },
  { id: 'PRD-0101', name: 'Phone Stand 01', category: 'Accessories', stockouts: 17, stockoutRate: 0.78, belowReorder: 129, shipped: 1293, averageStock: 30.99 },
];

export const highRiskOrders = [
  { id: 'ORD-029615', date: '02 Sep 2025', warehouse: 'Spree', segment: 'Consumer', product: 'Water Bottle 20', value: 37.54, age: 364, status: 'Processing' },
  { id: 'ORD-029191', date: '02 Sep 2025', warehouse: 'Rhine-Ruhr', segment: 'Consumer', product: 'Protective Sleeve 04', value: 67.90, age: 364, status: 'Processing' },
  { id: 'ORD-026282', date: '02 Sep 2025', warehouse: 'Saxony', segment: 'Consumer', product: 'Yoga Mat 01', value: 276.24, age: 364, status: 'Processing' },
  { id: 'ORD-003216', date: '02 Sep 2025', warehouse: 'Main Central', segment: 'Consumer', product: 'Kitchen Scale 14', value: 152.64, age: 364, status: 'Processing' },
  { id: 'ORD-014730', date: '02 Sep 2025', warehouse: 'Main Central', segment: 'Consumer', product: 'Fitness Tracker Band 05', value: 140.65, age: 364, status: 'Processing' },
  { id: 'ORD-026544', date: '02 Sep 2025', warehouse: 'Rhine-Ruhr', segment: 'Consumer', product: 'Laptop Stand 05', value: 54.90, age: 364, status: 'Processing' },
  { id: 'ORD-000522', date: '02 Sep 2025', warehouse: 'Spree', segment: 'Small Business', product: 'Charging Pouch 15', value: 68.45, age: 364, status: 'Processing' },
  { id: 'ORD-023581', date: '03 Sep 2025', warehouse: 'Spree', segment: 'Small Business', product: 'Laptop Stand 05', value: 73.27, age: 363, status: 'On Hold' },
  { id: 'ORD-015509', date: '04 Sep 2025', warehouse: 'Isar South', segment: 'Consumer', product: 'Desk Lamp 03', value: 211.36, age: 362, status: 'Processing' },
  { id: 'ORD-003618', date: '04 Sep 2025', warehouse: 'Main Central', segment: 'Small Business', product: 'Coffee Press 02', value: 171.81, age: 362, status: 'Processing' },
  { id: 'ORD-023263', date: '05 Sep 2025', warehouse: 'Elbe North', segment: 'Consumer', product: 'Wireless Mouse 06', value: 81.48, age: 361, status: 'On Hold' },
  { id: 'ORD-017726', date: '05 Sep 2025', warehouse: 'Main Central', segment: 'Small Business', product: 'Water Bottle 20', value: 213.23, age: 361, status: 'On Hold' },
  { id: 'ORD-008505', date: '05 Sep 2025', warehouse: 'Saxony', segment: 'Consumer', product: 'Wireless Mouse 01', value: 117.14, age: 361, status: 'Processing' },
  { id: 'ORD-029749', date: '08 Sep 2025', warehouse: 'Rhine-Ruhr', segment: 'Consumer', product: 'Wireless Mouse 06', value: 80.98, age: 358, status: 'Processing' },
  { id: 'ORD-027639', date: '08 Sep 2025', warehouse: 'Spree', segment: 'Consumer', product: 'Laptop Stand 05', value: 18.20, age: 358, status: 'Processing' },
];
