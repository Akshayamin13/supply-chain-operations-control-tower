#!/usr/bin/env python3
"""Generate a deterministic, source-like supply-chain dataset.

The coherent scenario is created first. A small number of controlled defects are
then injected into copies written to data/raw so SQL cleaning can be demonstrated.
No third-party Python packages are required.
"""

from __future__ import annotations

import csv
import hashlib
import json
import random
from collections import Counter, defaultdict
from datetime import date, timedelta
from pathlib import Path
from typing import Any, Dict, Iterable, List, Sequence, Tuple


SEED = 20260901
START_DATE = date(2025, 9, 1)
END_DATE = date(2026, 8, 31)
ANALYSIS_DATE = date(2026, 9, 1)
ORDER_COUNT = 30_000
CUSTOMER_COUNT = 4_000
PRODUCT_COUNT = 120

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = PROJECT_ROOT / "data" / "raw"
MANIFEST_PATH = PROJECT_ROOT / "data" / "quality_manifest.json"

RNG = random.Random(SEED)
QUALITY_RNG = random.Random(SEED + 1)


def iso(value: date | None) -> str:
    return value.isoformat() if value else ""


def money(value: float) -> str:
    return f"{value:.2f}"


def decimal4(value: float) -> str:
    return f"{value:.4f}"


def write_csv(path: Path, columns: Sequence[str], rows: Iterable[Dict[str, Any]]) -> int:
    count = 0
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow(row)
            count += 1
    return count


def allocate_disjoint_indices(total: int, named_counts: Dict[str, int]) -> Dict[str, set[int]]:
    required = sum(named_counts.values())
    if required > total:
        raise ValueError("Requested more quality cases than available rows")
    chosen = QUALITY_RNG.sample(range(total), required)
    result: Dict[str, set[int]] = {}
    cursor = 0
    for name, count in named_counts.items():
        result[name] = set(chosen[cursor : cursor + count])
        cursor += count
    return result


def all_dates(start: date, end: date) -> List[date]:
    return [start + timedelta(days=offset) for offset in range((end - start).days + 1)]


def generate_warehouses() -> List[Dict[str, Any]]:
    return [
        {"warehouse_id": "WH-001", "warehouse_name": "Spree Fulfilment Centre", "city": "Berlin", "country": "DE", "storage_capacity_units": 48_000, "daily_order_capacity": 19},
        {"warehouse_id": "WH-002", "warehouse_name": "Elbe North Hub", "city": "Hamburg", "country": "DE", "storage_capacity_units": 39_000, "daily_order_capacity": 15},
        {"warehouse_id": "WH-003", "warehouse_name": "Rhine-Ruhr Fulfilment Centre", "city": "Cologne", "country": "DE", "storage_capacity_units": 46_000, "daily_order_capacity": 18},
        {"warehouse_id": "WH-004", "warehouse_name": "Main Central Hub", "city": "Frankfurt", "country": "DE", "storage_capacity_units": 55_000, "daily_order_capacity": 24},
        {"warehouse_id": "WH-005", "warehouse_name": "Isar South Centre", "city": "Munich", "country": "DE", "storage_capacity_units": 34_000, "daily_order_capacity": 13},
        {"warehouse_id": "WH-006", "warehouse_name": "Saxony Distribution Hub", "city": "Leipzig", "country": "DE", "storage_capacity_units": 42_000, "daily_order_capacity": 17},
    ]


def generate_carriers() -> List[Dict[str, Any]]:
    return [
        {"carrier_id": "CAR-01", "carrier_name": "RheinParcel", "service_level": "Standard", "base_transit_days": 2, "risk": 0.07, "cost_factor": 1.00},
        {"carrier_id": "CAR-02", "carrier_name": "Nordstern Logistics", "service_level": "Standard", "base_transit_days": 2, "risk": 0.09, "cost_factor": 0.96},
        {"carrier_id": "CAR-03", "carrier_name": "Mainline Express", "service_level": "Express", "base_transit_days": 1, "risk": 0.045, "cost_factor": 1.42},
        {"carrier_id": "CAR-04", "carrier_name": "Alpine Freight", "service_level": "Economy", "base_transit_days": 3, "risk": 0.18, "cost_factor": 0.83},
        {"carrier_id": "CAR-05", "carrier_name": "Elbe Courier", "service_level": "Standard", "base_transit_days": 2, "risk": 0.08, "cost_factor": 1.02},
        {"carrier_id": "CAR-06", "carrier_name": "EuroLink Standard", "service_level": "Economy", "base_transit_days": 3, "risk": 0.14, "cost_factor": 0.86},
        {"carrier_id": "CAR-07", "carrier_name": "RapidRoute", "service_level": "Express", "base_transit_days": 1, "risk": 0.055, "cost_factor": 1.38},
    ]


