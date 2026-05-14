-- =============================================================================
-- Order Management Schema — Spec B (Balanced) · Opus
-- PostgreSQL 16 · BIGSERIAL IDs · TIMESTAMPTZ (UTC) · Soft delete
-- =============================================================================

-- Customers: account holders who place orders.
CREATE TABLE customers (
    id            BIGSERIAL    PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name     VARCHAR(255) NOT NULL,
    phone         VARCHAR(50),
    address       TEXT,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at    TIMESTAMPTZ
);

-- Products: catalog of items available for purchase.
CREATE TABLE products (
    id            BIGSERIAL      PRIMARY KEY,
    name          VARCHAR(255)   NOT NULL,
    sku           VARCHAR(100)   NOT NULL UNIQUE,
    price         NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    stock_on_hand INTEGER        NOT NULL DEFAULT 0 CHECK (stock_on_hand >= 0),
    is_available  BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    deleted_at    TIMESTAMPTZ
);

-- Orders: header record for each customer purchase.
-- total_amount is a snapshot captured at placement, not a live calculation.
CREATE TABLE orders (
    id           BIGSERIAL      PRIMARY KEY,
    customer_id  BIGINT         NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    status       VARCHAR(20)    NOT NULL DEFAULT 'pending'
                                CHECK (status IN ('pending', 'paid', 'shipped', 'delivered', 'cancelled')),
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    placed_at    TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    created_at   TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ
);

-- Order items: line items belonging to an order.
-- unit_price is a snapshot at order time; never join to products.price for totals.
CREATE TABLE order_items (
    id         BIGSERIAL      PRIMARY KEY,
    order_id   BIGINT         NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    product_id BIGINT         NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity   INTEGER        NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    created_at TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Payments: payment attempts for an order. Multiple rows expected (retries, refunds).
-- Status lifecycle: initiated → authorized → captured | initiated → failed | captured → refunded.
CREATE TABLE payments (
    id                  BIGSERIAL      PRIMARY KEY,
    order_id            BIGINT         NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    amount              NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    method              VARCHAR(50)    NOT NULL
                                       CHECK (method IN ('card', 'transfer', 'cash_on_delivery')),
    status              VARCHAR(20)    NOT NULL DEFAULT 'initiated'
                                       CHECK (status IN ('initiated', 'authorized', 'captured', 'failed', 'refunded')),
    processor_reference VARCHAR(255)   NOT NULL UNIQUE,
    processed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
);

-- Shipments: parcels for an order. An order may ship in multiple parcels.
-- Status lifecycle: label_created → in_transit → delivered | any → returned.
CREATE TABLE shipments (
    id              BIGSERIAL    PRIMARY KEY,
    order_id        BIGINT       NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    carrier         VARCHAR(100) NOT NULL,
    tracking_number VARCHAR(255) UNIQUE,
    status          VARCHAR(20)  NOT NULL DEFAULT 'label_created'
                                 CHECK (status IN ('label_created', 'in_transit', 'delivered', 'returned')),
    shipped_at      TIMESTAMPTZ,
    delivered_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

-- =============================================================================
-- Indexes: foreign keys
-- =============================================================================

CREATE INDEX idx_orders_customer_id     ON orders(customer_id);
CREATE INDEX idx_order_items_order_id   ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_payments_order_id      ON payments(order_id);
CREATE INDEX idx_shipments_order_id     ON shipments(order_id);

-- =============================================================================
-- Indexes: hot-path lookups
-- =============================================================================

CREATE INDEX idx_orders_customer_placed    ON orders(customer_id, placed_at DESC);
CREATE INDEX idx_orders_status             ON orders(status);
CREATE INDEX idx_shipments_tracking_number ON shipments(tracking_number);
CREATE INDEX idx_payments_order_status     ON payments(order_id, status);
