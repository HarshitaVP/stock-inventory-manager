-- V1__init.sql  ·  Stock & Inventory Manager

CREATE TABLE app_user (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    password_hash VARCHAR(100) NOT NULL,
    role          VARCHAR(20)  NOT NULL CHECK (role IN ('ADMIN', 'MANAGER', 'VIEWER')),
    enabled       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE area (
    id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(10)  NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE store (
    id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code    VARCHAR(10)  NOT NULL UNIQUE,
    name    VARCHAR(100) NOT NULL,
    area_id BIGINT       NOT NULL REFERENCES area (id),
    active  BOOLEAN      NOT NULL DEFAULT TRUE
);
CREATE INDEX idx_store_area ON store (area_id);

CREATE TABLE product (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku           VARCHAR(30)    NOT NULL UNIQUE,
    name          VARCHAR(150)   NOT NULL,
    category      VARCHAR(50)    NOT NULL,
    unit_price    NUMERIC(12, 4) NOT NULL CHECK (unit_price >= 0),
    reorder_level INTEGER        NOT NULL DEFAULT 10 CHECK (reorder_level >= 0),
    active        BOOLEAN        NOT NULL DEFAULT TRUE,
    version       INTEGER        NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ    NOT NULL DEFAULT now()
);
CREATE INDEX idx_product_category ON product (category);

CREATE TABLE stock (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT      NOT NULL REFERENCES product (id),
    store_id   BIGINT      NOT NULL REFERENCES store (id),
    quantity   INTEGER     NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    version    INTEGER     NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_stock_product_store UNIQUE (product_id, store_id)
);
CREATE INDEX idx_stock_store ON stock (store_id);

CREATE TABLE stock_movement (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id      BIGINT      NOT NULL REFERENCES product (id),
    store_id        BIGINT      NOT NULL REFERENCES store (id),
    quantity_change INTEGER     NOT NULL CHECK (quantity_change <> 0),
    reason          VARCHAR(20) NOT NULL CHECK (reason IN ('RECEIVED', 'SOLD', 'DAMAGED', 'CORRECTION')),
    source          VARCHAR(10) NOT NULL CHECK (source IN ('MANUAL', 'IMPORT')),
    import_job_id   BIGINT,
    created_by      VARCHAR(50) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_movement_product_store_time
    ON stock_movement (product_id, store_id, created_at DESC);

CREATE TABLE product_area_auth (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT      NOT NULL REFERENCES product (id),
    area_id    BIGINT      NOT NULL REFERENCES area (id),
    authorised BOOLEAN     NOT NULL,
    updated_by VARCHAR(50) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_area_auth UNIQUE (product_id, area_id)
);

CREATE TABLE product_store_auth (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT      NOT NULL REFERENCES product (id),
    store_id   BIGINT      NOT NULL REFERENCES store (id),
    authorised BOOLEAN     NOT NULL,
    updated_by VARCHAR(50) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_store_auth UNIQUE (product_id, store_id)
);

CREATE TABLE import_error (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_execution_id BIGINT       NOT NULL,
    line_number      INTEGER      NOT NULL,
    raw_line         TEXT,
    error_code       VARCHAR(30)  NOT NULL,
    message          VARCHAR(255) NOT NULL
);
CREATE INDEX idx_import_error_job ON import_error (job_execution_id);