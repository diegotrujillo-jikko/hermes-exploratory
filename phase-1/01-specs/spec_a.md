# Spec A — Minimal

## Domain

Order management for a small e-commerce backend. Customers place orders containing one or more products. Each order has a status lifecycle (pending → paid → shipped → delivered, or cancelled). Payments and shipments are tracked separately.

## Scope

Design a PostgreSQL schema that supports:

- Customer accounts.
- Product catalog with prices and stock.
- Orders with line items.
- Payment records linked to orders.
- Shipment records linked to orders.

## Tech stack

- Database: PostgreSQL 16.
- Migrations: plain SQL (`CREATE TABLE` statements in a single file).
- No ORM assumptions.

## Deliverable

A single `.sql` file with `CREATE TABLE` statements only. No seed data, no triggers, no stored procedures.
