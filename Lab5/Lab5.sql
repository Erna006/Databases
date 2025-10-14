-- Sarsemkhan Yernazar
-- 24B032001

-- creating database
CREATE DATABASE labwork5_db
    WITH OWNER = postgres
    TEMPLATE = template0
    ENCODING = 'UTF8';


--    Part 1: CHECK Constraints
-- Task 1.1
CREATE TABLE employees_check
(
    employee_id SERIAL PRIMARY KEY,
    first_name  TEXT,
    last_name   TEXT,
    age         INTEGER CHECK (age BETWEEN 18 AND 65), -- age must be 18..65
    salary      NUMERIC(12, 2) CHECK (salary > 0)      -- salary must be > 0
);

-- Task 1.2
CREATE TABLE products_catalog
(
    product_id     SERIAL PRIMARY KEY,
    product_name   TEXT,
    regular_price  NUMERIC(10, 2),
    discount_price NUMERIC(10, 2),
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
            AND discount_price > 0
            AND discount_price < regular_price
        )
);

-- Task 1.3
CREATE TABLE bookings
(
    booking_id     SERIAL PRIMARY KEY,
    check_in_date  DATE NOT NULL,
    check_out_date DATE NOT NULL,
    num_guests     INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CONSTRAINT check_dates CHECK (check_out_date > check_in_date) -- check_out after check_in
);

-- Task 1.4
INSERT INTO employees_check (first_name, last_name, age, salary)
VALUES ('Alice', 'Green', 30, 45000.00),
       ('Bob', 'White', 60, 120000.50);
-- Tests: invalid inserts (expected to fail)
-- INSERT INTO employees_check (first_name, last_name, age, salary) VALUES ('Young','One', 17, 20000.00); -- violates age CHECK (age < 18)
-- INSERT INTO employees_check (first_name, last_name, age, salary) VALUES ('Old','One', 66, 30000.00);   -- violates age CHECK (age > 65)
-- INSERT INTO employees_check (first_name, last_name, age, salary) VALUES ('Zero','Pay', 25, 0.00);      -- violates salary CHECK (salary > 0)
-- INSERT INTO employees_check (first_name, last_name, age, salary) VALUES ('Neg','Pay', 25, -100.00);    -- violates salary CHECK

INSERT INTO products_catalog (product_name, regular_price, discount_price)
VALUES ('Widget A', 100.00, 80.00),
       ('Gadget B', 50.00, 45.00);

-- invalid inserts (expected to fail)
-- INSERT INTO products_catalog (product_name, regular_price, discount_price) VALUES ('Bad1', 0.00, 0.00);    -- violates regular_price>0
-- INSERT INTO products_catalog (product_name, regular_price, discount_price) VALUES ('Bad2', 100.00, 100.00); -- violates discount_price < regular_price
-- INSERT INTO products_catalog (product_name, regular_price, discount_price) VALUES ('Bad3', 100.00, -5.00);  -- violates discount_price > 0

INSERT INTO bookings (check_in_date, check_out_date, num_guests)
VALUES ('2025-06-01', '2025-06-05', 2),
       ('2025-07-10', '2025-07-12', 1);

-- invalid inserts (expected to fail)
-- INSERT INTO bookings (check_in_date, check_out_date, num_guests) VALUES ('2025-08-01','2025-07-30', 2); -- violates check_dates
-- INSERT INTO bookings (check_in_date, check_out_date, num_guests) VALUES ('2025-08-01','2025-08-05', 0); -- violates num_guests BETWEEN 1 AND 10
-- INSERT INTO bookings (check_in_date, check_out_date, num_guests) VALUES ('2025-08-01','2025-08-05', 11); -- violates num_guests BETWEEN 1 AND 10


--    Part 2: NOT NULL Constraints
-- Task 2.1
CREATE TABLE customers
(
    customer_id       SERIAL PRIMARY KEY NOT NULL,
    email             TEXT               NOT NULL,
    phone             TEXT,
    registration_date DATE               NOT NULL
);

-- Task 2.2
CREATE TABLE inventory
(
    item_id      INTEGER PRIMARY KEY NOT NULL,
    item_name    TEXT                NOT NULL,
    quantity     INTEGER             NOT NULL CHECK ( quantity >= 0 ),
    unit_price   NUMERIC(10, 2)      NOT NULL CHECK ( unit_price > 0 ),
    last_updated TIMESTAMP           NOT NULL
);