def generate_products() -> Tuple[List[Dict[str, Any]], List[float]]:
    category_specs = [
        ("Electronics", 34.0, 95.0, 0.8),
        ("Home & Kitchen", 12.0, 38.0, 1.5),
        ("Personal Care", 5.0, 19.0, 0.35),
        ("Sports & Outdoors", 16.0, 52.0, 1.2),
        ("Office Supplies", 4.0, 14.0, 0.45),
        ("Accessories", 7.0, 24.0, 0.25),
    ]
    product_labels = {
        "Electronics": ["Wireless Mouse", "USB-C Hub", "Bluetooth Speaker", "Webcam", "Mechanical Keyboard"],
        "Home & Kitchen": ["Storage Set", "Coffee Press", "Desk Lamp", "Kitchen Scale", "Water Bottle"],
        "Personal Care": ["Electric Toothbrush", "Grooming Kit", "Skin Care Set", "Hair Dryer", "Massage Roller"],
        "Sports & Outdoors": ["Yoga Mat", "Resistance Bands", "Hiking Bottle", "Training Bag", "Fitness Tracker Band"],
        "Office Supplies": ["Notebook Set", "Desk Organiser", "Printer Paper", "Marker Set", "Laptop Stand"],
        "Accessories": ["Phone Stand", "Cable Set", "Travel Adapter", "Protective Sleeve", "Charging Pouch"],
    }
    products: List[Dict[str, Any]] = []
    demand_weights: List[float] = []
    product_number = 1
    for category, min_cost, max_cost, base_weight in category_specs:
        for category_index in range(20):
            cost = RNG.uniform(min_cost, max_cost)
            margin = RNG.uniform(1.45, 2.25)
            price = round(cost * margin, 2)
            popularity = 2.8 if category_index < 2 else 1.8 if category_index < 6 else RNG.uniform(0.65, 1.35)
            products.append(
                {
                    "product_id": f"PRD-{product_number:04d}",
                    "product_name": f"{product_labels[category][category_index % 5]} {category_index + 1:02d}",
                    "product_category": category,
                    "unit_cost_eur": money(cost),
                    "unit_price_eur": money(price),
                    "weight_kg": money(max(0.08, RNG.uniform(base_weight * 0.45, base_weight * 1.75))),
                    "supplier_lead_time_days": RNG.randint(3, 14),
                    "_demand_weight": popularity,
                }
            )
            demand_weights.append(popularity)
            product_number += 1
    return products, demand_weights


def generate_customers() -> List[Dict[str, Any]]:
    locations = [
        ("Berlin", "DE", 18), ("Hamburg", "DE", 10), ("Munich", "DE", 11),
        ("Cologne", "DE", 9), ("Frankfurt", "DE", 9), ("Leipzig", "DE", 6),
        ("Stuttgart", "DE", 7), ("Düsseldorf", "DE", 7), ("Vienna", "AT", 5),
        ("Amsterdam", "NL", 4), ("Brussels", "BE", 3), ("Paris", "FR", 4),
        ("Warsaw", "PL", 4), ("Prague", "CZ", 3),
    ]
    segments = ["Consumer", "Small Business", "Mid-Market", "Enterprise"]
    segment_weights = [64, 23, 9, 4]
    customers: List[Dict[str, Any]] = []
    for customer_number in range(1, CUSTOMER_COUNT + 1):
        city, country, _ = RNG.choices(locations, weights=[item[2] for item in locations], k=1)[0]
        segment = RNG.choices(segments, weights=segment_weights, k=1)[0]
        signup = START_DATE - timedelta(days=RNG.randint(30, 1_450))
        customers.append(
            {
                "customer_id": f"CUST-{customer_number:05d}",
                "customer_name": f"Synthetic Customer {customer_number:05d}",
                "customer_segment": segment,
                "city": city,
                "country": country,
                "signup_date": iso(signup),
            }
        )
    return customers


