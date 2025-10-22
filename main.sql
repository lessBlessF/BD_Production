CREATE TABLE materials (
    material_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE operations (
    operation_id SERIAL PRIMARY KEY,
    hour_price NUMERIC(10,2) NOT NULL CHECK (hour_price > 0),
    hours NUMERIC(5,2) NOT NULL CHECK (hours > 0)
);

CREATE TABLE components (
    component_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    price NUMERIC(10,2) DEFAULT 0 CHECK (price >= 0),
    process_number INT
);

CREATE TABLE process (
    process_id SERIAL PRIMARY KEY,
    component_id INT NOT NULL REFERENCES components(component_id) ON DELETE CASCADE,
    material_id INT NOT NULL REFERENCES materials(material_id) ON DELETE CASCADE,
    material_amount NUMERIC(10,2) NOT NULL CHECK (material_amount > 0),
    operation_id INT NOT NULL REFERENCES operations(operation_id)
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2) CHECK (price >= 0)
);

CREATE TABLE product_components (
    id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    component_id INT NOT NULL REFERENCES components(component_id),
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    UNIQUE(product_id, component_id)
);

CREATE INDEX idx_components_price ON components(price);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_process_material ON process(material_id);

CREATE VIEW v_materials AS
SELECT * FROM materials;

CREATE VIEW v_products_components AS
SELECT p.name AS product, c.name AS component, pc.quantity
FROM product_components pc
JOIN products p ON pc.product_id = p.product_id
JOIN components c ON pc.component_id = c.component_id;

CREATE VIEW v_material_cost AS
SELECT m.name, SUM(pr.material_amount * m.price) AS total_cost
FROM process pr
JOIN materials m ON pr.material_id = m.material_id
GROUP BY m.name
HAVING SUM(pr.material_amount * m.price) > 500;

CREATE OR REPLACE FUNCTION update_component_prices()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE components
    SET price = price + (NEW.price - OLD.price) * 0.1
    WHERE component_id IN (
        SELECT component_id FROM process WHERE material_id = NEW.material_id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_component_prices
AFTER UPDATE OF price ON materials
FOR EACH ROW
EXECUTE FUNCTION update_component_prices();

