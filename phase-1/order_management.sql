-- ============================================================
-- Order Management Database Schema
-- PostgreSQL 16
-- ============================================================

-- Domain: E-commerce order management
-- Tables: customers, orders, order_items, payments, shipments
-- Business rules:
--   - Orders can be cancelled only if not shipped
--   - One order can have multiple payment attempts, but only one succeeds
--   - One order can have multiple shipments (partial shipping)
--   - All monetary amounts stored as NUMERIC(12,2)
--   - Soft deletes via deleted_at (nullable)
--   - All timestamps in UTC (TIMESTAMPTZ)
-- ============================================================

-- ------------------------------------------------------------
-- Table: customers
-- ------------------------------------------------------------
CREATE TABLE customers (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    -- Billing address (optional; shipping may be per-order)
    billing_street VARCHAR(255),
    billing_city VARCHAR(100),
    billing_state VARCHAR(100),
    billing_postal_code VARCHAR(20),
    billing_country VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

COMMENT ON TABLE customers IS 'Registered customers; owns orders and related entities. Soft-delete via deleted_at.';
COMMENT ON COLUMN customers.id IS 'Primary key (BIGSERIAL).';
COMMENT ON COLUMN customers.email IS 'Unique customer email; used for login and notifications.';
COMMENT ON COLUMN customers.first_name IS 'Given name.';
COMMENT ON COLUMN customers.last_name IS 'Family name.';
COMMENT ON COLUMN customers.phone IS 'Contact phone number (optional).';
COMMENT ON COLUMN customers.billing_street IS 'Billing address street line (optional).';
COMMENT ON COLUMN customers.billing_city IS 'Billing address city (optional).';
COMMENT ON COLUMN customers.billing_state IS 'Billing address state/province (optional).';
COMMENT ON COLUMN customers.billing_postal_code IS 'Billing address postal/ZIP code (optional).';
COMMENT ON COLUMN customers.billing_country IS 'Billing address country (optional).';
COMMENT ON COLUMN customers.is_active IS 'True if the customer account is active; false for deactivated accounts.';
COMMENT ON COLUMN customers.created_at IS 'Timestamp when the customer record was created (UTC).';
COMMENT ON COLUMN customers.updated_at IS 'Timestamp when the customer record was last updated (UTC).';
COMMENT ON COLUMN customers.deleted_at IS 'Timestamp when the customer was soft-deleted (UTC); NULL means active.';

-- Indexes for customers
CREATE INDEX idx_customers_email ON customers(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_customers_active ON customers(is_active) WHERE deleted_at IS NULL;

-- ------------------------------------------------------------
-- Table: orders
-- ------------------------------------------------------------
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')),
    -- Currency code (e.g., USD, EUR)
    currency_code CHAR(3) NOT NULL DEFAULT 'USD',
    subtotal_amount NUMERIC(12, 2) NOT NULL CHECK (subtotal_amount >= 0),
    tax_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    shipping_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (shipping_amount >= 0),
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    -- Shipping address (snapshot at order time)
    shipping_street VARCHAR(255) NOT NULL,
    shipping_city VARCHAR(100) NOT NULL,
    shipping_state VARCHAR(100) NOT NULL,
    shipping_postal_code VARCHAR(20) NOT NULL,
    shipping_country VARCHAR(100) NOT NULL,
    notes TEXT,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

COMMENT ON TABLE orders IS 'Customer orders; head of the order domain. Soft-delete via deleted_at. Cancelled orders have cancelled_at set.';
COMMENT ON COLUMN orders.id IS 'Primary key (BIGSERIAL).';
COMMENT ON COLUMN orders.customer_id IS 'Reference to the customer who placed the order (RESTRICT on customer delete).';
COMMENT ON COLUMN orders.order_number IS 'Human-readable unique order identifier (e.g., ORD-20250514-0001).';
COMMENT ON COLUMN orders.status IS 'Order lifecycle state: pending, confirmed, processing, shipped, delivered, cancelled, returned.';
COMMENT ON COLUMN orders.currency_code IS 'ISO 4217 currency code for all monetary amounts in this order.';
COMMENT ON COLUMN orders.subtotal_amount IS 'Sum of (order_items.unit_price * order_items.quantity); excludes tax and shipping.';
COMMENT ON COLUMN orders.tax_amount IS 'Tax amount charged for this order.';
COMMENT ON COLUMN orders.shipping_amount IS 'Shipping cost for this order.';
COMMENT ON COLUMN orders.total_amount IS 'subtotal + tax + shipping; must match sum of payment_amount across successful payments.';
COMMENT ON COLUMN orders.shipping_street IS 'Shipping address street line (snapshot).';
COMMENT ON COLUMN orders.shipping_city IS 'Shipping address city (snapshot).';
COMMENT ON COLUMN orders.shipping_state IS 'Shipping address state/province (snapshot).';
COMMENT ON COLUMN orders.shipping_postal_code IS 'Shipping address postal/ZIP (snapshot).';
COMMENT ON COLUMN orders.shipping_country IS 'Shipping address country (snapshot).';
COMMENT ON COLUMN orders.notes IS 'Customer notes or internal order annotations (optional).';
COMMENT ON COLUMN orders.cancelled_at IS 'Timestamp when the order was cancelled (if applicable). NULL means not cancelled.';
COMMENT ON COLUMN orders.created_at IS 'Timestamp when the order was created (UTC).';
COMMENT ON COLUMN orders.updated_at IS 'Timestamp when the order was last updated (UTC).';
COMMENT ON COLUMN orders.deleted_at IS 'Timestamp when the order was soft-deleted (UTC); NULL means active.';

-- Indexes for orders
CREATE INDEX idx_orders_customer_id ON orders(customer_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_status ON orders(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_order_number ON orders(order_number);

-- ------------------------------------------------------------
-- Table: order_items
-- ------------------------------------------------------------
CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    -- Product reference (product_id to a separate products table; optional here)
    product_id BIGINT,
    product_sku VARCHAR(100) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    line_total NUMERIC(12, 2) NOT NULL CHECK (line_total >= 0),
    -- Snapshot of product attributes at purchase time
    product_image_url VARCHAR(500),
    -- Allow NULL product_id when referencing an external catalog
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

COMMENT ON TABLE order_items IS 'Line items within an order. Each item represents a purchased product with price/quantity snapshot.';
COMMENT ON COLUMN order_items.id IS 'Primary key (BIGSERIAL).';
COMMENT ON COLUMN order_items.order_id IS 'Reference to the owning order (RESTRICT on order delete).';
COMMENT ON COLUMN order_items.product_id IS 'Optional reference to a products table; NULL when product catalog is external.';
COMMENT ON COLUMN order_items.product_sku IS 'Stock Keeping Unit at time of purchase (immutable snapshot).';
COMMENT ON COLUMN order_items.product_name IS 'Product name at time of purchase (immutable snapshot).';
COMMENT ON COLUMN order_items.unit_price IS 'Price per unit at time of purchase; in order currency.';
COMMENT ON COLUMN order_items.quantity IS 'Number of units purchased; must be > 0.';
COMMENT ON COLUMN order_items.line_total IS 'unit_price * quantity (redundant but indexed for fast aggregation).';
COMMENT ON COLUMN order_items.product_image_url IS 'URL of product image at time of purchase (optional).';

-- Indexes for order_items
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_sku ON order_items(product_sku);

-- ------------------------------------------------------------
-- Table: payments
-- ------------------------------------------------------------
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    payment_method_type VARCHAR(50) NOT NULL,
    -- Payment gateway reference (e.g., stripe_payment_intent_id)
    gateway_payment_id VARCHAR(255) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    currency_code CHAR(3) NOT NULL DEFAULT 'USD',
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded', 'partially_refunded')),
    -- Payment attempt metadata
    gateway_response_code VARCHAR(100),
    error_message TEXT,
    refunded_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (refunded_amount >= 0),
    is_test BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT uq_payments_gateway_id UNIQUE (gateway_payment_id)
);

COMMENT ON TABLE payments IS 'Payment attempts against an order. Multiple payments can exist per order (retries); only one should have status=succeeded at a time.';
COMMENT ON COLUMN payments.id IS 'Primary key (BIGSERIAL).';
COMMENT ON COLUMN payments.order_id IS 'Reference to the order being paid (RESTRICT on order delete).';
COMMENT ON COLUMN payments.payment_method_type IS 'Type of payment method (e.g., credit_card, paypal, apple_pay).';
COMMENT ON COLUMN payments.gateway_payment_id IS 'Unique identifier from the payment gateway (e.g., Stripe PaymentIntent ID); globally unique.';
COMMENT ON COLUMN payments.amount IS 'Amount attempted for this payment; positive NUMERIC(12,2).';
COMMENT ON COLUMN payments.currency_code IS 'ISO 4217 currency code; must match the order currency.';
COMMENT ON COLUMN payments.status IS 'Payment lifecycle: pending, succeeded, failed, refunded, partially_refunded.';
COMMENT ON COLUMN payments.gateway_response_code IS 'Gateway-specific response code (e.g., approval code).';
COMMENT ON COLUMN payments.error_message IS 'Gateway error message if status=failed (optional).';
COMMENT ON COLUMN payments.refunded_amount IS 'Amount refunded against this payment; cannot exceed amount.';
COMMENT ON COLUMN payments.is_test IS 'True if this is a test/sandbox payment; false for live.';
COMMENT ON COLUMN payments.created_at IS 'Timestamp when the payment was initiated (UTC).';
COMMENT ON COLUMN payments.updated_at IS 'Timestamp when the payment was last updated (UTC).';
COMMENT ON COLUMN payments.deleted_at IS 'Timestamp when the payment was soft-deleted (UTC); NULL means active.';

-- Indexes for payments
CREATE INDEX idx_payments_order_id ON payments(order_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_payments_status ON payments(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_payments_gateway_id ON payments(gateway_payment_id);

-- ------------------------------------------------------------
-- Table: shipments
-- ------------------------------------------------------------
CREATE TABLE shipments (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    shipment_number VARCHAR(50) NOT NULL UNIQUE,
    carrier VARCHAR(100) NOT NULL,
    tracking_number VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'picked_up', 'in_transit', 'out_for_delivery', 'delivered', 'returned', 'failed')),
    -- Shipping cost for this particular shipment (may be portion of order.shipping_amount)
    shipping_cost NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (shipping_cost >= 0),
    -- Timestamps
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT fk_shipments_order FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

COMMENT ON TABLE shipments IS 'Shipments for orders. Supports partial shipping: one order can have multiple shipments.';
COMMENT ON COLUMN shipments.id IS 'Primary key (BIGSERIAL).';
COMMENT ON COLUMN shipments.order_id IS 'Reference to the order being shipped (RESTRICT on order delete).';
COMMENT ON COLUMN shipments.shipment_number IS 'Human-readable unique shipment identifier (e.g., SHP-20250514-0001).';
COMMENT ON COLUMN shipments.carrier IS 'Shipping carrier name (e.g., UPS, FedEx, USPS, DHL).';
COMMENT ON COLUMN shipments.tracking_number IS 'Carrier-provided tracking number; globally unique when present.';
COMMENT ON COLUMN shipments.status IS 'Shipment lifecycle: pending, picked_up, in_transit, out_for_delivery, delivered, returned, failed.';
COMMENT ON COLUMN shipments.shipping_cost IS 'Cost charged for this shipment; portion of order shipping amount.';
COMMENT ON COLUMN shipments.shipped_at IS 'Timestamp when the carrier picked up the shipment (NULL until shipped).';
COMMENT ON COLUMN shipments.delivered_at IS 'Timestamp when the shipment was delivered (NULL until delivered).';
COMMENT ON COLUMN shipments.created_at IS 'Timestamp when the shipment record was created (UTC).';
COMMENT ON COLUMN shipments.updated_at IS 'Timestamp when the shipment was last updated (UTC).';
COMMENT ON COLUMN shipments.deleted_at IS 'Timestamp when the shipment was soft-deleted (UTC); NULL means active.';

-- Indexes for shipments
CREATE INDEX idx_shipments_order_id ON shipments(order_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_shipments_status ON shipments(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_shipments_tracking_number ON shipments(tracking_number);

-- ============================================================
-- End of schema
-- ============================================================
