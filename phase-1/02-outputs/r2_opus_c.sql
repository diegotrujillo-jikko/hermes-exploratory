-- =============================================================================
-- Order Management Schema — Spec C (Comprehensive) · Opus
-- PostgreSQL 16 · BIGSERIAL IDs · TIMESTAMPTZ (UTC) · Soft delete
-- Parents before children · CHECK over ENUM
-- =============================================================================

-- Requires the citext extension for case-insensitive email uniqueness.
CREATE EXTENSION IF NOT EXISTS citext;

-- ---------------------------------------------------------------------------
-- 1. customers
-- ---------------------------------------------------------------------------

CREATE TABLE customers (
    id            BIGSERIAL    PRIMARY KEY,
    email         CITEXT       NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name     VARCHAR(255) NOT NULL,
    phone         VARCHAR(50),
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at    TIMESTAMPTZ
);

-- Case-insensitive uniqueness scoped to non-deleted customers.
CREATE UNIQUE INDEX idx_customers_email_unique ON customers (email) WHERE deleted_at IS NULL;

COMMENT ON TABLE customers IS 'Account holders who place orders.';
COMMENT ON COLUMN customers.email IS 'Unique login identifier. CITEXT gives case-insensitive matching; partial unique index scopes to active rows.';
COMMENT ON COLUMN customers.password_hash IS 'Bcrypt/argon2 hash — never store plaintext passwords.';
COMMENT ON COLUMN customers.deleted_at IS 'Non-null = soft-deleted. Orders, payments, and shipments are preserved for audit.';

-- ---------------------------------------------------------------------------
-- 2. addresses
-- ---------------------------------------------------------------------------