def weighted_order_dates() -> Tuple[List[date], List[float]]:
    month_factors = {
        (2025, 9): 0.92, (2025, 10): 1.02, (2025, 11): 1.32, (2025, 12): 1.58,
        (2026, 1): 0.88, (2026, 2): 0.93, (2026, 3): 1.00, (2026, 4): 1.04,
        (2026, 5): 1.08, (2026, 6): 1.00, (2026, 7): 0.94, (2026, 8): 1.03,
    }
    dates = all_dates(START_DATE, END_DATE)
    weights = []
    for value in dates:
        weekday_factor = 1.0 if value.weekday() < 5 else 0.62
        weights.append(month_factors[(value.year, value.month)] * weekday_factor)
    return dates, weights


def order_quantity(segment: str) -> int:
    if segment == "Enterprise":
        return RNG.choices([2, 4, 6, 8, 10, 15, 20], weights=[5, 12, 18, 20, 20, 15, 10], k=1)[0]
    if segment == "Mid-Market":
        return RNG.choices([1, 2, 3, 4, 5, 8, 10], weights=[8, 18, 24, 20, 14, 10, 6], k=1)[0]
    if segment == "Small Business":
        return RNG.choices([1, 2, 3, 4, 5, 6], weights=[24, 31, 20, 13, 8, 4], k=1)[0]
    return RNG.choices([1, 2, 3, 4, 5], weights=[62, 24, 9, 4, 1], k=1)[0]


def initial_order_status(order_date: date) -> str:
    age = (ANALYSIS_DATE - order_date).days
    cancellation = 0.026
    roll = RNG.random()
    if roll < cancellation:
        return "Cancelled"
    if age <= 2:
        return RNG.choices(["Delivered", "In Transit", "Packed", "Processing", "On Hold"], weights=[20, 28, 20, 22, 10], k=1)[0]
    if age <= 7:
        return RNG.choices(["Delivered", "In Transit", "Packed", "Processing", "On Hold"], weights=[61, 20, 7, 7, 5], k=1)[0]
    if age <= 21:
        return RNG.choices(["Delivered", "In Transit", "Packed", "Processing", "On Hold"], weights=[91, 3, 1, 3, 2], k=1)[0]
    return RNG.choices(["Delivered", "Processing", "On Hold"], weights=[98.5, 0.9, 0.6], k=1)[0]


def generate_orders(
    products: List[Dict[str, Any]],
    product_weights: List[float],
    customers: List[Dict[str, Any]],
    warehouses: List[Dict[str, Any]],
) -> List[Dict[str, Any]]:
    dates, date_weights = weighted_order_dates()
    warehouse_weights = [18, 14, 20, 22, 11, 15]
    orders: List[Dict[str, Any]] = []
    for order_number in range(1, ORDER_COUNT + 1):
        customer = RNG.choice(customers)
        product = RNG.choices(products, weights=product_weights, k=1)[0]
        warehouse = RNG.choices(warehouses, weights=warehouse_weights, k=1)[0]
        order_date = RNG.choices(dates, weights=date_weights, k=1)[0]
        if order_number == 1:
            order_date = START_DATE
        elif order_number == 2:
            order_date = END_DATE
        quantity = order_quantity(customer["customer_segment"])
        price = float(product["unit_price_eur"])
        discount_ranges = {
            "Consumer": (0.00, 0.06),
            "Small Business": (0.02, 0.09),
            "Mid-Market": (0.04, 0.12),
            "Enterprise": (0.07, 0.16),
        }
        low_discount, high_discount = discount_ranges[customer["customer_segment"]]
        discount = round(RNG.uniform(low_discount, high_discount), 4)
        cross_border_days = 1 if customer["country"] != "DE" else 0
        promise_days = RNG.choices([2, 3, 4, 5], weights=[12, 44, 31, 13], k=1)[0] + cross_border_days
        promised_date = order_date + timedelta(days=promise_days)
        channel = RNG.choices(
            ["Online Store", "Marketplace", "EDI", "Sales Desk"],
            weights=[63, 20, 9, 8] if customer["customer_segment"] == "Consumer" else [30, 12, 31, 27],
            k=1,
        )[0]
        status = initial_order_status(order_date)
        orders.append(
            {
                "order_id": f"ORD-{order_number:06d}",
                "customer_id": customer["customer_id"],
                "product_id": product["product_id"],
                "warehouse_id": warehouse["warehouse_id"],
                "order_date": iso(order_date),
                "promised_delivery_date": iso(promised_date),
                "order_status": status,
                "order_quantity": quantity,
                "unit_price_eur": product["unit_price_eur"],
                "discount_pct": decimal4(discount),
                "order_value_eur": money(quantity * price * (1 - discount)),
                "sales_channel": channel,
            }
        )
    return orders


