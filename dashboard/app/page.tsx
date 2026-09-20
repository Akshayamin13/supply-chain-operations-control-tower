'use client';

import { useMemo, useState, type ReactNode } from 'react';
import {
  AlertTriangle,
  ArrowDownRight,
  ArrowUpRight,
  Boxes,
  CalendarDays,
  ChevronRight,
  CircleGauge,
  ClipboardCheck,
  Clock3,
  DatabaseZap,
  Factory,
  Gauge,
  PackageCheck,
  PackageSearch,
  ShieldCheck,
  ShoppingCart,
  Siren,
  Truck,
  Warehouse,
  type LucideIcon,
} from 'lucide-react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  ComposedChart,
  Line,
  ReferenceLine,
  Scatter,
  ScatterChart,
  XAxis,
  YAxis,
  ZAxis,
} from 'recharts';

import { Badge } from '@/components/ui/badge';
import {
  ChartConfig,
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from '@/components/ui/chart';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  backlogAgeing,
  carrierPerformance,
  customerSegments,
  exceptionAnalysis,
  executiveKpis,
  highRiskOrders,
  monthlyTrend,
  productRisk,
  stockoutAssociation,
  warehouseCapacity,
  warehousePerformance,
} from '@/lib/dashboard-data';

const currency0 = new Intl.NumberFormat('en-GB', {
  style: 'currency',
  currency: 'EUR',
  maximumFractionDigits: 0,
});
const currency2 = new Intl.NumberFormat('en-GB', {
  style: 'currency',
  currency: 'EUR',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});
const compact = new Intl.NumberFormat('en-GB', { notation: 'compact' });

const chartConfig = {
  orders: { label: 'Orders', color: '#0b6b63' },
  revenue: { label: 'Revenue', color: '#d58b28' },
  otd: { label: 'On-time delivery', color: '#0b6b63' },
  exceptionRate: { label: 'Exception rate', color: '#b84732' },
  shipments: { label: 'Shipments', color: '#2e6e9e' },
  cost: { label: 'Average cost', color: '#d58b28' },
  backlog: { label: 'Backlog orders', color: '#b84732' },
  value: { label: 'Backlog value', color: '#d58b28' },
  stockoutRate: { label: 'Stockout rate', color: '#b84732' },
  shipped: { label: 'Shipped units', color: '#2e6e9e' },
  average: { label: 'Average utilisation', color: '#0b6b63' },
  peak: { label: 'Peak utilisation', color: '#d58b28' },
} satisfies ChartConfig;

const serviceColours: Record<string, string> = {
  Express: '#0b6b63',
  Standard: '#2e6e9e',
  Economy: '#d58b28',
  Unknown: '#94a3b8',
};

const categoryColours: Record<string, string> = {
  Electronics: '#2e6e9e',
  Accessories: '#0b6b63',
  'Home & Kitchen': '#d58b28',
  'Personal Care': '#a44c78',
  'Office Supplies': '#7b61a8',
};

const warehouseSelectItems = [
  { value: 'all', label: 'All warehouses' },
  ...warehousePerformance.map((warehouse) => ({
    value: warehouse.id,
    label: `${warehouse.id} · ${warehouse.name} · ${warehouse.city}`,
  })),
];

const carrierSelectItems = [
  { value: 'all', label: 'All carriers' },
  ...carrierPerformance.map((carrier) => ({
    value: carrier.id,
    label: `${carrier.id} · ${carrier.name}`,
  })),
];

const categorySelectItems = [
  { value: 'all', label: 'All product categories' },
  ...Array.from(new Set(productRisk.map((row) => row.category))).map((category) => ({
    value: category,
    label: category,
  })),
];

function Panel({
  title,
  eyebrow,
  detail,
  action,
  children,
  className = '',
}: {
  title: string;
  eyebrow?: string;
  detail?: string;
  action?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <article
      className={`rounded-2xl border border-[#dbe6e3] bg-white p-5 shadow-[0_8px_24px_rgb(31_65_61/5%)] sm:p-6 ${className}`}
    >
      <div className="mb-5 flex items-start justify-between gap-4">
        <div>
          {eyebrow ? (
            <p className="text-[11px] font-semibold uppercase tracking-[0.13em] text-[#0b6b63]">
              {eyebrow}
            </p>
          ) : null}
          <h2 className={`${eyebrow ? 'mt-1' : ''} text-lg font-semibold tracking-tight`}>
            {title}
          </h2>
          {detail ? <p className="mt-1 text-xs leading-5 text-[#71817e]">{detail}</p> : null}
        </div>
        {action}
      </div>
      {children}
    </article>
  );
}