CREATE TABLE addresses (
    id          BIGSERIAL    PRIMARY KEY,
    customer_id BIGINT       NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    label       VARCHAR(50),
    line_1      VARCHAR(255) NOT NULL,
    line_2      VARCHAR(255),
    city        VARCHAR(100) NOT NULL,
    state       VARCHAR(100),
    postal_code VARCHAR(20)  NOT NULL,
    country     VARCHAR(3)   NOT NULL DEFAULT 'US',
    is_default  BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

COMMENT ON TABLE addresses IS 'Customer addresses. A customer may have many; orders reference specific addresses for shipping and billing.';
COMMENT ON COLUMN addresses.country IS 'ISO 3166-1 alpha-2 or alpha-3 code.';
COMMENT ON COLUMN addresses.is_default IS 'TRUE marks the customer''s preferred shipping address.';
COMMENT ON COLUMN addresses.deleted_at IS 'Soft delete — historical order references to this address are preserved.';

-- ---------------------------------------------------------------------------
-- 3. products
-- ---------------------------------------------------------------------------

CREATE TABLE products (
    id            BIGSERIAL      PRIMARY KEY,
    sku           VARCHAR(100)   NOT NULL UNIQUE,
    name          VARCHAR(255)   NOT NULL,
    description   TEXT,
    price         NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    stock_on_hand INTEGER        NOT NULL DEFAULT 0 CHECK (stock_on_hand >= 0),
    is_available  BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    deleted_at    TIMESTAMPTZ
);

COMMENT ON TABLE products IS 'Product catalog. Soft-deletable — never hard-delete a product that has been ordered.';
COMMENT ON COLUMN products.price IS 'Current list price. order_items.unit_price captures the historical price at order time.';
COMMENT ON COLUMN products.stock_on_hand IS 'Available inventory count. Decremented by application logic, not triggers.';
COMMENT ON COLUMN products.deleted_at IS 'Soft delete. order_items FK uses RESTRICT so deletion is blocked while references exist.';

-- ---------------------------------------------------------------------------
-- 4. orders
-- ---------------------------------------------------------------------------

CREATE TABLE orders (
    id                  BIGSERIAL      PRIMARY KEY,
    customer_id         BIGINT         NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    shipping_address_id BIGINT         NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT,
    billing_address_id  BIGINT         NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT,
    status              VARCHAR(32)    NOT NULL DEFAULT 'pending'
                                       CHECK (status IN ('pending', 'paid', 'shipped', 'delivered', 'cancelled')),
    total_amount        NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    placed_at           TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
);

COMMENT ON TABLE orders IS 'Order header — one per customer purchase.';
COMMENT ON COLUMN orders.status IS 'Lifecycle: pending → paid → shipped → delivered. Terminal cancellation: pending|paid → cancelled.';
COMMENT ON COLUMN orders.total_amount IS 'Snapshot of SUM(order_items.unit_price × quantity) at placement time. Not a live join.';
COMMENT ON COLUMN orders.shipping_address_id IS 'Address used for delivery. RESTRICT prevents deletion of referenced addresses.';
COMMENT ON COLUMN orders.deleted_at IS 'Soft delete — audit trail is preserved.';

-- ---------------------------------------------------------------------------
-- 5. order_items
-- ---------------------------------------------------------------------------

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

COMMENT ON TABLE order_items IS 'Line items in an order. Immutable after placement — history is never rewritten.';
COMMENT ON COLUMN order_items.unit_price IS 'Price snapshot captured at order time. Never join to products.price for historical totals.';
COMMENT ON COLUMN order_items.quantity IS 'Must be > 0. Partial shipments are tracked in shipment_items, not here.';
COMMENT ON COLUMN order_items.deleted_at IS 'Soft delete — order history is immutable.';

-- ---------------------------------------------------------------------------
-- 6. payments
-- ---------------------------------------------------------------------------

CREATE TABLE payments (
    id                  BIGSERIAL      PRIMARY KEY,
    order_id            BIGINT         NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    amount              NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    method              VARCHAR(32)    NOT NULL
                                       CHECK (method IN ('card', 'transfer', 'cash_on_delivery')),
    status              VARCHAR(32)    NOT NULL DEFAULT 'initiated'
                                       CHECK (status IN ('initiated', 'authorized', 'captured', 'failed', 'refunded')),
    processor_reference VARCHAR(255)   NOT NULL UNIQUE,
    processed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
);

COMMENT ON TABLE payments IS 'Payment attempts for an order. Multiple rows expected: retries, split payments, refunds.';
COMMENT ON COLUMN payments.status IS 'Lifecycle: initiated → authorized → captured | initiated → failed | captured → refunded.';
COMMENT ON COLUMN payments.amount IS 'Always positive. A refund is a separate row with status=''refunded'', same order_id.';
COMMENT ON COLUMN payments.processor_reference IS 'Unique external reference from the payment processor. Used for reconciliation.';
COMMENT ON COLUMN payments.deleted_at IS 'Soft delete — financial records are never hard-deleted.';

-- ---------------------------------------------------------------------------
-- 7. shipments
-- ---------------------------------------------------------------------------

CREATE TABLE shipments (
    id              BIGSERIAL    PRIMARY KEY,
    order_id        BIGINT       NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    carrier         VARCHAR(100) NOT NULL,
    tracking_number VARCHAR(255) NOT NULL UNIQUE,
    status          VARCHAR(32)  NOT NULL DEFAULT 'label_created'
                                 CHECK (status IN ('label_created', 'in_transit', 'delivered', 'returned')),
    shipped_at      TIMESTAMPTZ,
    delivered_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

COMMENT ON TABLE shipments IS 'Shipment parcels. An order may ship in multiple parcels (split shipments).';
COMMENT ON COLUMN shipments.status IS 'Lifecycle: label_created → in_transit → delivered | any state → returned.';
COMMENT ON COLUMN shipments.tracking_number IS 'Carrier-assigned tracking ID. Unique across all shipments.';
COMMENT ON COLUMN shipments.deleted_at IS 'Soft delete for audit preservation.';

-- ---------------------------------------------------------------------------
-- 8. shipment_items (join: shipments ↔ order_items)
-- ---------------------------------------------------------------------------

CREATE TABLE shipment_items (
    id            BIGSERIAL   PRIMARY KEY,
    shipment_id   BIGINT      NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    order_item_id BIGINT      NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
    quantity      INTEGER     NOT NULL CHECK (quantity > 0),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at    TIMESTAMPTZ,
    UNIQUE (shipment_id, order_item_id)
);

COMMENT ON TABLE shipment_items IS 'Many-to-many: tracks which order_items are in each shipment parcel, with quantity for splits.';
COMMENT ON COLUMN shipment_items.quantity IS 'Units of the order_item in this parcel. Enables split shipments (e.g. 10 units → 6 + 4).';
COMMENT ON COLUMN shipment_items.deleted_at IS 'Soft delete.';

-- =============================================================================
-- Indexes: foreign keys
-- =============================================================================

CREATE INDEX idx_addresses_customer_id        ON addresses(customer_id);
CREATE INDEX idx_orders_customer_id           ON orders(customer_id);
CREATE INDEX idx_orders_shipping_address_id   ON orders(shipping_address_id);
CREATE INDEX idx_orders_billing_address_id    ON orders(billing_address_id);
CREATE INDEX idx_order_items_order_id         ON order_items(order_id);
CREATE INDEX idx_order_items_product_id       ON order_items(product_id);
CREATE INDEX idx_payments_order_id            ON payments(order_id);
CREATE INDEX idx_shipments_order_id           ON shipments(order_id);
CREATE INDEX idx_shipment_items_shipment_id   ON shipment_items(shipment_id);
CREATE INDEX idx_shipment_items_order_item_id ON shipment_items(order_item_id);

-- =============================================================================
-- Indexes: composite hot paths
-- =============================================================================

CREATE INDEX idx_orders_customer_placed ON orders(customer_id, placed_at DESC);
CREATE INDEX idx_orders_status_placed   ON orders(status, placed_at);
CREATE INDEX idx_payments_order_status  ON payments(order_id, status);

-- =============================================================================
-- Indexes: partial (active rows only — accelerates queries that filter soft deletes)
-- =============================================================================

CREATE INDEX idx_customers_active   ON customers(id)    WHERE deleted_at IS NULL;
CREATE INDEX idx_products_active    ON products(id)     WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_active      ON orders(id)       WHERE deleted_at IS NULL;
CREATE INDEX idx_order_items_active ON order_items(id)  WHERE deleted_at IS NULL;