def generate_inventory(
    orders: List[Dict[str, Any]],
    products: List[Dict[str, Any]],
    warehouses: List[Dict[str, Any]],
) -> Tuple[int, set[Tuple[str, str, str]], Dict[str, int]]:
    demand: Dict[Tuple[str, str, str], int] = defaultdict(int)
    for order in orders:
        if order["order_status"] != "Cancelled":
            demand[(order["order_date"], order["warehouse_id"], order["product_id"])] += int(order["order_quantity"])

    row_total = len(all_dates(START_DATE, END_DATE)) * len(warehouses) * len(products)
    quality_sets = allocate_disjoint_indices(
        row_total,
        {"missing_product_id": 15, "negative_closing_stock": 20, "balance_mismatch_only": 40, "duplicate_rows": 80},
    )
    inventory_path = RAW_DIR / "inventory.csv"
    columns = [
        "inventory_date", "warehouse_id", "product_id", "opening_stock",
        "received_quantity", "shipped_quantity", "closing_stock", "reorder_level",
    ]
    stock_by_pair: Dict[Tuple[str, str], int] = {}
    reorder_by_pair: Dict[Tuple[str, str], int] = {}
    for warehouse in warehouses:
        for product in products:
            popularity = float(product["_demand_weight"])
            reorder_level = max(4, round(5 + popularity * RNG.uniform(2.0, 4.0)))
            pair = (warehouse["warehouse_id"], product["product_id"])
            reorder_by_pair[pair] = reorder_level
            stock_by_pair[pair] = round(reorder_level * RNG.uniform(1.4, 2.3))

    stockout_keys: set[Tuple[str, str, str]] = set()
    written = 0
    canonical_index = 0
    with inventory_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        for snapshot_date in all_dates(START_DATE, END_DATE):
            for warehouse in warehouses:
                for product in products:
                    pair = (warehouse["warehouse_id"], product["product_id"])
                    opening = stock_by_pair[pair]
                    reorder_level = reorder_by_pair[pair]
                    stressed = (
                        warehouse["warehouse_id"] == "WH-003"
                        and product["product_category"] == "Electronics"
                        and snapshot_date.month in {11, 12}
                    ) or (
                        warehouse["warehouse_id"] == "WH-005"
                        and product["product_category"] == "Personal Care"
                        and snapshot_date.month in {1, 2}
                    )
                    receive_probability = 0.10 if stressed else 0.23
                    received = 0
                    if opening <= reorder_level and RNG.random() < receive_probability:
                        received = round(reorder_level * RNG.uniform(1.7, 3.0))
                    elif RNG.random() < 0.004:
                        received = round(reorder_level * RNG.uniform(1.2, 2.0))
                    requested = demand.get((iso(snapshot_date), warehouse["warehouse_id"], product["product_id"]), 0)
                    shipped = min(requested, opening + received)
                    closing = opening + received - shipped
                    if requested > shipped or (closing == 0 and requested > 0):
                        stockout_keys.add((iso(snapshot_date), warehouse["warehouse_id"], product["product_id"]))
                    stock_by_pair[pair] = closing
                    row = {
                        "inventory_date": iso(snapshot_date),
                        "warehouse_id": warehouse["warehouse_id"],
                        "product_id": product["product_id"],
                        "opening_stock": opening,
                        "received_quantity": received,
                        "shipped_quantity": shipped,
                        "closing_stock": closing,
                        "reorder_level": reorder_level,
                    }
                    if canonical_index in quality_sets["missing_product_id"]:
                        row["product_id"] = ""
                    elif canonical_index in quality_sets["negative_closing_stock"]:
                        row["closing_stock"] = -5
                    elif canonical_index in quality_sets["balance_mismatch_only"]:
                        row["closing_stock"] = int(row["closing_stock"]) + 7
                    writer.writerow(row)
                    written += 1
                    if canonical_index in quality_sets["duplicate_rows"]:
                        writer.writerow(dict(row))
                        written += 1
                    canonical_index += 1
    expected = {
        "canonical_rows": row_total,
        "duplicate_extra_rows": 80,
        "missing_product_id": 15,
        "negative_closing_stock": 20,
        "balance_mismatch": 60,
    }
    return written, stockout_keys, expected