function KpiCard({
  label,
  value,
  note,
  icon: Icon,
  tone = 'teal',
}: {
  label: string;
  value: string;
  note: string;
  icon: LucideIcon;
  tone?: 'teal' | 'blue' | 'amber' | 'red';
}) {
  const toneStyles = {
    teal: 'bg-[#dff1ed] text-[#0b6b63]',
    blue: 'bg-[#e3eef6] text-[#2e6e9e]',
    amber: 'bg-[#fbedd8] text-[#a66313]',
    red: 'bg-[#f7e3df] text-[#a33a28]',
  };
  return (
    <article className="rounded-2xl border border-[#dbe6e3] bg-white p-4 shadow-[0_8px_24px_rgb(31_65_61/5%)]">
      <div className="mb-4 flex items-start justify-between gap-3">
        <p className="text-[11px] font-semibold uppercase tracking-[0.12em] text-[#687b78]">
          {label}
        </p>
        <span className={`grid size-8 place-items-center rounded-lg ${toneStyles[tone]}`}>
          <Icon className="size-4" />
        </span>
      </div>
      <p className="text-[1.65rem] font-semibold tracking-[-0.04em] text-[#102a2b]">{value}</p>
      <p className="mt-1 text-xs text-[#72827f]">{note}</p>
    </article>
  );
}

