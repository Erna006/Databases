--    Part 2: Creating Basic Indexes
-- Exercise 2.1: Create a Simple B-tree Index
CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';
--How many indexes exist on the employees table? (Hint: PRIMARY KEY creates an automatic index)
--Indexing foreign key columns improves JOIN performance and helps with constraint checking.

-- Exercise 2.2: Create an Index on a Foreign Key
CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT * FROM employees WHERE dept_id = 101;
--Why is it beneficial to index foreign key columns?
--Indexing foreign key columns improves JOIN performance and helps with constraint checking.

-- Exercise 2.3: View Index Information
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
--List all the indexes you see. Which ones were created automatically?
--You'll see indexes like: departments_pkey, employees_pkey, projects_pkey (automatic primary key indexes), plus the ones we created.

--############################################################

--    Part 3: Multicolumn Indexes
-- Exercise 3.1: Create a Multicolumn Index
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;
--Would this index be useful for a query that only filters by salary (without dept_id)? Why or why not?
--No, this index wouldn't be useful for queries filtering only by salary because the leftmost column (dept_id) isn't used.

-- Exercise 3.2: Understanding Column Order
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;

SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;
--Does the order of columns in a multicolumn index matter? Explain.
--Yes, column order matters significantly. The leftmost columns in the index are more useful for filtering.

--############################################################

--    Part 4: Unique Indexes
-- Exercise 4.1: Create a Unique Index
ALTER TABLE employees ADD COLUMN email VARCHAR(100);

UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
--What error message did you receive?
--You'll get an error like "duplicate key value violates unique constraint"

-- Exercise 4.2: Unique Index vs UNIQUE Constraint
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';
--Did PostgreSQL automatically create an index? What type of index?
--Yes, PostgreSQL automatically creates a unique index when you add a UNIQUE constraint.

--############################################################

--    Part 5: Indexes and Sorting
-- Exercise 5.1: Create an Index for Sorting
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;
--How does this index help with ORDER BY queries?
--This index helps by pre-sorting data in descending order, making ORDER BY operations faster.

-- Exercise 5.2: Index with NULL Handling
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT project_name, budget
FROM projects
ORDER BY budget NULLS FIRST;

--############################################################

--    Part 6: Indexes on Expressions
-- Exercise 6.1: Create a Function-Based Index
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
--Without this index, how would PostgreSQL search for names case-insensitively?
--Without this index, PostgreSQL would do a full table scan and apply LOWER() to every row.

-- Exercise 6.2: Index on Calculated Values
ALTER TABLE employees ADD COLUMN hire_date DATE;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;

--############################################################

--    Part 7: Managing Indexes
-- Exercise 7.1: Rename an Index
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

-- Exercise 7.2: Drop Unused Indexes
DROP INDEX emp_salary_dept_idx;
--Why might you want to drop an index?
--You might drop indexes to save disk space, reduce maintenance overhead, or remove redundant indexes.

-- Exercise 7.3: Reindex
REINDEX INDEX employees_salary_index;
--When is REINDEX useful?
--After bulk INSERT operations. When index becomes bloated. After significant data modifications

--############################################################

--    Part 8: Practical Scenarios
-- Exercise 8.1: Optimize a Slow Query
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;

-- Exercise 8.2: Partial Index
CREATE INDEX proj_high_budget_idx ON projects(budget) WHERE budget > 80000;

SELECT project_name, budget
FROM projects
WHERE budget > 80000;
--What's the advantage of a partial index compared to a regular index?
--Partial indexes are smaller, faster, and use less disk space since they only index a subset of data.

-- Exercise 8.3: Analyze Index Usage
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
--Does the output show an "Index Scan" or a "Seq Scan" (Sequential Scan)? What does this tell you?
--Check if it shows "Index Scan" (using index) or "Seq Scan" (full table scan).

--############################################################

--    Part 9: Index Types Comparison
-- Exercise 9.1: Create a Hash Index
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';
--When should you use a HASH index instead of a B-tree index?
--Use HASH indexes for equality comparisons, when you don't need range queries.

-- Exercise 9.2: Compare Index Types
CREATE INDEX proj_name_btree_idx ON projects(project_name);
CREATE INDEX proj_name_hash_idx ON projects USING HASH (project_name);

SELECT * FROM projects WHERE project_name = 'Website Redesign';
SELECT * FROM projects WHERE project_name > 'Database';

--############################################################

--    Part 10: Cleanup and Best Practices
-- Exercise 10.1: Review All Indexes
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
--Which index is the largest? Why?
--The largest index is typically on columns with the most data or multicolumn indexes.

-- Exercise 10.2: Drop Unnecessary Indexes
DROP INDEX IF EXISTS proj_name_hash_idx;

-- Exercise 10.3: Document Your Indexes
CREATE VIEW index_documentation AS
SELECT
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' as purpose
FROM pg_indexes
WHERE schemaname = 'public' AND indexname LIKE '%salary%';
SELECT * FROM index_documentation;

-- 1)What is the default index type in PostgreSQL?
-- Default index type: B-tree

-- 2)Name three scenarios where you should create an index:
-- Three scenarios for indexes:
-- Frequently filtered columns in WHERE clauses
-- Foreign key columns for JOIN performance
-- Columns used in ORDER BY

-- 3)Name two scenarios where you should NOT create an index:
-- Two scenarios against indexes:
-- Tables with frequent bulk inserts/updates
-- Small tables where sequential scan is faster

-- 4)What happens to indexes when you INSERT, UPDATE, or DELETE data?
-- Indexes are automatically updated on INSERT/UPDATE/DELETE, which adds overhead

-- 5)How can you check if a query is using an index?
-- Use EXPLAIN before queries