def generate_shipments(
    orders: List[Dict[str, Any]],
    products_by_id: Dict[str, Dict[str, Any]],
    customers_by_id: Dict[str, Dict[str, Any]],
    warehouses_by_id: Dict[str, Dict[str, Any]],
    carriers: List[Dict[str, Any]],
    stockout_keys: set[Tuple[str, str, str]],
) -> List[Dict[str, Any]]:
    daily_order_counts = Counter((order["order_date"], order["warehouse_id"]) for order in orders if order["order_status"] != "Cancelled")
    carrier_weights = [22, 18, 13, 13, 14, 11, 9]
    shipments: List[Dict[str, Any]] = []
    shipment_number = 1
    for order in orders:
        if order["order_status"] in {"Cancelled", "Processing", "Packed", "On Hold"}:
            continue
        carrier = RNG.choices(carriers, weights=carrier_weights, k=1)[0]
        warehouse = warehouses_by_id[order["warehouse_id"]]
        customer = customers_by_id[order["customer_id"]]
        product = products_by_id[order["product_id"]]
        order_date = date.fromisoformat(order["order_date"])
        promised_date = date.fromisoformat(order["promised_delivery_date"])
        stockout = (order["order_date"], order["warehouse_id"], order["product_id"]) in stockout_keys
        utilisation = daily_order_counts[(order["order_date"], order["warehouse_id"])] / int(warehouse["daily_order_capacity"])

        handling_days = 1
        exception_reason = ""
        if stockout:
            handling_days += RNG.randint(2, 5)
            if RNG.random() < 0.82:
                exception_reason = "Inventory Shortage"
        if utilisation > 1.0 and RNG.random() < min(0.78, 0.35 + (utilisation - 1.0)):
            handling_days += RNG.randint(1, 3)
            if not exception_reason:
                exception_reason = "Warehouse Capacity"
        if order["warehouse_id"] in {"WH-001", "WH-003"} and RNG.random() < 0.10:
            handling_days += 1

        ship_date = order_date + timedelta(days=handling_days)
        international_days = 1 if customer["country"] != "DE" else 0
        transit_days = int(carrier["base_transit_days"]) + international_days
        if RNG.random() < float(carrier["risk"]):
            transit_days += RNG.randint(1, 4)
            if not exception_reason:
                exception_reason = "Carrier Delay"
        if order_date.month in {12, 1, 2} and RNG.random() < 0.045:
            transit_days += RNG.randint(1, 3)
            if not exception_reason:
                exception_reason = "Weather"
        if not exception_reason:
            other_roll = RNG.random()
            if other_roll < 0.010:
                exception_reason = "Address Issue"
                transit_days += 1
            elif other_roll < 0.016:
                exception_reason = "System Error"
                handling_days += 1
                ship_date += timedelta(days=1)
            elif other_roll < 0.022:
                exception_reason = "Damaged Shipment"
                transit_days += 2
            elif other_roll < 0.029:
                exception_reason = "Customer Request"
                transit_days += 1

        actual_delivery = ship_date + timedelta(days=transit_days)
        status = order["order_status"]
        if status == "Delivered" and actual_delivery >= ANALYSIS_DATE:
            status = "In Transit"
            order["order_status"] = "In Transit"
        if status == "In Transit":
            actual_value: date | None = None
        else:
            actual_value = actual_delivery
        shipment_status = "Delivered" if actual_value else "In Transit"

        quantity = int(order["order_quantity"])
        weight = float(product["weight_kg"]) * quantity
        shipping_cost = (3.2 + weight * 0.62 + international_days * 2.8) * float(carrier["cost_factor"])
        if carrier["service_level"] == "Express":
            shipping_cost += 2.2
        shipments.append(
            {
                "shipment_id": f"SHP-{shipment_number:06d}",
                "order_id": order["order_id"],
                "carrier_id": carrier["carrier_id"],
                "ship_date": iso(ship_date),
                "actual_delivery_date": iso(actual_value),
                "shipment_status": shipment_status,
                "shipping_cost_eur": money(shipping_cost),
                "exception_reason": exception_reason,
                "_promised_delivery_date": iso(promised_date),
            }
        )
        shipment_number += 1
    return shipments


