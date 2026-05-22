-- =============================================================================
-- Order Management Schema — Spec C (Comprehensive)
-- PostgreSQL 16 · BIGSERIAL IDs · TIMESTAMPTZ (UTC) · Soft delete
-- Parents before children · CHECK over ENUM
-- =============================================================================

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

CREATE UNIQUE INDEX idx_customers_email_unique ON customers (email) WHERE deleted_at IS NULL;

COMMENT ON TABLE customers IS 'Account holders who place orders.';
COMMENT ON COLUMN customers.email IS 'Unique login identifier (case-insensitive via CITEXT).';
COMMENT ON COLUMN customers.password_hash IS 'Bcrypt or argon2 hash — never store plaintext.';
COMMENT ON COLUMN customers.deleted_at IS 'Non-null marks a soft-deleted customer. Orders and payments are preserved for audit.';

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
    country     VARCHAR(100) NOT NULL DEFAULT 'US',
    is_default  BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

COMMENT ON TABLE addresses IS 'Customer addresses; a customer may have many. Referenced by orders for shipping/billing.';
COMMENT ON COLUMN addresses.is_default IS 'TRUE if this is the customer''s default shipping address.';
COMMENT ON COLUMN addresses.deleted_at IS 'Soft delete — historical order references are preserved.';

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

COMMENT ON TABLE products IS 'Product catalog. Soft-deletable; never hard-delete a product that has been ordered.';
COMMENT ON COLUMN products.price IS 'Current list price. Historical price is captured in order_items.unit_price at order time.';
COMMENT ON COLUMN products.deleted_at IS 'Soft delete — order_items FK to this table uses RESTRICT.';

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

COMMENT ON TABLE orders IS 'Order header. One per customer purchase.';
COMMENT ON COLUMN orders.status IS 'Lifecycle: pending → paid → shipped → delivered. Terminal: pending/paid → cancelled.';
COMMENT ON COLUMN orders.total_amount IS 'Snapshot of SUM(order_items.unit_price * quantity) at placement. Not a live calculation.';
COMMENT ON COLUMN orders.deleted_at IS 'Soft delete for audit trail preservation.';

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

COMMENT ON TABLE order_items IS 'Line items belonging to an order. Immutable after placement.';
COMMENT ON COLUMN order_items.unit_price IS 'Price snapshot at order time. Never join back to products.price for historical totals.';
COMMENT ON COLUMN order_items.deleted_at IS 'Soft delete — history is immutable.';

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

COMMENT ON TABLE payments IS 'Payment attempts for an order. Multiple rows per order are expected (retries, refunds).';
COMMENT ON COLUMN payments.status IS 'Lifecycle: initiated → authorized → captured, or initiated → failed, or captured → refunded.';
COMMENT ON COLUMN payments.amount IS 'Positive for charges; a refund is a separate row with status = ''refunded''.';
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

COMMENT ON TABLE shipments IS 'Shipment parcels for an order. An order may ship in multiple parcels.';
COMMENT ON COLUMN shipments.status IS 'Lifecycle: label_created → in_transit → delivered, or any → returned.';
COMMENT ON COLUMN shipments.deleted_at IS 'Soft delete for audit preservation.';

-- ---------------------------------------------------------------------------
-- 8. shipment_items (join table: shipments ↔ order_items)
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

COMMENT ON TABLE shipment_items IS 'Many-to-many: which order_items are in which shipment, with quantity for partial shipments.';
COMMENT ON COLUMN shipment_items.quantity IS 'Supports split shipments: e.g. 10 units of one item shipped as 6 + 4 across two parcels.';
COMMENT ON COLUMN shipment_items.deleted_at IS 'Soft delete.';

-- =============================================================================
-- Indexes: foreign keys
-- =============================================================================

CREATE INDEX idx_addresses_customer_id           ON addresses(customer_id);
CREATE INDEX idx_orders_customer_id              ON orders(customer_id);
CREATE INDEX idx_orders_shipping_address_id      ON orders(shipping_address_id);
CREATE INDEX idx_orders_billing_address_id       ON orders(billing_address_id);
CREATE INDEX idx_order_items_order_id            ON order_items(order_id);
CREATE INDEX idx_order_items_product_id          ON order_items(product_id);
CREATE INDEX idx_payments_order_id               ON payments(order_id);
CREATE INDEX idx_shipments_order_id              ON shipments(order_id);
CREATE INDEX idx_shipment_items_shipment_id      ON shipment_items(shipment_id);
CREATE INDEX idx_shipment_items_order_item_id    ON shipment_items(order_item_id);

-- =============================================================================
-- Indexes: composite hot paths
-- =============================================================================

CREATE INDEX idx_orders_customer_placed   ON orders(customer_id, placed_at DESC);
CREATE INDEX idx_orders_status_placed     ON orders(status, placed_at);
CREATE INDEX idx_payments_order_status    ON payments(order_id, status);

-- =============================================================================
-- Indexes: partial (soft delete — active rows only)
-- =============================================================================

CREATE INDEX idx_customers_active  ON customers(id)    WHERE deleted_at IS NULL;
CREATE INDEX idx_products_active   ON products(id)     WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_active     ON orders(id)       WHERE deleted_at IS NULL;
CREATE INDEX idx_order_items_active ON order_items(id) WHERE deleted_at IS NULL;
