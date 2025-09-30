create database advanced_lab;

create table employees(
    emp_id serial primary key,
    first_name varchar(50),
    last_name varchar(50),
    department varchar(50),
    salary int,
    hire_date date,
    status varchar(20) default 'Active'
);
create table departments(
    dept_id serial primary key,
    dept_name varchar(50),
    budget int,
    manager_id int
);
create table projects(
    project_id serial primary key,
    project_name varchar(50),
    dept_id int,
    start_date date,
    end_date date,
    budget int
);

insert into employees(first_name, last_name, department)
values ('John', 'Doe', 'IT');

alter table employees alter column salary set default 40000;
insert into employees (first_name, last_name, department, hire_date)
values ('Alice', 'Smith', 'HR', '2023-05-01');

insert into departments (dept_name, budget, manager_id)
values
    ('IT', 200000, 1),
    ('HR', 100000, 2),
    ('Sales', 150000, 3);

insert into employees (first_name, last_name, department, salary, hire_date)
values ('Bob', 'Marley', 'Finance', 50000 * 1.1, CURRENT_DATE);

create temp table temp_employees as
select * from employees where department = 'IT';

update employees
set salary = salary * 1.1;

update employees SET salary = salary * 1.1 where 1=1;

update employees set status = 'Senior' where salary > 60000 and hire_date < '2020-01-01';

update employees
set department = case
    when salary > 80000 then 'Management'
    when salary between 50000 and 80000 then 'Senior'
    else 'Junior'
end;

update employees set department = default where status = 'Inactive';

update departments as d
set budget = (select avg(salary) * 1.2
              from employees as e
              where e.department = d.dept_name);

update employees as e
set salary = salary * 1.15,
    status = 'Promoted'
where department = 'Sales';

delete from employees where status = 'Terminated';

delete from employees
where salary < 40000
  and hire_date > '2023-01-01'
  and department is null;

delete from departments
where dept_name not in (
    select distinct department from employees where department is not null
    );

delete from projects
where end_date < '2023-01-01'
returning *;

insert into employees (first_name, last_name, salary, department)
values ('NullTest', 'User', NULL, NULL);

update employees
set department = 'Unassigned'
where department is null;

delete from employees
where salary is null or department is null;

insert into employees (first_name, last_name, department)
values ('David', 'Lee', 'IT')
returning emp_id, first_name || ' ' || last_name as full_name;

update employees
set salary = salary + 5000
where department = 'IT'
returning emp_id, salary - 5000 as old_salary, salary as new_salary;

delete from employees
where hire_date < '2020-01-01'
returning *;

insert into employees (first_name, last_name, department)
select 'Emma', 'Stone', 'HR'
where not exists (
    select 1 from employees where first_name = 'Emma' and last_name = 'Stone'
);

update employees as e
set salary = case
    when(select budget from departments as d where d.dept_name = e.department) > 100000 then salary * 1.1
    else salary * 1.05
end;

insert into employees (first_name, last_name, department, salary, hire_date)
values
    ('A1','B1','IT',50000,'2022-01-01'),
    ('A2','B2','IT',52000,'2022-01-02'),
    ('A3','B3','HR',48000,'2022-01-03'),
    ('A4','B4','Sales',45000,'2022-01-04'),
    ('A5','B5','Finance',55000,'2022-01-05');
UPDATE employees
SET salary = salary * 1.1
WHERE first_name LIKE 'A%';

create table employee_archive as table employees with no data;
insert into employee_archive
select * from employees where status = 'Inactive';
delete from employees where status = 'Inactive';

update projects as p
set end_date = end_date + interval '30 days'
where budget > 50000
  and (select count(*) from employees as e where e.department =
                                                 (select dept_name from departments as d where d.dept_id = p.dept_id)) > 3;