-- Task 2.3
INSERT INTO customers (customer_id, email, phone, registration_date)
VALUES (1, 'a@example.com', '123-456', '2024-01-10'),
       (2, 'b@example.com', NULL, '2024-02-05');
-- invalid inserts (expected to fail)
-- INSERT INTO customers (customer_id, email, phone, registration_date) VALUES (3, NULL, '555-555', '2024-03-01'); -- violates NOT NULL email
-- INSERT INTO customers (customer_id, email, phone, registration_date) VALUES (4, 'd@example.com', '555-555', NULL); -- violates NOT NULL registration_date

INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (1, 'Screws', 100, 0.10, NOW()),
       (2, 'Hammer', 10, 12.50, NOW());
-- invalid inserts (expected to fail)
-- INSERT INTO inventory (item_name, quantity, unit_price, last_updated) VALUES (NULL, 5, 1.00, NOW()); -- violates NOT NULL item_name
-- INSERT INTO inventory (item_name, quantity, unit_price, last_updated) VALUES ('Nails', -1, 0.05, NOW()); -- violates quantity >= 0
-- INSERT INTO inventory (item_name, quantity, unit_price, last_updated) VALUES ('Glue', 5, 0.00, NOW()); -- violates unit_price > 0


--    Part 3: UNIQUE Constraints
-- Task 3.1
CREATE TABLE users
(
    user_id    SERIAL PRIMARY KEY,
    username   TEXT UNIQUE,
    email      TEXT UNIQUE,
    created_at TIMESTAMP
);

-- Task 3.2
CREATE TABLE course_enrollments
(
    enrollment_id SERIAL PRIMARY KEY,
    student_id    INTEGER NOT NULL,
    course_code   TEXT    NOT NULL,
    semester      TEXT    NOT NULL,
    UNIQUE (student_id, course_code, semester) -- multi-column unique: student can't enroll twice in same course+semester
);

-- Task 3.3
ALTER TABLE users
    ADD CONSTRAINT unique_username UNIQUE (username),
    ADD CONSTRAINT unique_email UNIQUE (email);

INSERT INTO users (username, email)
VALUES ('user1', 'user1@example.com'),
       ('user2', 'user2@example.com');
-- INSERT INTO users (username, email) VALUES ('user1', 'new@example.com'); -- violates unique_username
-- INSERT INTO users (username, email) VALUES ('uniqueX', 'user1@example.com'); -- violates unique_email

INSERT INTO course_enrollments (student_id, course_code, semester)
VALUES (101, 'CS101', '2024-Fall'),
       (102, 'CS101', '2024-Fall');
-- INSERT INTO course_enrollments (student_id, course_code, semester) VALUES (101, 'CS101', '2024-Fall'); -- violates UNIQUE(student_id, course_code, semester)


--    Part 4: PRIMARY KEY Constraints
-- Task 4.1
CREATE TABLE departments
(
    dept_id   INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location  TEXT
);
INSERT INTO departments (dept_id, dept_name, location)
VALUES (1, 'IT', 'Building A'),
       (2, 'Sales', 'Building B'),
       (3, 'HR', 'Building C');
-- INSERT INTO departments (dept_id, dept_name, location) VALUES (1, 'Finance', 'Building D'); -- violates PRIMARY KEY duplicate
-- INSERT INTO departments (dept_id, dept_name, location) VALUES (NULL, 'Logistics', 'Building D'); -- violates PRIMARY KEY (can't be null)

-- Task 4.2
CREATE TABLE student_courses
(
    student_id      INTEGER NOT NULL,
    course_id       INTEGER NOT NULL,
    enrollment_date DATE,
    grade           TEXT,
    PRIMARY KEY (student_id, course_id) -- composite primary key
);

-- Task 4.3
-- 1) Difference between UNIQUE and PRIMARY KEY:
--    - PRIMARY KEY implies NOT NULL and UNIQUE; it uniquely identifies a row.
--    - UNIQUE ensures uniqueness but columns with UNIQUE can be NULL (unless NOT NULL is added).
-- 2) When to use single-column vs composite PK:
--    - Single-column PK when a single attribute uniquely identifies row (e.g., id).
--    - Composite PK when uniqueness is combination of columns (e.g., student+course).
-- 3) Why only one PRIMARY KEY but many UNIQUE constraints:
--    - A table has only one primary identifier concept (one PK), but multiple different uniqueness rules can exist for business logic.