def inject_product_quality(products: List[Dict[str, Any]]) -> Dict[str, int]:
    dirty_indices = set(QUALITY_RNG.sample(range(len(products)), 12))
    variants = {
        "Electronics": "electronics",
        "Home & Kitchen": "Home and Kitchen",
        "Personal Care": "Personal care ",
        "Sports & Outdoors": "Sports and Outdoors",
        "Office Supplies": "office supplies",
        "Accessories": "ACCESSORIES",
    }
    for index in dirty_indices:
        products[index]["product_category"] = variants[products[index]["product_category"]]
    return {"noncanonical_category": len(dirty_indices)}


def inject_order_quality(orders: List[Dict[str, Any]]) -> Tuple[List[Dict[str, Any]], Dict[str, int]]:
    raw_orders = [dict(order) for order in orders]
    quality_sets = allocate_disjoint_indices(
        len(raw_orders),
        {
            "missing_customer_id": 20,
            "missing_product_id": 18,
            "missing_warehouse_id": 24,
            "unmapped_warehouse_id": 10,
            "negative_quantity": 25,
            "promised_before_order": 30,
            "noncanonical_status": 45,
        },
    )
    status_variants = ["delivered ", "PROCESSING", "dispatchd", "cancel", "On-Hold"]
    for index, row in enumerate(raw_orders):
        if index in quality_sets["missing_customer_id"]:
            row["customer_id"] = ""
        elif index in quality_sets["missing_product_id"]:
            row["product_id"] = ""
        elif index in quality_sets["missing_warehouse_id"]:
            row["warehouse_id"] = ""
        elif index in quality_sets["unmapped_warehouse_id"]:
            row["warehouse_id"] = "WH-999"
        elif index in quality_sets["negative_quantity"]:
            row["order_quantity"] = -abs(int(row["order_quantity"]))
        elif index in quality_sets["promised_before_order"]:
            order_date = date.fromisoformat(row["order_date"])
            row["promised_delivery_date"] = iso(order_date - timedelta(days=2))
        elif index in quality_sets["noncanonical_status"]:
            row["order_status"] = status_variants[index % len(status_variants)]
    injected_indices = set().union(*quality_sets.values())
    duplicate_candidates = sorted(set(range(len(raw_orders))) - injected_indices)
    duplicate_indices = QUALITY_RNG.sample(duplicate_candidates, 60)
    raw_orders.extend(dict(raw_orders[index]) for index in duplicate_indices)
    expected = {name: len(indices) for name, indices in quality_sets.items()}
    expected["canonical_rows"] = len(orders)
    expected["duplicate_extra_rows"] = len(duplicate_indices)
    return raw_orders, expected


def inject_shipment_quality(shipments: List[Dict[str, Any]]) -> Tuple[List[Dict[str, Any]], Dict[str, int]]:
    raw_shipments = [dict(shipment) for shipment in shipments]
    all_indices = set(range(len(raw_shipments)))
    delivered_indices = {index for index, row in enumerate(raw_shipments) if row["actual_delivery_date"]}
    before_delivery = set(QUALITY_RNG.sample(sorted(delivered_indices), 35))
    remaining = sorted(all_indices - before_delivery)
    selected = QUALITY_RNG.sample(remaining, 35 + 12 + 30)
    missing_carrier = set(selected[:35])
    orphan_order = set(selected[35:47])
    noncanonical_status = set(selected[47:77])
    status_variants = ["delivered ", "IN TRANSIT", "in-transit"]
    for index, row in enumerate(raw_shipments):
        if index in before_delivery:
            ship_date = date.fromisoformat(row["ship_date"])
            row["actual_delivery_date"] = iso(ship_date - timedelta(days=1))
        elif index in missing_carrier:
            row["carrier_id"] = ""
        elif index in orphan_order:
            row["order_id"] = f"ORD-ORPHAN-{index:05d}"
        elif index in noncanonical_status:
            row["shipment_status"] = status_variants[index % len(status_variants)]
    injected_indices = before_delivery | missing_carrier | orphan_order | noncanonical_status
    duplicate_candidates = sorted(set(range(len(raw_shipments))) - injected_indices)
    duplicate_indices = QUALITY_RNG.sample(duplicate_candidates, 50)
    raw_shipments.extend(dict(raw_shipments[index]) for index in duplicate_indices)
    expected = {
        "canonical_rows": len(shipments),
        "duplicate_extra_rows": len(duplicate_indices),
        "missing_carrier_id": len(missing_carrier),
        "orphan_order_id": len(orphan_order),
        "delivery_before_ship": len(before_delivery),
        "noncanonical_status": len(noncanonical_status),
    }
    return raw_shipments, expected


