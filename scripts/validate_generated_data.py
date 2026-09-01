#!/usr/bin/env python3
"""Validate generated CSV structure, row counts, relationships, and injected defects."""

from __future__ import annotations

import csv
import json
from collections import Counter
from datetime import date
from pathlib import Path
from typing import Any, Dict, Iterable, List


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = PROJECT_ROOT / "data" / "raw"
MANIFEST_PATH = PROJECT_ROOT / "data" / "quality_manifest.json"
PROFILE_PATH = PROJECT_ROOT / "data" / "data_profile.json"

CANONICAL_ORDER_STATUSES = {"Delivered", "In Transit", "Packed", "Processing", "On Hold", "Cancelled"}
CANONICAL_SHIPMENT_STATUSES = {"Delivered", "In Transit"}
CANONICAL_CATEGORIES = {"Electronics", "Home & Kitchen", "Personal Care", "Sports & Outdoors", "Office Supplies", "Accessories"}


def read_rows(name: str) -> List[Dict[str, str]]:
    with (RAW_DIR / f"{name}.csv").open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def duplicate_extras(values: Iterable[Any]) -> int:
    values_list = list(values)
    return len(values_list) - len(set(values_list))


def compare_expected(actual: Dict[str, Dict[str, int]], expected: Dict[str, Dict[str, int]]) -> List[str]:
    failures = []
    for table, expected_checks in expected.items():
        for check_name, expected_count in expected_checks.items():
            if check_name == "canonical_rows":
                continue
            actual_count = actual.get(table, {}).get(check_name)
            if actual_count != expected_count:
                failures.append(f"{table}.{check_name}: expected {expected_count}, found {actual_count}")
    return failures


def main() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    products = read_rows("products")
    warehouses = read_rows("warehouses")
    carriers = read_rows("carriers")
    customers = read_rows("customers")
    orders = read_rows("orders")
    shipments = read_rows("shipments")
    inventory = read_rows("inventory")

    product_ids = {row["product_id"] for row in products if row["product_id"]}
    warehouse_ids = {row["warehouse_id"] for row in warehouses if row["warehouse_id"]}
    carrier_ids = {row["carrier_id"] for row in carriers if row["carrier_id"]}
    customer_ids = {row["customer_id"] for row in customers if row["customer_id"]}
    order_ids = {row["order_id"] for row in orders if row["order_id"]}

    actual: Dict[str, Dict[str, int]] = {
        "products": {
            "noncanonical_category": sum(row["product_category"] not in CANONICAL_CATEGORIES for row in products),
        },
        "orders": {
            "duplicate_extra_rows": duplicate_extras(row["order_id"] for row in orders),
            "missing_customer_id": sum(not row["customer_id"] for row in orders),
            "missing_product_id": sum(not row["product_id"] for row in orders),
            "missing_warehouse_id": sum(not row["warehouse_id"] for row in orders),
            "unmapped_warehouse_id": sum(bool(row["warehouse_id"]) and row["warehouse_id"] not in warehouse_ids for row in orders),
            "negative_quantity": sum(int(row["order_quantity"]) < 0 for row in orders),
            "promised_before_order": sum(date.fromisoformat(row["promised_delivery_date"]) < date.fromisoformat(row["order_date"]) for row in orders),
            "noncanonical_status": sum(row["order_status"] not in CANONICAL_ORDER_STATUSES for row in orders),
        },
        "shipments": {
            "duplicate_extra_rows": duplicate_extras(row["shipment_id"] for row in shipments),
            "missing_carrier_id": sum(not row["carrier_id"] for row in shipments),
            "orphan_order_id": sum(row["order_id"] not in order_ids for row in shipments),
            "delivery_before_ship": sum(bool(row["actual_delivery_date"]) and date.fromisoformat(row["actual_delivery_date"]) < date.fromisoformat(row["ship_date"]) for row in shipments),
            "noncanonical_status": sum(row["shipment_status"] not in CANONICAL_SHIPMENT_STATUSES for row in shipments),
        },
        "inventory": {
            "duplicate_extra_rows": duplicate_extras((row["inventory_date"], row["warehouse_id"], row["product_id"]) for row in inventory),
            "missing_product_id": sum(not row["product_id"] for row in inventory),
            "negative_closing_stock": sum(int(row["closing_stock"]) < 0 for row in inventory),
            "balance_mismatch": sum(int(row["opening_stock"]) + int(row["received_quantity"]) - int(row["shipped_quantity"]) != int(row["closing_stock"]) for row in inventory),
        },
    }

    row_counts = {
        "products": len(products), "warehouses": len(warehouses), "carriers": len(carriers),
        "customers": len(customers), "orders": len(orders), "shipments": len(shipments), "inventory": len(inventory),
    }
    failures = []
    for table, expected_count in manifest["source_row_counts"].items():
        if row_counts[table] != expected_count:
            failures.append(f"{table} row count: expected {expected_count}, found {row_counts[table]}")
    failures.extend(compare_expected(actual, manifest["expected_quality_issues"]))

    unique_order_dates = [date.fromisoformat(row["order_date"]) for row in orders]
    if min(unique_order_dates).isoformat() != manifest["analysis_period"]["start"]:
        failures.append("Order minimum date does not match configured start")
    if max(unique_order_dates).isoformat() != manifest["analysis_period"]["end"]:
        failures.append("Order maximum date does not match configured end")
    if len(product_ids) != 120 or len(warehouse_ids) != 6 or len(carrier_ids) != 7 or len(customer_ids) != 4_000:
        failures.append("Dimension cardinality does not match the design")

    status_distribution = Counter(row["order_status"].strip().lower() for row in orders)
    profile = {
        "validation_status": "PASS" if not failures else "FAIL",
        "row_counts": row_counts,
        "unique_business_keys": {
            "products": len(product_ids), "warehouses": len(warehouse_ids), "carriers": len(carrier_ids),
            "customers": len(customer_ids), "orders": len(order_ids),
        },
        "date_range": {"minimum_order_date": min(unique_order_dates).isoformat(), "maximum_order_date": max(unique_order_dates).isoformat()},
        "quality_issue_counts": actual,
        "raw_order_status_distribution": dict(sorted(status_distribution.items())),
        "failures": failures,
    }
    PROFILE_PATH.write_text(json.dumps(profile, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(profile, indent=2))
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()

