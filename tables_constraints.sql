-- 3.1 Настраиваемые справочники
CREATE TABLE categories (
    category_id   SERIAL PRIMARY KEY,
    name          TEXT    NOT NULL UNIQUE,
    description   TEXT
);

CREATE TABLE suppliers (
    supplier_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL UNIQUE,
    phone       TEXT,
    email       TEXT CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE customers (
    customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name   TEXT NOT NULL,
    phone       TEXT,
    email       TEXT UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    full_name   TEXT NOT NULL,
    position    TEXT NOT NULL,
    hired_at    DATE NOT NULL,
    fired_at    DATE,
    CHECK (fired_at IS NULL OR fired_at > hired_at)
);

-- 3.2 Складская география
CREATE TABLE warehouses (
    warehouse_id SERIAL PRIMARY KEY,
    label        TEXT NOT NULL UNIQUE,
    address      TEXT
);

-- 3.3 Номенклатура
CREATE TABLE parts (
    part_id      SERIAL PRIMARY KEY,
    category_id  INT REFERENCES categories ON UPDATE CASCADE,
    supplier_id  UUID REFERENCES suppliers ON UPDATE CASCADE,
    sku          TEXT NOT NULL UNIQUE,
    part_name    TEXT NOT NULL,
    unit         TEXT NOT NULL DEFAULT 'шт',
    min_stock    INT  NOT NULL DEFAULT 0 CHECK (min_stock >= 0)
);

-- 3.4 История цен
CREATE TABLE price_history (
    part_id    INT REFERENCES parts ON DELETE CASCADE,
    valid_from DATE NOT NULL,
    price_kzt  NUMERIC(12,2) NOT NULL CHECK (price_kzt > 0),
    PRIMARY KEY (part_id, valid_from)
);

-- 3.5 Остатки на складах
CREATE TABLE stock_balance (
    warehouse_id INT REFERENCES warehouses ON DELETE CASCADE,
    part_id      INT REFERENCES parts ON DELETE CASCADE,
    qty          INT NOT NULL DEFAULT 0,
    CHECK (qty >= 0),
    PRIMARY KEY (warehouse_id, part_id)
);

-- 3.6 Движения запасов
CREATE TYPE movement_type AS ENUM ('IN', 'OUT');

CREATE TABLE stock_movements (
    movement_id   BIGSERIAL PRIMARY KEY,
    movement_ts   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    type          movement_type NOT NULL,
    warehouse_id  INT NOT NULL REFERENCES warehouses,
    part_id       INT NOT NULL REFERENCES parts,
    qty           INT NOT NULL CHECK (qty > 0),
    employee_id   INT REFERENCES employees
);

-- 3.7 Закупки
CREATE TABLE purchase_orders (
    po_id        SERIAL PRIMARY KEY,
    supplier_id  UUID NOT NULL REFERENCES suppliers,
    ordered_at   DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_at  DATE,
    status       TEXT NOT NULL CHECK (status IN ('NEW','ON_THE_WAY','RECEIVED','CANCELLED'))
);

CREATE TABLE purchase_order_items (
    po_id       INT REFERENCES purchase_orders ON DELETE CASCADE,
    part_id     INT REFERENCES parts ON DELETE RESTRICT,
    ordered_qty INT NOT NULL CHECK (ordered_qty > 0),
    price_kzt   NUMERIC(12,2) NOT NULL CHECK (price_kzt > 0),
    PRIMARY KEY (po_id, part_id)
);

-- 3.8 Продажи
CREATE TABLE sales_orders (
    so_id        SERIAL PRIMARY KEY,
    customer_id  UUID NOT NULL REFERENCES customers,
    issued_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status       TEXT NOT NULL CHECK (status IN ('NEW','PAID','SHIPPED','CANCELLED'))
);

CREATE TABLE sales_order_items (
    so_id      INT REFERENCES sales_orders ON DELETE CASCADE,
    part_id    INT REFERENCES parts ON DELETE RESTRICT,
    sold_qty   INT NOT NULL CHECK (sold_qty > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price > 0),
    PRIMARY KEY (so_id, part_id)
);