def checksums(csv_paths: List[Path]) -> None:
    lines = []
    for path in sorted(csv_paths, key=lambda item: item.name):
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        lines.append(f"{digest}  {path.name}")
    (RAW_DIR / "SHA256SUMS.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    warehouses = generate_warehouses()
    carriers = generate_carriers()
    products, product_weights = generate_products()
    customers = generate_customers()
    orders = generate_orders(products, product_weights, customers, warehouses)

    products_by_id = {row["product_id"]: row for row in products}
    customers_by_id = {row["customer_id"]: row for row in customers}
    warehouses_by_id = {row["warehouse_id"]: row for row in warehouses}

    inventory_rows, stockout_keys, inventory_quality = generate_inventory(orders, products, warehouses)
    shipments = generate_shipments(
        orders,
        products_by_id,
        customers_by_id,
        warehouses_by_id,
        carriers,
        stockout_keys,
    )

    raw_products = [dict(row) for row in products]
    product_quality = inject_product_quality(raw_products)
    raw_orders, order_quality = inject_order_quality(orders)
    raw_shipments, shipment_quality = inject_shipment_quality(shipments)

    columns = {
        "products": ["product_id", "product_name", "product_category", "unit_cost_eur", "unit_price_eur", "weight_kg", "supplier_lead_time_days"],
        "warehouses": ["warehouse_id", "warehouse_name", "city", "country", "storage_capacity_units", "daily_order_capacity"],
        "carriers": ["carrier_id", "carrier_name", "service_level", "base_transit_days"],
        "customers": ["customer_id", "customer_name", "customer_segment", "city", "country", "signup_date"],
        "orders": ["order_id", "customer_id", "product_id", "warehouse_id", "order_date", "promised_delivery_date", "order_status", "order_quantity", "unit_price_eur", "discount_pct", "order_value_eur", "sales_channel"],
        "shipments": ["shipment_id", "order_id", "carrier_id", "ship_date", "actual_delivery_date", "shipment_status", "shipping_cost_eur", "exception_reason"],
    }
    row_counts = {
        "products": write_csv(RAW_DIR / "products.csv", columns["products"], raw_products),
        "warehouses": write_csv(RAW_DIR / "warehouses.csv", columns["warehouses"], warehouses),
        "carriers": write_csv(RAW_DIR / "carriers.csv", columns["carriers"], carriers),
        "customers": write_csv(RAW_DIR / "customers.csv", columns["customers"], customers),
        "orders": write_csv(RAW_DIR / "orders.csv", columns["orders"], raw_orders),
        "shipments": write_csv(RAW_DIR / "shipments.csv", columns["shipments"], raw_shipments),
        "inventory": inventory_rows,
    }

    manifest = {
        "seed": SEED,
        "analysis_period": {"start": iso(START_DATE), "end": iso(END_DATE), "analysis_date": iso(ANALYSIS_DATE)},
        "source_row_counts": row_counts,
        "expected_quality_issues": {
            "products": product_quality,
            "orders": order_quality,
            "shipments": shipment_quality,
            "inventory": inventory_quality,
        },
        "synthetic_data_notice": "All records and organisations are fictional. Performance results describe only this simulated scenario.",
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    csv_paths = [RAW_DIR / f"{name}.csv" for name in ["products", "warehouses", "carriers", "customers", "orders", "shipments", "inventory"]]
    checksums(csv_paths)
    print(json.dumps({"row_counts": row_counts, "stockout_event_keys": len(stockout_keys)}, indent=2))


if __name__ == "__main__":
    main()