--    Part 5: FOREIGN KEY Constraints
-- Task 5.1
CREATE TABLE employees_dept
(
    emp_id    SERIAL PRIMARY KEY,
    emp_name  TEXT NOT NULL,
    dept_id   INTEGER REFERENCES departments (dept_id), -- FK references departments.dept_id
    hire_date DATE
);
INSERT INTO employees_dept (emp_name, dept_id, hire_date)
VALUES ('John Employee', 1, '2024-01-01');
-- INSERT INTO employees_dept (emp_name, dept_id, hire_date) VALUES ('Bad Emp', 999, '2024-01-02'); -- violates FK: dept_id 999 not in departments

-- Task 5.2
CREATE TABLE authors
(
    author_id   SERIAL PRIMARY KEY,
    author_name TEXT NOT NULL,
    country     TEXT
);

CREATE TABLE publishers
(
    publisher_id   SERIAL PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city           TEXT
);

CREATE TABLE books
(
    book_id          SERIAL PRIMARY KEY,
    title            TEXT NOT NULL,
    author_id        INTEGER REFERENCES authors (author_id),
    publisher_id     INTEGER REFERENCES publishers (publisher_id),
    publication_year INTEGER,
    isbn             TEXT UNIQUE
);

INSERT INTO authors (author_name, country)
VALUES ('Jane Austen', 'UK'),
       ('Mark Twain', 'USA'),
       ('Fyodor Dostoevsky', 'Russia');

INSERT INTO publishers (publisher_name, city)
VALUES ('Penguin', 'London'),
       ('HarperCollins', 'New York'),
       ('Vintage', 'London');

INSERT INTO books (title, author_id, publisher_id, publication_year, isbn)
VALUES ('Pride and Prejudice', 1, 1, 1813, '1111111111111'),
       ('Adventures of Huckleberry Finn', 2, 2, 1884, '2222222222222'),
       ('Crime and Punishment', 3, 3, 1866, '3333333333333');

-- Task 5.3
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products_fk CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