function PageHeading({
  eyebrow,
  title,
  description,
}: {
  eyebrow: string;
  title: string;
  description: string;
}) {
  return (
    <section className="mb-5">
      <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-[#56706d]">{eyebrow}</p>
      <h1 className="mt-1 text-2xl font-semibold tracking-[-0.035em] text-[#102a2b] sm:text-3xl">{title}</h1>
      <p className="mt-1.5 max-w-3xl text-sm leading-6 text-[#627572]">{description}</p>
    </section>
  );
}

function ExecutiveOverview({ warehouseId }: { warehouseId: string }) {
  const selected = warehousePerformance.find((row) => row.id === warehouseId);
  const shownWarehouses = selected ? [selected] : warehousePerformance;
  const totalOrders = selected?.orders ?? executiveKpis.totalOrders;
  const revenue = selected?.revenue ?? executiveKpis.revenue;
  const otd = selected?.otd ?? executiveKpis.onTimeDelivery;
  const backlog = selected?.backlog ?? executiveKpis.openBacklog;
  const sla = selected ? (selected.breaches / selected.orders) * 100 : executiveKpis.slaBreach;
  const exceptions = selected?.exceptionRate ?? executiveKpis.exceptionRate;

  return (
    <TabsContent value="overview" className="pt-5">
      <PageHeading
        eyebrow={`${selected?.city ?? 'German network'} · ${selected?.fullName ?? '6 fulfilment centres'}`}
        title="Executive overview"
        description="A one-minute health check across demand, service and operational exposure for the validated 12-month scenario."
      />

      <section className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-6">
        <KpiCard label="Total orders" value={totalOrders.toLocaleString('en-GB')} note={selected ? selected.fullName : '29,873 analysis-eligible'} icon={PackageCheck} />
        <KpiCard label="Revenue" value={currency0.format(revenue)} note={selected ? `${selected.city} contribution` : `AOV ${currency2.format(executiveKpis.averageOrderValue)}`} icon={ArrowUpRight} tone="blue" />
        <KpiCard label="On-time delivery" value={`${otd.toFixed(2)}%`} note="Target ≥ 90%" icon={Truck} tone="red" />
        <KpiCard label="Open backlog" value={backlog.toLocaleString('en-GB')} note={selected ? 'Open warehouse orders' : '499 over 7 days'} icon={Boxes} tone="amber" />
        <KpiCard label="SLA breach rate" value={`${sla.toFixed(2)}%`} note={selected ? `${selected.breaches.toLocaleString('en-GB')} breaches` : '11,047 eligible breaches'} icon={AlertTriangle} tone="red" />
        <KpiCard label="Exception rate" value={`${exceptions.toFixed(2)}%`} note={selected ? 'Warehouse shipments' : '7,981 shipments affected'} icon={Siren} tone={exceptions > 30 ? 'red' : 'amber'} />
      </section>

      <section className="mt-5 grid gap-5 xl:grid-cols-[minmax(0,1.4fr)_minmax(360px,0.85fr)]">
        <Panel
          eyebrow="Demand pulse"
          title="Monthly orders and revenue"
          detail={`Network trend · December volume peaks ${(100 * (Math.max(...monthlyTrend.map((month) => month.orders)) / (monthlyTrend.reduce((sum, month) => sum + month.orders, 0) / monthlyTrend.length) - 1)).toFixed(0)}% above the monthly average`}
          action={<Badge variant="secondary">12 months</Badge>}
        >
          <ChartContainer config={chartConfig} className="h-[310px] w-full aspect-auto">
            <ComposedChart accessibilityLayer data={monthlyTrend} margin={{ left: 0, right: 8, top: 10 }}>
              <CartesianGrid vertical={false} stroke="#e6edeb" />
              <XAxis dataKey="month" tickLine={false} axisLine={false} tickMargin={10} />
              <YAxis yAxisId="orders" tickLine={false} axisLine={false} width={42} />
              <YAxis yAxisId="revenue" orientation="right" tickLine={false} axisLine={false} tickFormatter={(value) => `€${compact.format(value)}`} width={54} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <Bar yAxisId="orders" dataKey="orders" fill="var(--color-orders)" radius={[5, 5, 0, 0]} maxBarSize={34} />
              <Line yAxisId="revenue" dataKey="revenue" type="monotone" stroke="var(--color-revenue)" strokeWidth={2.5} dot={{ r: 3, fill: '#fff', strokeWidth: 2 }} activeDot={{ r: 5 }} />
            </ComposedChart>
          </ChartContainer>
        </Panel>

        <Panel
          eyebrow="Service comparison"
          title="On-time delivery by warehouse"
          detail="Company average: 62.32% · target: 90%"
        >
          <ChartContainer config={chartConfig} className="h-[310px] w-full aspect-auto">
            <BarChart accessibilityLayer data={shownWarehouses} layout="vertical" margin={{ left: 10, right: 16 }}>
              <CartesianGrid horizontal={false} stroke="#e6edeb" />
              <XAxis type="number" domain={[0, 100]} tickFormatter={(value) => `${value}%`} tickLine={false} axisLine={false} />
              <YAxis type="category" dataKey="name" width={88} tickLine={false} axisLine={false} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <ReferenceLine x={62.32} stroke="#d58b28" strokeDasharray="4 4" />
              <Bar dataKey="otd" radius={[0, 5, 5, 0]}>
                {shownWarehouses.map((row) => <Cell key={row.id} fill={row.otd < 60 ? '#b84732' : '#0b6b63'} />)}
              </Bar>
            </BarChart>
          </ChartContainer>
        </Panel>
      </section>

      <section className="mt-5 grid gap-5 xl:grid-cols-[minmax(0,1.25fr)_minmax(330px,0.75fr)]">
        <Panel eyebrow="Exception mix" title="Recorded operational exceptions" detail="Warehouse capacity accounts for 59% of all recorded exceptions">
          <ChartContainer config={chartConfig} className="h-[300px] w-full aspect-auto">
            <BarChart accessibilityLayer data={exceptionAnalysis.slice(0, 6)} layout="vertical" margin={{ left: 12, right: 16 }}>
              <CartesianGrid horizontal={false} stroke="#e6edeb" />
              <XAxis type="number" tickLine={false} axisLine={false} />
              <YAxis type="category" dataKey="reason" width={116} tickLine={false} axisLine={false} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <Bar dataKey="shipments" fill="#b84732" radius={[0, 5, 5, 0]} maxBarSize={26} />
            </BarChart>
          </ChartContainer>
        </Panel>

        <aside className="rounded-2xl bg-[#102f31] p-6 text-white shadow-[0_16px_38px_rgb(16_47_49/16%)]">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-[#86c7be]">Control-room brief</p>
              <h2 className="mt-1 text-lg font-semibold">Priority signals</h2>
            </div>
            <span className="grid size-10 place-items-center rounded-xl bg-[#b84732]"><AlertTriangle className="size-5" /></span>
          </div>
          <div className="my-6 h-px bg-white/10" />
          <div className="space-y-4">
            <div>
              <div className="flex items-center justify-between text-xs"><span className="text-[#a9c7c3]">Service performance</span><span className="font-mono text-[#f3b45c]">{otd.toFixed(2)}% OTD</span></div>
              <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-white/10"><div className="h-full rounded-full bg-[#d58b28]" style={{ width: `${Math.min(otd, 100)}%` }} /></div>
            </div>
            <div className="rounded-xl border border-white/10 bg-white/[0.04] p-4">
              <p className="text-sm font-semibold">Primary constraint</p>
              <p className="mt-1.5 text-sm leading-5 text-[#b9cecb]">Rhine-Ruhr records 55.62% OTD and 117 days above daily capacity.</p>
            </div>
            <div className="rounded-xl border border-white/10 bg-white/[0.04] p-4">
              <p className="text-sm font-semibold">Backlog exposure</p>
              <p className="mt-1.5 text-sm leading-5 text-[#b9cecb]">464 orders are 15+ days old, representing €52,374 in value.</p>
            </div>
          </div>
        </aside>
      </section>
    </TabsContent>
  );
}

function FulfilmentDashboard({ warehouseId }: { warehouseId: string }) {
  const selected = warehousePerformance.find((row) => row.id === warehouseId);
  const rows = selected ? [selected] : warehousePerformance;
  const [carrierId, setCarrierId] = useState('all');
  const selectedCarrier = carrierPerformance.find((row) => row.id === carrierId);
  const carriers = selectedCarrier ? [selectedCarrier] : carrierPerformance;
  const delivered = selectedCarrier?.delivered ?? selected?.delivered ?? 28120;
  const otd = selectedCarrier?.otd ?? selected?.otd ?? executiveKpis.onTimeDelivery;
  const delay = selectedCarrier?.delay ?? selected?.delay ?? executiveKpis.averageDelayDays;
  const exceptions = selectedCarrier?.exceptionRate ?? selected?.exceptionRate ?? executiveKpis.exceptionRate;
  const serviceScope = selectedCarrier
    ? `${selectedCarrier.id} · ${selectedCarrier.name} · network-wide`
    : selected
      ? `${selected.id} · ${selected.fullName}`
      : 'All warehouses and carriers';

  return (
    <TabsContent value="fulfilment" className="pt-5">
      <div className="flex flex-col justify-between gap-4 lg:flex-row lg:items-end">
        <PageHeading eyebrow="Service operations" title="Fulfilment & delivery" description="Trace late delivery, ageing backlog, warehouse performance and carrier trade-offs." />
        <div className="mb-5 w-full lg:w-auto">
          <p className="mb-1.5 text-[10px] font-semibold uppercase tracking-[0.12em] text-[#687b78]">Carrier filter</p>
          <Select items={carrierSelectItems} value={carrierId} onValueChange={(value) => setCarrierId(value ?? 'all')}>
          <SelectTrigger aria-label="Carrier filter" className="w-full bg-white lg:w-[260px]"><SelectValue placeholder="All carriers" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All carriers</SelectItem>
            {carrierPerformance.map((carrier) => <SelectItem key={carrier.id} value={carrier.id}>{carrier.id} · {carrier.name}</SelectItem>)}
          </SelectContent>
          </Select>
          <p className="mt-1.5 text-[11px] text-[#71817e]">{serviceScope}</p>
        </div>
      </div>

      <section className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
        <KpiCard label="Delivered shipments" value={delivered.toLocaleString('en-GB')} note={selectedCarrier ? `${selectedCarrier.shipments.toLocaleString('en-GB')} carrier shipments` : selected ? selected.fullName : '99.13% of shipments'} icon={PackageCheck} />
        <KpiCard label="Late delivery" value={`${(100 - otd).toFixed(2)}%`} note="Delivered shipment denominator" icon={Clock3} tone="red" />
        <KpiCard label="Average delay" value={`${delay.toFixed(2)} days`} note="Across eligible deliveries" icon={ArrowDownRight} tone="amber" />
        <KpiCard label={selectedCarrier ? 'Average shipping cost' : 'Network lead time'} value={selectedCarrier ? currency2.format(selectedCarrier.cost) : `${executiveKpis.fulfilmentLeadTime.toFixed(2)} days`} note={selectedCarrier ? `${selectedCarrier.service} service · per shipment` : 'Order to carrier hand-off'} icon={Truck} tone="blue" />
        <KpiCard label="Exception rate" value={`${exceptions.toFixed(2)}%`} note="Shipments with exception" icon={Siren} tone={exceptions > 30 ? 'red' : 'amber'} />
      </section>

      <section className="mt-5 grid gap-5 xl:grid-cols-2">
        <Panel eyebrow="Backlog control" title="Ageing profile" detail="67% of open backlog is already 15+ days old" action={<Badge variant="destructive">688 open</Badge>}>
          <ChartContainer config={chartConfig} className="h-[300px] w-full aspect-auto">
            <ComposedChart accessibilityLayer data={backlogAgeing} margin={{ left: 0, right: 10, top: 8 }}>
              <CartesianGrid vertical={false} stroke="#e6edeb" />
              <XAxis dataKey="bucket" tickLine={false} axisLine={false} />
              <YAxis yAxisId="orders" tickLine={false} axisLine={false} width={40} />
              <YAxis yAxisId="value" orientation="right" tickFormatter={(value) => `€${compact.format(value)}`} tickLine={false} axisLine={false} width={54} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <Bar yAxisId="orders" dataKey="orders" fill="#b84732" radius={[5, 5, 0, 0]} maxBarSize={52} />
              <Line yAxisId="value" dataKey="value" type="monotone" stroke="#d58b28" strokeWidth={2.5} dot={{ fill: '#fff', r: 4, strokeWidth: 2 }} />
            </ComposedChart>
          </ChartContainer>
        </Panel>

        <Panel eyebrow="Carrier trade-off" title="Service performance vs shipping cost" detail="Express service performs strongly but costs about twice as much as economy">
          <ChartContainer config={chartConfig} className="h-[300px] w-full aspect-auto">
            <ComposedChart key={carrierId} accessibilityLayer data={carriers} margin={{ left: 0, right: 10, top: 8 }}>
              <CartesianGrid vertical={false} stroke="#e6edeb" />
              <XAxis dataKey="name" tickLine={false} axisLine={false} interval={0} angle={-18} textAnchor="end" height={62} fontSize={10} />
              <YAxis yAxisId="otd" domain={[0, 100]} tickFormatter={(value) => `${value}%`} tickLine={false} axisLine={false} width={42} />
              <YAxis yAxisId="cost" orientation="right" domain={[0, 11]} tickFormatter={(value) => `€${value}`} tickLine={false} axisLine={false} width={38} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <ReferenceLine yAxisId="otd" y={62.32} stroke="#8fa7a3" strokeDasharray="4 4" />
              <Bar yAxisId="otd" dataKey="otd" radius={[5, 5, 0, 0]} maxBarSize={36}>
                {carriers.map((carrier) => <Cell key={carrier.id} fill={serviceColours[carrier.service]} />)}
              </Bar>
              <Line yAxisId="cost" dataKey="cost" stroke="#d58b28" strokeWidth={2.2} dot={{ r: 4, fill: '#fff', strokeWidth: 2 }} />
            </ComposedChart>
          </ChartContainer>
        </Panel>
      </section>

      <Panel className="mt-5" eyebrow="Network comparison" title="Warehouse delivery matrix" detail="Sorted from lowest to highest on-time delivery">
        <Table>
          <TableHeader><TableRow><TableHead>Warehouse</TableHead><TableHead>City</TableHead><TableHead className="text-right">Orders</TableHead><TableHead className="text-right">OTD</TableHead><TableHead className="text-right">Avg delay</TableHead><TableHead className="text-right">Exceptions</TableHead><TableHead className="text-right">Backlog</TableHead></TableRow></TableHeader>
          <TableBody>
            {rows.map((row) => (
              <TableRow key={row.id}>
                <TableCell className="font-medium">{row.fullName}</TableCell><TableCell className="text-[#6b7d79]">{row.city}</TableCell><TableCell className="text-right font-mono">{row.orders.toLocaleString('en-GB')}</TableCell><TableCell className="text-right"><Badge variant={row.otd < 60 ? 'destructive' : 'secondary'}>{row.otd.toFixed(2)}%</Badge></TableCell><TableCell className="text-right font-mono">{row.delay.toFixed(2)} d</TableCell><TableCell className="text-right font-mono">{row.exceptionRate.toFixed(2)}%</TableCell><TableCell className="text-right font-mono">{row.backlog}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Panel>
    </TabsContent>
  );
}

function InventoryDashboard() {
  const [category, setCategory] = useState('all');
  const products = useMemo(
    () => category === 'all' ? productRisk : productRisk.filter((row) => row.category === category),
    [category],
  );
  const inventorySelection = useMemo(() => ({
    stockouts: products.reduce((sum, row) => sum + row.stockouts, 0),
    belowReorder: products.reduce((sum, row) => sum + row.belowReorder, 0),
    shipped: products.reduce((sum, row) => sum + row.shipped, 0),
    averageStockoutRate: products.reduce((sum, row) => sum + row.stockoutRate, 0) / Math.max(products.length, 1),
  }), [products]);

  return (
    <TabsContent value="inventory" className="pt-5">
      <div className="flex flex-col justify-between gap-4 lg:flex-row lg:items-end">
        <PageHeading eyebrow="Stock health" title="Inventory risk" description="Prioritise products and stock positions associated with fulfilment disruption. Category selections update every watchlist metric below." />
        <div className="mb-5 w-full lg:w-auto">
          <p className="mb-1.5 text-[10px] font-semibold uppercase tracking-[0.12em] text-[#687b78]">Product category</p>
          <Select items={categorySelectItems} value={category} onValueChange={(value) => setCategory(value ?? 'all')}>
            <SelectTrigger aria-label="Product category filter" className="w-full bg-white lg:w-[260px]"><SelectValue placeholder="All product categories" /></SelectTrigger>
            <SelectContent><SelectItem value="all">All product categories</SelectItem>{categorySelectItems.slice(1).map((item) => <SelectItem key={item.value} value={item.value}>{item.label}</SelectItem>)}</SelectContent>
          </Select>
          <p className="mt-1.5 text-[11px] text-[#71817e]">{category === 'all' ? '15 priority products · all categories' : `${products.length} priority products · ${category}`}</p>
        </div>
      </div>

      <section className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
        <KpiCard label="Priority SKUs" value={products.length.toLocaleString('en-GB')} note={category === 'all' ? 'Across all categories' : category} icon={PackageSearch} />
        <KpiCard label="Watchlist stockouts" value={inventorySelection.stockouts.toLocaleString('en-GB')} note="Selected priority products" icon={AlertTriangle} tone="red" />
        <KpiCard label="Watchlist shipped" value={inventorySelection.shipped.toLocaleString('en-GB')} note="Units shipped" icon={Factory} tone="blue" />
        <KpiCard label="Avg stockout rate" value={`${inventorySelection.averageStockoutRate.toFixed(2)}%`} note="Selected priority products" icon={CircleGauge} tone="amber" />
        <KpiCard label="Below reorder" value={inventorySelection.belowReorder.toLocaleString('en-GB')} note="Selected watchlist snapshots" icon={Boxes} tone="amber" />
      </section>

      <div className="mt-3 flex flex-wrap items-center gap-x-5 gap-y-1 rounded-xl border border-[#d5e4e0] bg-[#edf5f2] px-4 py-3 text-xs text-[#526b67]">
        <span className="font-semibold text-[#163b3b]">Network benchmark</span>
        <span>67,281 units shipped</span>
        <span>0.35% stockout rate</span>
        <span>4.30 inventory turnover</span>
        <span>96.70% late rate when stockout-linked</span>
      </div>

      <section className="mt-5 grid gap-5 xl:grid-cols-[minmax(0,1.2fr)_minmax(340px,0.8fr)]">
        <Panel eyebrow="Product risk matrix" title="Demand vs stockout exposure" detail="Bubble size represents below-reorder snapshots">
          <ChartContainer config={chartConfig} className="h-[340px] w-full aspect-auto">
            <ScatterChart key={category} accessibilityLayer margin={{ left: 2, right: 12, top: 10, bottom: 8 }}>
              <CartesianGrid stroke="#e6edeb" />
              <XAxis type="number" dataKey="shipped" name="Shipped units" tickLine={false} axisLine={false} label={{ value: 'Shipped units', position: 'insideBottom', offset: -6 }} height={40} />
              <YAxis type="number" dataKey="stockoutRate" name="Stockout rate" unit="%" tickLine={false} axisLine={false} width={46} />
              <ZAxis type="number" dataKey="belowReorder" range={[70, 420]} name="Below reorder" />
              <ChartTooltip cursor={{ strokeDasharray: '4 4' }} content={<ChartTooltipContent />} />
              <Scatter data={products}>
                {products.map((row) => <Cell key={row.id} fill={categoryColours[row.category] ?? '#0b6b63'} />)}
              </Scatter>
            </ScatterChart>
          </ChartContainer>
        </Panel>

        <Panel eyebrow="Service association" title="Stock position on order date" detail="Stockout-linked orders show materially worse service outcomes">
          <div className="space-y-4">
            {stockoutAssociation.map((row, index) => (
              <div key={row.position} className={`rounded-xl border p-4 ${index === 1 ? 'border-[#e8b2a7] bg-[#fff5f2]' : 'bg-[#f6faf8]'}`}>
                <div className="flex items-center justify-between gap-4"><p className="font-semibold">{row.position}</p><Badge variant={index === 1 ? 'destructive' : 'secondary'}>{row.orders.toLocaleString('en-GB')} orders</Badge></div>
                <div className="mt-4 grid grid-cols-3 gap-3">
                  <div><p className="text-[10px] uppercase tracking-wider text-[#748480]">Late rate</p><p className="mt-1 font-mono text-lg font-semibold">{row.lateRate.toFixed(2)}%</p></div>
                  <div><p className="text-[10px] uppercase tracking-wider text-[#748480]">Delay</p><p className="mt-1 font-mono text-lg font-semibold">{row.delay.toFixed(2)}d</p></div>
                  <div><p className="text-[10px] uppercase tracking-wider text-[#748480]">Lead time</p><p className="mt-1 font-mono text-lg font-semibold">{row.leadTime.toFixed(2)}d</p></div>
                </div>
              </div>
            ))}
            <div className="rounded-xl bg-[#102f31] p-4 text-sm leading-6 text-[#c2d6d2]">
              <p className="font-semibold text-white">Analytical caution</p>
              <p className="mt-1">The SQL shows an association. Additional controls would be needed before claiming that stockouts alone caused the delay.</p>
            </div>
          </div>
        </Panel>
      </section>

      <Panel className="mt-5" eyebrow="SKU watchlist" title="Highest product stockout exposure" detail={`${products.length} priority products shown`}>
        <Table>
          <TableHeader><TableRow><TableHead>Product</TableHead><TableHead>Category</TableHead><TableHead className="text-right">Stockouts</TableHead><TableHead className="text-right">Stockout rate</TableHead><TableHead className="text-right">Below reorder</TableHead><TableHead className="text-right">Shipped units</TableHead><TableHead className="text-right">Avg stock</TableHead></TableRow></TableHeader>
          <TableBody>{products.map((row) => <TableRow key={row.id}><TableCell><p className="font-medium">{row.name}</p><p className="text-xs text-[#7a8a87]">{row.id}</p></TableCell><TableCell>{row.category}</TableCell><TableCell className="text-right font-mono">{row.stockouts}</TableCell><TableCell className="text-right"><Badge variant={row.stockoutRate >= 2 ? 'destructive' : 'secondary'}>{row.stockoutRate.toFixed(2)}%</Badge></TableCell><TableCell className="text-right font-mono">{row.belowReorder}</TableCell><TableCell className="text-right font-mono">{row.shipped.toLocaleString('en-GB')}</TableCell><TableCell className="text-right font-mono">{row.averageStock.toFixed(2)}</TableCell></TableRow>)}</TableBody>
        </Table>
      </Panel>
    </TabsContent>
  );
}

function DiagnosticsDashboard({ warehouseId }: { warehouseId: string }) {
  const capacityRows = warehouseId === 'all' ? warehouseCapacity : warehouseCapacity.filter((row) => row.id === warehouseId);
  const selectedName = warehousePerformance.find((row) => row.id === warehouseId)?.name;
  const riskRows = selectedName ? highRiskOrders.filter((row) => row.warehouse === selectedName) : highRiskOrders;

  return (
    <TabsContent value="diagnostics" className="pt-5">
      <PageHeading eyebrow="Root-cause view" title="Operations diagnostics" description="Connect capacity, customer value and order-level risk to a prioritised management response." />

      <section className="grid gap-5 xl:grid-cols-2">
        <Panel eyebrow="Capacity pressure" title="Average and peak utilisation" detail="Daily capacity is based on non-cancelled orders received" action={<Badge variant="destructive">All sites peaked &gt;100%</Badge>}>
          <ChartContainer config={chartConfig} className="h-[330px] w-full aspect-auto">
            <BarChart accessibilityLayer data={capacityRows} margin={{ left: 0, right: 8, top: 8 }}>
              <CartesianGrid vertical={false} stroke="#e6edeb" />
              <XAxis dataKey="name" tickLine={false} axisLine={false} interval={0} angle={-15} textAnchor="end" height={56} fontSize={10} />
              <YAxis tickFormatter={(value) => `${value}%`} tickLine={false} axisLine={false} width={46} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <ReferenceLine y={100} stroke="#b84732" strokeDasharray="4 4" />
              <Bar dataKey="average" fill="#0b6b63" radius={[4, 4, 0, 0]} />
              <Bar dataKey="peak" fill="#d58b28" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ChartContainer>
        </Panel>

        <Panel eyebrow="Customer portfolio" title="Revenue and service by segment" detail="Enterprise customers have the highest AOV and the weakest on-time delivery">
          <ChartContainer config={chartConfig} className="h-[330px] w-full aspect-auto">
            <ComposedChart accessibilityLayer data={customerSegments} margin={{ left: 0, right: 10, top: 8 }}>
              <CartesianGrid vertical={false} stroke="#e6edeb" />
              <XAxis dataKey="segment" tickLine={false} axisLine={false} interval={0} fontSize={11} />
              <YAxis yAxisId="revenue" tickFormatter={(value) => `€${compact.format(value)}`} tickLine={false} axisLine={false} width={58} />
              <YAxis yAxisId="otd" orientation="right" domain={[0, 100]} tickFormatter={(value) => `${value}%`} tickLine={false} axisLine={false} width={46} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <Bar yAxisId="revenue" dataKey="revenue" fill="#2e6e9e" radius={[5, 5, 0, 0]} maxBarSize={54} />
              <Line yAxisId="otd" dataKey="otd" stroke="#b84732" strokeWidth={2.5} dot={{ r: 4, fill: '#fff', strokeWidth: 2 }} />
            </ComposedChart>
          </ChartContainer>
        </Panel>
      </section>

      <section className="mt-5 grid gap-5 xl:grid-cols-[minmax(0,1.4fr)_minmax(320px,0.6fr)]">
        <Panel eyebrow="Exception queue" title="Critical backlog orders" detail={`Showing ${riskRows.length} oldest high-risk records from the analytical export`} action={<Badge variant="destructive">SLA breached</Badge>}>
          <Table>
            <TableHeader><TableRow><TableHead>Order</TableHead><TableHead>Warehouse</TableHead><TableHead>Product</TableHead><TableHead>Segment</TableHead><TableHead className="text-right">Value</TableHead><TableHead className="text-right">Age</TableHead><TableHead>Status</TableHead></TableRow></TableHeader>
            <TableBody>{riskRows.map((row) => <TableRow key={row.id}><TableCell><p className="font-mono text-xs font-semibold">{row.id}</p><p className="text-[11px] text-[#7a8a87]">{row.date}</p></TableCell><TableCell>{row.warehouse}</TableCell><TableCell className="max-w-[190px] overflow-hidden text-ellipsis">{row.product}</TableCell><TableCell>{row.segment}</TableCell><TableCell className="text-right font-mono">{currency2.format(row.value)}</TableCell><TableCell className="text-right font-mono font-semibold text-[#a33a28]">{row.age}d</TableCell><TableCell><Badge variant={row.status === 'On Hold' ? 'destructive' : 'outline'}>{row.status}</Badge></TableCell></TableRow>)}</TableBody>
          </Table>
        </Panel>

        <aside className="rounded-2xl border border-[#cfe0dc] bg-[#e9f2ef] p-6">
          <div className="flex items-center gap-3">
            <span className="grid size-10 place-items-center rounded-xl bg-[#0b6b63] text-white"><ClipboardCheck className="size-5" /></span>
            <div><p className="text-[11px] font-semibold uppercase tracking-[0.13em] text-[#56706d]">Management action plan</p><h2 className="text-lg font-semibold">Recommended next moves</h2></div>
          </div>
          <div className="mt-6 space-y-3">
            {[
              ['01', 'Rebalance Cologne capacity', 'Review staffing, cut-off times and overflow routing before peak demand.'],
              ['02', 'Reassess economy routing', 'Compare service penalties with the additional cost of standard or express lanes.'],
              ['03', 'Clear aged backlog', 'Assign owners to the 464 orders aged 15+ days and validate stale statuses.'],
              ['04', 'Tune reorder levels', 'Prioritise the highest-risk SKUs using demand, lead time and warehouse stockout history.'],
            ].map(([number, title, detail]) => (
              <div key={number} className="flex gap-3 rounded-xl border border-white/70 bg-white/70 p-4">
                <span className="font-mono text-xs font-semibold text-[#0b6b63]">{number}</span>
                <div><p className="text-sm font-semibold">{title}</p><p className="mt-1 text-xs leading-5 text-[#637572]">{detail}</p></div>
              </div>
            ))}
          </div>
        </aside>
      </section>
    </TabsContent>
  );
}

export default function Home() {
  const [warehouseId, setWarehouseId] = useState('all');
  const [activeTab, setActiveTab] = useState('overview');

  return (
    <main className="min-h-screen pb-12">
      <header className="border-b border-white/10 bg-[#0d292b] text-white">
        <div className="mx-auto flex max-w-[1480px] flex-wrap items-center justify-between gap-3 px-5 py-4 lg:px-8">
          <div className="flex items-center gap-3">
            <div className="grid size-10 place-items-center rounded-xl bg-[#25a394] font-mono text-xs font-bold tracking-widest shadow-lg shadow-black/20">OT</div>
            <div><p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#8dc9c1]">Supply chain analytics</p><p className="text-base font-semibold tracking-tight">Operations Control Tower</p></div>
          </div>
          <div className="flex flex-wrap items-center gap-x-5 gap-y-2 text-xs text-[#b9d4d0]">
            <a href="https://github.com/Akshayamin13" className="rounded-sm font-medium text-white underline decoration-[#648d87] underline-offset-4 hover:text-[#8dc9c1] focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-white">Akshay Amin</a>
            <a href="https://github.com/Akshayamin13/supply-chain-operations-control-tower" className="rounded-sm underline decoration-[#648d87] underline-offset-4 hover:text-white focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-white">Project &amp; SQL</a>
            <span className="hidden items-center gap-2 sm:flex"><span className="size-2 rounded-full bg-[#58c6a8] shadow-[0_0_0_4px_rgb(88_198_168/12%)]" />Synthetic snapshot · 01 Sep 2026</span>
          </div>
        </div>
      </header>

      <div className="mx-auto max-w-[1480px] px-5 pt-5 lg:px-8">
        <Tabs value={activeTab} onValueChange={(value) => setActiveTab(value ?? 'overview')}>
          <div className="flex flex-col justify-between gap-3 rounded-2xl border border-[#d8e3e0] bg-white/90 p-3 shadow-sm backdrop-blur sm:flex-row sm:items-center">
            <TabsList variant="line" className="h-auto w-full justify-start overflow-x-auto sm:w-auto">
              <TabsTrigger value="overview" className="px-3 py-2"><Gauge /> Overview</TabsTrigger>
              <TabsTrigger value="fulfilment" className="px-3 py-2"><Truck /> Fulfilment</TabsTrigger>
              <TabsTrigger value="inventory" className="px-3 py-2"><Warehouse /> Inventory</TabsTrigger>
              <TabsTrigger value="diagnostics" className="px-3 py-2"><DatabaseZap /> Diagnostics</TabsTrigger>
            </TabsList>
            <div className="flex flex-wrap items-center gap-2">
              <span className="hidden items-center gap-2 rounded-lg bg-[#edf4f2] px-3 py-2 text-xs text-[#526b67] md:flex"><CalendarDays className="size-4 text-[#0b6b63]" />Sep 2025 – Aug 2026</span>
              {activeTab === 'inventory' ? (
                <span className="flex items-center gap-2 rounded-lg bg-[#edf4f2] px-3 py-2 text-xs font-medium text-[#526b67]"><Warehouse className="size-4 text-[#0b6b63]" />Network-level inventory snapshots</span>
              ) : (
                <Select items={warehouseSelectItems} value={warehouseId} onValueChange={(value) => setWarehouseId(value ?? 'all')}>
                  <SelectTrigger aria-label="Warehouse filter" className="w-[260px] bg-white"><SelectValue placeholder="All warehouses" /></SelectTrigger>
                  <SelectContent><SelectItem value="all">All warehouses</SelectItem>{warehousePerformance.map((warehouse) => <SelectItem key={warehouse.id} value={warehouse.id}>{warehouse.id} · {warehouse.name} · {warehouse.city}</SelectItem>)}</SelectContent>
                </Select>
              )}
            </div>
          </div>

          <ExecutiveOverview warehouseId={warehouseId} />
          <FulfilmentDashboard warehouseId={warehouseId} />
          <InventoryDashboard />
          <DiagnosticsDashboard warehouseId={warehouseId} />
        </Tabs>

        <footer className="mt-8 flex flex-col justify-between gap-3 border-t border-[#d8e3e0] pt-5 text-xs text-[#6d807c] sm:flex-row sm:items-center">
          <div className="space-y-1">
            <p>Built by <a href="https://github.com/Akshayamin13" className="font-medium text-[#163b3b] underline underline-offset-4">Akshay Amin</a> · Analyst portfolio case study.</p>
            <p>All records and business outcomes are synthetic. <a href="https://github.com/Akshayamin13/supply-chain-operations-control-tower/blob/main/LICENSE" className="underline underline-offset-4">MIT License</a></p>
          </div>
          <div className="flex items-center gap-4"><span className="flex items-center gap-1.5"><ShieldCheck className="size-4 text-[#0b6b63]" />28 SQL quality checks passed</span><span className="flex items-center gap-1.5"><ShoppingCart className="size-4 text-[#0b6b63]" />30,000 source orders</span><ChevronRight className="size-4" /></div>
        </footer>
      </div>
    </main>
  );
}
