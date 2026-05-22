-- =============================================================================
-- Order Management Schema — Spec C (Comprehensive) · Haiku
-- PostgreSQL 16 · BIGSERIAL · TIMESTAMPTZ (UTC) · Soft delete
-- =============================================================================

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
COMMENT ON COLUMN customers.deleted_at IS 'Soft delete. Orders and payments preserved for audit.';

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

COMMENT ON TABLE addresses IS 'Customer addresses. Referenced by orders for shipping and billing.';

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

COMMENT ON TABLE products IS 'Product catalog. Soft-deletable.';
COMMENT ON COLUMN products.price IS 'Current price. Historical price captured in order_items.unit_price.';

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

COMMENT ON TABLE orders IS 'Order header.';
COMMENT ON COLUMN orders.status IS 'pending → paid → shipped → delivered, or cancelled.';
COMMENT ON COLUMN orders.total_amount IS 'Snapshot at placement, not a live join.';

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

COMMENT ON TABLE order_items IS 'Line items in an order.';
COMMENT ON COLUMN order_items.unit_price IS 'Price snapshot at order time.';

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

COMMENT ON TABLE payments IS 'Payment attempts for an order.';
COMMENT ON COLUMN payments.status IS 'initiated → authorized → captured, or failed, or refunded.';

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

COMMENT ON TABLE shipments IS 'Shipment parcels for an order.';
COMMENT ON COLUMN shipments.status IS 'label_created → in_transit → delivered, or returned.';

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

COMMENT ON TABLE shipment_items IS 'Join table for partial shipments.';

-- Indexes: foreign keys
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

-- Indexes: composite hot paths
CREATE INDEX idx_orders_customer_placed ON orders(customer_id, placed_at DESC);
CREATE INDEX idx_orders_status_placed   ON orders(status, placed_at);
CREATE INDEX idx_payments_order_status  ON payments(order_id, status);