CREATE TABLE categories
(
    category_id   SERIAL PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk
(
    product_id   SERIAL PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id  INTEGER REFERENCES categories (category_id) ON DELETE RESTRICT
    -- ON DELETE RESTRICT: cannot delete category if product exists pointing to it
);

CREATE TABLE orders
(
    order_id   SERIAL PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items
(
    item_id    SERIAL PRIMARY KEY,
    order_id   INTEGER REFERENCES orders (order_id) ON DELETE CASCADE, -- ON DELETE CASCADE: deleting order deletes items
    product_id INTEGER REFERENCES products_fk (product_id),
    quantity   INTEGER CHECK (quantity > 0)
);

INSERT INTO categories (category_name)
VALUES ('Electronics'),
       ('Books');

INSERT INTO products_fk (product_name, category_id)
VALUES ('Phone', 1),
       ('Laptop', 1),
       ('Novel', 2);

-- Test 1: Try to delete category that has products -> should fail (RESTRICT)
-- The following will fail:
-- DELETE FROM categories WHERE category_id = 1; -- ERROR: update or delete on table "categories" violates foreign key constraint ...
-- Explanation: RESTRICT prevents deletion of referenced category.

-- Test 2: Delete an order -> order_items should be deleted automatically (CASCADE)
INSERT INTO orders (order_date)
VALUES ('2024-10-01'); -- creates order_id = 1 (likely)
INSERT INTO order_items (order_id, product_id, quantity)
VALUES (1, 1, 2),
       (1, 2, 1);
-- confirm items exist:
-- SELECT * FROM order_items WHERE order_id = 1;
-- Now delete order:
DELETE
FROM orders
WHERE order_id = 1;
-- After deletion, items with order_id=1 are automatically deleted (CASCADE). Verify:
-- SELECT * FROM order_items WHERE order_id = 1; -- empty


--    Part 6: Practical Application
-- Task 6.1
CREATE TABLE customers_ecom
(
    customer_id       SERIAL PRIMARY KEY,
    name              TEXT NOT NULL,
    email             TEXT NOT NULL UNIQUE, -- UNIQUE constraint on email
    phone             TEXT,
    registration_date DATE NOT NULL
);
-- products
CREATE TABLE products_ecom
(
    product_id     SERIAL PRIMARY KEY,
    name           TEXT           NOT NULL,
    description    TEXT,
    price          NUMERIC(10, 2) NOT NULL CHECK (price >= 0),         -- price non-negative
    stock_quantity INTEGER        NOT NULL CHECK (stock_quantity >= 0) -- stock non-negative
);
-- orders
CREATE TABLE orders_ecom
(
    order_id     SERIAL PRIMARY KEY,
    customer_id  INTEGER        NOT NULL REFERENCES customers_ecom (customer_id) ON DELETE RESTRICT,
    order_date   DATE           NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    status       TEXT           NOT NULL CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);
-- order_details
CREATE TABLE order_details
(
    order_detail_id SERIAL PRIMARY KEY,
    order_id        INTEGER        NOT NULL REFERENCES orders_ecom (order_id) ON DELETE CASCADE,
    product_id      INTEGER        NOT NULL REFERENCES products_ecom (product_id),
    quantity        INTEGER        NOT NULL CHECK (quantity > 0), -- quantity positive
    unit_price      NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0)
);

INSERT INTO customers_ecom (name, email, phone, registration_date)
VALUES ('Alice', 'alice@example.com', '111-111', '2024-01-10'),
       ('Bob', 'bob@example.com', '222-222', '2024-02-11'),
       ('Clara', 'clara@example.com', NULL, '2024-03-12'),
       ('Derek', 'derek@example.com', '333-333', '2024-04-13'),
       ('Eve', 'eve@example.com', '444-444', '2024-05-14');

INSERT INTO products_ecom (name, description, price, stock_quantity)
VALUES ('Widget', 'Small widget', 9.99, 100),
       ('Gizmo', 'Cool gizmo', 19.50, 50),
       ('Thingamajig', 'Useful thing', 5.00, 200),
       ('Doodad', 'Decorative doodad', 12.00, 10),
       ('Gadget', 'Multi-purpose gadget', 49.99, 5);

INSERT INTO orders_ecom (customer_id, order_date, total_amount, status)
VALUES (1, '2024-06-01', 29.48, 'pending'),
       (2, '2024-06-02', 19.50, 'processing'),
       (1, '2024-06-05', 9.99, 'shipped'),
       (3, '2024-06-06', 5.00, 'delivered'),
       (4, '2024-06-07', 24.00, 'cancelled');

INSERT INTO order_details (order_id, product_id, quantity, unit_price)
VALUES (1, 1, 2, 9.99), -- 2 Widgets
       (1, 3, 1, 5.00), -- 1 Thingamajig
       (2, 2, 1, 19.50),
       (3, 1, 1, 9.99),
       (4, 3, 1, 5.00);

-- Tests
-- 1) Price non-negative
-- INSERT INTO products_ecom (name, description, price, stock_quantity) VALUES ('BadPrice','X', -1.00, 10); -- violates CHECK price >= 0

-- 2) Stock non-negative
-- INSERT INTO products_ecom (name, description, price, stock_quantity) VALUES ('NegStock','X', 1.00, -5); -- violates CHECK stock_quantity >= 0

-- 3) Order status allowed values only
-- INSERT INTO orders_ecom (customer_id, order_date, total_amount, status) VALUES (1, '2024-07-01', 10.00, 'unknown'); -- violates status CHECK

-- 4) Order_details quantity positive
-- INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (1, 1, 0, 9.99); -- violates CHECK(quantity > 0)

-- 5) Unique customer email test
-- INSERT INTO customers_ecom (name, email, phone, registration_date) VALUES ('Z','alice@example.com','999', '2024-08-01'); -- violates UNIQUE(email)

-- 6) FK behaviors
-- Attempt to delete a customer with orders (should be RESTRICT and fail)
-- DELETE FROM customers_ecom WHERE customer_id = 1; -- expected to fail due to orders referencing customer 1 (ON DELETE RESTRICT)

-- Deleting an order should cascade to order_details
-- Insert a test order with details, then delete order to observe cascade:
INSERT INTO orders_ecom (customer_id, order_date, total_amount, status)
VALUES (5, '2024-07-01', 49.99, 'pending');
-- assume the above created order_id = X (depend on sequence), find it:
-- For test case we fetch last inserted id using RETURNING:
-- Example:
-- INSERT INTO orders_ecom (customer_id, order_date, total_amount, status) VALUES (5, '2024-07-02', 49.99, 'pending') RETURNING order_id;

-- Then insert order_details for that order and delete the order to see cascade:
-- INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (returned_order_id, 5, 1, 49.99);
-- DELETE FROM orders_ecom WHERE order_id = returned_order_id; -- this will delete corresponding order_details automatically