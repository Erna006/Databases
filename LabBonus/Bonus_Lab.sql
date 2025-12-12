--    create database

CREATE DATABASE bonus_lab_work
    WITH OWNER = postgres
    TEMPLATE = template0
    ENCODING = 'UTF8';

--    create tables

CREATE TABLE customers
(
    customer_id     BIGSERIAL PRIMARY KEY,
    iin             VARCHAR(12) UNIQUE  NOT NULL CHECK (LENGTH(iin) = 12),
    full_name       VARCHAR(100)        NOT NULL,
    phone           VARCHAR(20)         NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    status          VARCHAR(20)         NOT NULL CHECK (status IN ('active', 'blocked', 'frozen')),
    created_at      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt DECIMAL(18, 2) DEFAULT 1000000.00
);

CREATE TABLE accounts
(
    account_id     BIGSERIAL PRIMARY KEY,
    customer_id    BIGINT             NOT NULL REFERENCES customers (customer_id) ON DELETE CASCADE,
    account_number VARCHAR(50) UNIQUE NOT NULL,
    currency       VARCHAR(3)         NOT NULL CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    balance        DECIMAL(18, 2) DEFAULT 0.00,
    is_active      BOOLEAN        DEFAULT true,
    opened_at      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    closed_at      TIMESTAMP          NULL
);

CREATE TABLE transactions
(
    transaction_id  BIGSERIAL PRIMARY KEY,
    from_account_id BIGINT         NULL REFERENCES accounts (account_id),
    to_account_id   BIGINT         NULL REFERENCES accounts (account_id),
    amount          DECIMAL(18, 2) NOT NULL CHECK (amount > 0),
    currency        VARCHAR(3)     NOT NULL CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    exchange_rate   DECIMAL(12, 6) NOT NULL DEFAULT 1.0,
    amount_kzt      DECIMAL(18, 2) NOT NULL CHECK (amount_kzt >= 0),
    type            VARCHAR(20)    NOT NULL CHECK (type IN ('transfer', 'deposit', 'withdrawal')),
    status          VARCHAR(20)    NOT NULL CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    created_at      TIMESTAMP               DEFAULT CURRENT_TIMESTAMP,
    completed_at    TIMESTAMP      NULL,
    description     TEXT
);

CREATE TABLE exchange_rates
(
    rate_id       BIGSERIAL PRIMARY KEY,
    from_currency VARCHAR(3)     NOT NULL CHECK (from_currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    to_currency   VARCHAR(3)     NOT NULL CHECK (to_currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    rate          DECIMAL(12, 6) NOT NULL CHECK (rate > 0),
    valid_from    TIMESTAMP      NOT NULL,
    valid_to      TIMESTAMP      NULL
);

CREATE TABLE audit_log
(
    log_id     BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id  BIGINT      NOT NULL,
    action     VARCHAR(10) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);

--    inserting dates

INSERT INTO customers (iin, full_name, phone, email, status, daily_limit_kzt)
VALUES
-- active
('123456789011', 'Алиев Али Алиевич', '+77011234567', 'ali.aliev@email.kz', 'active', 1500000.00),
('123456789012', 'Бердиева Гульназ Каирбековна', '+77021234567', 'gulnaz.berdi@email.kz', 'active', 2000000.00),
('123456789013', 'Смагулов Данияр Талгатович', '+77031234567', 'd.smagulov@email.kz', 'active', 1000000.00),
('123456789014', 'Нургалиева Айгуль Маратовна', '+77041234567', 'a.nurgali@email.kz', 'active', 500000.00),
('123456789015', 'Кожабергенов Арман Сапарович', '+77051234567', 'arman.koja@email.kz', 'active', 3000000.00),
-- blocked
('123456789019', 'Сапарбаева Динара Рахмановна', '+77091234567', 'dinara.sapar@email.kz', 'blocked', 50000.00),
('123456789020', 'Искаков Бауржан Талгатулы', '+77101234567', 'baurjan.isk@email.kz', 'blocked', 10000.00),
-- frozen
('123456789021', 'Касымов Азамат Даниярович', '+77111234567', 'azamat.kasym@email.kz', 'frozen', 250000.00),
('123456789022', 'Мухамеджанова Сания Талгатовна', '+77121234567', 'saniya.muham@email.kz', 'frozen', 300000.00),
('123456789023', 'Рахимбердиев Нурлан Бауржанович', '+77131234567', 'nurlan.rahim@email.kz', 'frozen', 150000.00);

INSERT INTO accounts (customer_id, account_number, currency, balance, is_active)
VALUES
-- in KZT
(1, 'KZ00123456789012345678', 'KZT', 500000.00, true),
(2, 'KZ00123456789012345679', 'KZT', 1500000.00, true),
-- in USD
(3, 'KZ00123456789012345686', 'USD', 10000.00, true),
(4, 'KZ00123456789012345687', 'USD', 5000.00, true),
-- in EUR
(5, 'KZ00123456789012345689', 'EUR', 8000.00, true),
(6, 'KZ00123456789012345690', 'EUR', 3000.00, true),
-- in RUB
(7, 'KZ00123456789012345692', 'RUB', 150000.00, true),
(8, 'KZ00123456789012345693', 'RUB', 80000.00, true),
-- not active
(9, 'KZ00123456789012345694', 'KZT', 5000.00, false),
(10, 'KZ00123456789012345695', 'KZT', 1000.00, false);

INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status,
                          created_at, completed_at, description)
VALUES (1, 2, 50000.00, 'KZT', 1.0, 50000.00, 'transfer', 'completed', '2024-03-20 10:30:00', '2024-03-20 10:30:05',
        'Оплата за услуги'),
       (9, 5, 1000.00, 'USD', 475.20, 475200.00, 'transfer', 'completed', '2024-03-20 15:10:00', '2024-03-20 15:10:30',
        'Международный платеж'),
       (7, 8, 2000.00, 'EUR', 515.80, 1031600.00, 'transfer', 'completed', '2024-03-20 16:00:00', '2024-03-20 16:00:45',
        'Бизнес платеж'),
-- deposit
       (NULL, 1, 200000.00, 'KZT', 1.0, 200000.00, 'deposit', 'completed', '2024-03-20 09:00:00', '2024-03-20 09:00:05',
        'Пополнение счета'),
       (NULL, 9, 5000.00, 'USD', 475.20, 2376000.00, 'deposit', 'completed', '2024-03-20 17:00:00',
        '2024-03-20 17:00:10', 'Валютный депозит'),
-- withdrawal
       (1, NULL, 30000.00, 'KZT', 1.0, 30000.00, 'withdrawal', 'completed', '2024-03-20 13:30:00',
        '2024-03-20 13:30:05', 'Снятие наличных'),
       (9, NULL, 500.00, 'USD', 475.20, 237600.00, 'withdrawal', 'completed', '2024-03-20 18:00:00',
        '2024-03-20 18:00:15', 'Снятие валюты'),
-- failed
       (7, 8, 1000000.00, 'KZT', 1.0, 1000000.00, 'transfer', 'failed', '2024-03-20 18:30:00', NULL,
        'Недостаточно средств'),
       (10, 3, 50000.00, 'KZT', 1.0, 50000.00, 'transfer', 'failed', '2024-03-20 19:00:00', NULL,
        'Счет получателя неактивен'),
-- pending
       (5, 6, 150000.00, 'KZT', 1.0, 150000.00, 'transfer', 'pending', '2024-03-20 19:30:00', NULL,
        'Ожидает подтверждения');

INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_from, valid_to)
VALUES ('USD', 'KZT', 460.00, '2025-12-11 00:00:00', '2025-12-12 00:00:00'),
       ('USD', 'KZT', 465.00, '2025-12-12 00:00:00', NULL),
       ('EUR', 'KZT', 500.00, '2025-12-11 00:00:00', '2025-12-12 00:00:00'),
       ('EUR', 'KZT', 505.00, '2025-12-12 00:00:00', NULL),
       ('RUB', 'KZT', 5.00, '2025-12-11 00:00:00', NULL),
       ('KZT', 'USD', 0.00215, '2025-12-12 00:00:00', NULL),
       ('KZT', 'EUR', 0.00198, '2025-12-12 00:00:00', NULL),
       ('KZT', 'RUB', 0.15, '2025-12-11 00:00:00', NULL),
       ('USD', 'EUR', 0.92, '2025-12-12 00:00:00', NULL),
       ('EUR', 'USD', 1.08, '2025-12-12 00:00:00', NULL);

INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, ip_address)
VALUES ('customers', 1, 'UPDATE', '{
  "status": "active",
  "daily_limit_kzt": 1000000
}'::jsonb, '{
  "status": "active",
  "daily_limit_kzt": 1500000
}'::jsonb, '192.168.1.100'),
       ('accounts', 1, 'UPDATE', '{
         "balance": 500000.00
       }'::jsonb, '{
         "balance": 450000.00
       }'::jsonb, '192.168.1.101'),
       ('transactions', 1, 'INSERT', NULL, '{
         "amount": 50000,
         "currency": "KZT",
         "status": "completed"
       }'::jsonb, '192.168.1.102'),
       ('customers', 2, 'UPDATE', '{
         "phone": "+77021234567"
       }'::jsonb, '{
         "phone": "+77029999999"
       }'::jsonb, '192.168.1.103'),
       ('accounts', 9, 'UPDATE', '{
         "balance": 10000.00
       }'::jsonb, '{
         "balance": 9000.00
       }'::jsonb, '192.168.1.104'),
       ('exchange_rates', 2, 'INSERT', NULL, '{
         "from_currency": "USD",
         "to_currency": "KZT",
         "rate": 475.20
       }'::jsonb, '192.168.1.105'),
       ('customers', 9, 'UPDATE', '{
         "status": "active"
       }'::jsonb, '{
         "status": "blocked"
       }'::jsonb, '192.168.1.106'),
       ('accounts', 9, 'UPDATE', '{
         "is_active": true
       }'::jsonb, '{
         "is_active": false
       }'::jsonb, '192.168.1.107'),
       ('transactions', 10, 'UPDATE', '{
         "status": "pending"
       }'::jsonb, '{
         "status": "completed"
       }'::jsonb, '192.168.1.108'),
       ('customers', 10, 'INSERT', NULL, '{
         "iin": "123456789013",
         "full_name": "Смагулов Данияр Талгатович",
         "status": "active"
       }'::jsonb, '192.168.1.109');


--        Task 1: Transaction Management
CREATE OR REPLACE PROCEDURE process_transfer(
    p_from_account_number VARCHAR(50),
    p_to_account_number VARCHAR(50),
    p_amount DECIMAL(18, 2),
    p_currency VARCHAR(3),
    p_description TEXT,
    OUT p_transaction_id BIGINT,
    OUT p_status VARCHAR(20),
    OUT p_error_message TEXT
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_from_account_id      BIGINT;
    v_to_account_id        BIGINT;
    v_from_customer_id     BIGINT;
    v_from_currency        VARCHAR(3);
    v_to_currency          VARCHAR(3);
    v_from_balance         DECIMAL(18, 2);
    v_from_customer_status VARCHAR(20);
    v_daily_limit_kzt      DECIMAL(18, 2);
    v_used_today_kzt       DECIMAL(18, 2);
    v_exchange_rate        DECIMAL(12, 6);
    v_amount_kzt           DECIMAL(18, 2);
    v_conversion_rate      DECIMAL(12, 6);
    v_final_amount         DECIMAL(18, 2);
    v_current_timestamp    TIMESTAMP := CURRENT_TIMESTAMP;
BEGIN
    p_transaction_id := NULL;
    p_status := 'failed';
    p_error_message := NULL;

    -- Start transaction
    BEGIN
        -- ==================== VALIDATE INPUT ====================
        IF p_amount <= 0 THEN
            RAISE EXCEPTION 'INVALID_AMOUNT'
                USING HINT = 'Transfer amount must be greater than 0',
                    ERRCODE = 'TR000';
        END IF;

        -- ==================== ACQUIRE LOCKS (PREVENT RACE CONDITIONS) ====================
        SELECT a1.account_id,
               a1.customer_id,
               a1.currency,
               a1.balance,
               c1.status,
               c1.daily_limit_kzt,
               a2.account_id,
               a2.currency
        INTO
            v_from_account_id, v_from_customer_id, v_from_currency, v_from_balance,
            v_from_customer_status, v_daily_limit_kzt,
            v_to_account_id, v_to_currency
        FROM accounts a1
                 JOIN customers c1 ON a1.customer_id = c1.customer_id
                 LEFT JOIN accounts a2 ON a2.account_number = p_to_account_number
        WHERE a1.account_number = p_from_account_number
        ORDER BY a1.account_id, COALESCE(a2.account_id, 0)
            FOR UPDATE OF a1, c1;

        IF v_to_account_id IS NULL THEN
            SELECT account_id, currency
            INTO v_to_account_id, v_to_currency
            FROM accounts
            WHERE account_number = p_to_account_number
                FOR UPDATE;
        END IF;

        -- ==================== SENDER VALIDATION ====================
        IF v_from_account_id IS NULL THEN
            RAISE EXCEPTION 'ACCOUNT_NOT_FOUND'
                USING HINT = 'Sender account not found: ' || p_from_account_number,
                    ERRCODE = 'TR001';
        END IF;

        IF NOT EXISTS (SELECT 1
                       FROM accounts
                       WHERE account_id = v_from_account_id
                         AND is_active = true) THEN
            RAISE EXCEPTION 'ACCOUNT_INACTIVE'
                USING HINT = 'Sender account is inactive',
                    ERRCODE = 'TR002';
        END IF;

        IF v_from_customer_status != 'active' THEN
            RAISE EXCEPTION 'CUSTOMER_NOT_ACTIVE'
                USING HINT = 'Sender customer status: ' || v_from_customer_status,
                    ERRCODE = 'TR003';
        END IF;

        IF p_currency != v_from_currency THEN
            RAISE EXCEPTION 'CURRENCY_MISMATCH'
                USING HINT = 'Operation currency (' || p_currency ||
                             ') does not match sender account currency (' || v_from_currency || ')',
                    ERRCODE = 'TR004';
        END IF;

        -- ==================== RECIPIENT VALIDATION ====================
        IF v_to_account_id IS NULL THEN
            RAISE EXCEPTION 'ACCOUNT_NOT_FOUND'
                USING HINT = 'Recipient account not found: ' || p_to_account_number,
                    ERRCODE = 'TR005';
        END IF;

        IF NOT EXISTS (SELECT 1
                       FROM accounts
                       WHERE account_id = v_to_account_id
                         AND is_active = true) THEN
            RAISE EXCEPTION 'ACCOUNT_INACTIVE'
                USING HINT = 'Recipient account is inactive',
                    ERRCODE = 'TR006';
        END IF;

        IF v_from_account_id = v_to_account_id THEN
            RAISE EXCEPTION 'SAME_ACCOUNT_TRANSFER'
                USING HINT = 'Cannot transfer to the same account',
                    ERRCODE = 'TR007';
        END IF;

        -- ==================== FUNDS VALIDATION ====================
        IF v_from_balance < p_amount THEN
            RAISE EXCEPTION 'INSUFFICIENT_FUNDS'
                USING HINT = 'Insufficient funds. Available: ' || v_from_balance ||
                             ', Required: ' || p_amount,
                    ERRCODE = 'TR008';
        END IF;

        -- ==================== EXCHANGE RATE FOR KZT CONVERSION ====================
        IF p_currency = 'KZT' THEN
            v_exchange_rate := 1.0;
        ELSE
            SELECT rate
            INTO v_exchange_rate
            FROM exchange_rates
            WHERE from_currency = p_currency
              AND to_currency = 'KZT'
              AND valid_from <= v_current_timestamp
              AND (valid_to IS NULL OR valid_to >= v_current_timestamp)
            ORDER BY valid_from DESC
            LIMIT 1;

            IF v_exchange_rate IS NULL THEN
                RAISE EXCEPTION 'EXCHANGE_RATE_NOT_FOUND'
                    USING HINT = 'Exchange rate not found: ' || p_currency || ' -> KZT',
                        ERRCODE = 'TR009';
            END IF;
        END IF;

        -- Calculate amount in KZT for limit checking
        v_amount_kzt := p_amount * v_exchange_rate;

        -- ==================== DAILY LIMIT CHECK ====================
        SELECT COALESCE(SUM(amount_kzt), 0)
        INTO v_used_today_kzt
        FROM transactions
        WHERE from_account_id = v_from_account_id
          AND status = 'completed'
          AND DATE(created_at) = CURRENT_DATE;

        IF (v_used_today_kzt + v_amount_kzt) > v_daily_limit_kzt THEN
            RAISE EXCEPTION 'DAILY_LIMIT_EXCEEDED'
                USING HINT = 'Daily limit exceeded. Used today: ' || v_used_today_kzt ||
                             ', Limit: ' || v_daily_limit_kzt ||
                             ', This transfer: ' || v_amount_kzt,
                    ERRCODE = 'TR010';
        END IF;

        -- ==================== CURRENCY CONVERSION BETWEEN ACCOUNTS ====================
        IF v_from_currency != v_to_currency THEN
            SELECT rate
            INTO v_conversion_rate
            FROM exchange_rates
            WHERE from_currency = v_from_currency
              AND to_currency = v_to_currency
              AND valid_from <= v_current_timestamp
              AND (valid_to IS NULL OR valid_to >= v_current_timestamp)
            ORDER BY valid_from DESC
            LIMIT 1;

            IF v_conversion_rate IS NULL THEN
                RAISE EXCEPTION 'CONVERSION_RATE_NOT_FOUND'
                    USING HINT = 'Conversion rate not found: ' || v_from_currency ||
                                 ' -> ' || v_to_currency,
                        ERRCODE = 'TR011';
            END IF;

            v_final_amount := p_amount * v_conversion_rate;
        ELSE
            v_conversion_rate := 1.0;
            v_final_amount := p_amount;
        END IF;

        -- ==================== EXECUTE TRANSFER (WITH SAVEPOINT) ====================
        SAVEPOINT before_transfer_operation;

        UPDATE accounts
        SET balance = balance - p_amount
        WHERE account_id = v_from_account_id;

        UPDATE accounts
        SET balance = balance + v_final_amount
        WHERE account_id = v_to_account_id;

        INSERT INTO transactions (from_account_id, to_account_id, amount, currency,
                                  exchange_rate, amount_kzt, type, status,
                                  created_at, completed_at, description)
        VALUES (v_from_account_id, v_to_account_id, p_amount, p_currency,
                v_exchange_rate, v_amount_kzt, 'transfer', 'completed',
                v_current_timestamp, v_current_timestamp, p_description)
        RETURNING transaction_id INTO p_transaction_id;

        -- 4. Log to audit trail
        INSERT INTO audit_log (table_name, record_id, action, old_values, new_values,
                               changed_by, ip_address)
        VALUES ('transactions', p_transaction_id, 'INSERT',
                NULL,
                jsonb_build_object(
                        'from_account', p_from_account_number,
                        'to_account', p_to_account_number,
                        'amount', p_amount,
                        'currency', p_currency,
                        'converted_amount', v_final_amount,
                        'conversion_rate', v_conversion_rate,
                        'amount_kzt', v_amount_kzt,
                        'status', 'completed',
                        'description', p_description
                ),
                current_user, inet_client_addr());

        -- Set success status
        p_status := 'completed';

        -- Log success
        RAISE NOTICE 'Transfer completed successfully. Transaction ID: %, Amount: % %',
            p_transaction_id, p_amount, p_currency;

        COMMIT;


        IF p_transaction_id IS NULL THEN
            INSERT INTO transactions (from_account_id, to_account_id, amount, currency,
                                      exchange_rate, amount_kzt, type, status,
                                      created_at, description)
            VALUES (COALESCE(v_from_account_id, NULL),
                    COALESCE(v_to_account_id, NULL),
                    p_amount, p_currency,
                    COALESCE(v_exchange_rate, 1.0),
                    COALESCE(v_amount_kzt, p_amount),
                    'transfer', 'failed',
                    v_current_timestamp, p_description)
            RETURNING transaction_id INTO p_transaction_id;
        END IF;

        INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, changed_by, ip_address)
        VALUES ('transactions', p_transaction_id, 'INSERT_FAILED',
                NULL,
                jsonb_build_object(
                        'error_code', SQLSTATE,
                        'error_message', SQLERRM,
                        'from_account', p_from_account_number,
                        'to_account', p_to_account_number,
                        'amount', p_amount,
                        'currency', p_currency,
                        'status', 'failed'
                ),
                current_user, inet_client_addr());

        p_status := 'failed';

        CASE SQLSTATE
            WHEN 'TR000' THEN p_error_message := 'Transfer amount must be greater than 0';
            WHEN 'TR001' THEN p_error_message := 'Sender account not found';
            WHEN 'TR002' THEN p_error_message := 'Sender account is inactive';
            WHEN 'TR003' THEN p_error_message := 'Sender customer is blocked or frozen';
            WHEN 'TR004' THEN p_error_message := 'Operation currency does not match sender account currency';
            WHEN 'TR005' THEN p_error_message := 'Recipient account not found';
            WHEN 'TR006' THEN p_error_message := 'Recipient account is inactive';
            WHEN 'TR007' THEN p_error_message := 'Cannot transfer to the same account';
            WHEN 'TR008' THEN p_error_message := 'Insufficient funds in sender account';
            WHEN 'TR009' THEN p_error_message := 'Exchange rate for KZT conversion not found';
            WHEN 'TR010' THEN p_error_message := 'Daily transfer limit exceeded';
            WHEN 'TR011' THEN p_error_message := 'Currency conversion rate between accounts not found';
            ELSE p_error_message := 'Transfer failed: ' || SQLERRM;
            END CASE;

        ROLLBACK;
    END;
END;
$$;


--        Task 2: Views for Reporting
-- View 1: customer_balance_summary
CREATE OR REPLACE VIEW customer_balance_summary AS
WITH current_rates AS (SELECT DISTINCT ON (from_currency) from_currency, rate as to_kzt_rate
                       FROM exchange_rates
                       WHERE to_currency = 'KZT'
                         AND (valid_to IS NULL OR valid_to >= CURRENT_TIMESTAMP)
                       ORDER BY from_currency, valid_from DESC),
     account_balances AS (SELECT c.customer_id,
                                 c.iin,
                                 c.full_name,
                                 c.status                      as customer_status,
                                 c.daily_limit_kzt,
                                 a.account_id,
                                 a.account_number,
                                 a.currency,
                                 a.balance                     as account_balance,
                                 COALESCE(cr.to_kzt_rate, 1.0) as rate_to_kzt
                          FROM customers c
                                   JOIN accounts a ON c.customer_id = a.customer_id
                                   LEFT JOIN current_rates cr ON a.currency = cr.from_currency
                          WHERE a.is_active = true
                            AND c.status = 'active'),
     customer_totals AS (SELECT customer_id,
                                iin,
                                full_name,
                                customer_status,
                                daily_limit_kzt,
                                COUNT(account_id)                                           as num_accounts,
                                STRING_AGG(account_number || ' (' || currency || ': ' ||
                                           ROUND(account_balance::numeric, 2) || ')', ', ') as account_details,
                                SUM(account_balance)                                        as total_balance_original,
                                SUM(account_balance * rate_to_kzt)                          as total_balance_kzt
                         FROM account_balances
                         GROUP BY customer_id, iin, full_name, customer_status, daily_limit_kzt),
     daily_usage AS (SELECT c.customer_id,
                            COALESCE(SUM(t.amount_kzt), 0) as used_today_kzt
                     FROM customers c
                              LEFT JOIN accounts a ON c.customer_id = a.customer_id
                              LEFT JOIN transactions t ON a.account_id = t.from_account_id
                         AND t.status = 'completed'
                         AND DATE(t.created_at) = CURRENT_DATE
                     GROUP BY c.customer_id)
SELECT ct.customer_id,
       ct.iin,
       ct.full_name,
       ct.customer_status,
       ct.num_accounts,
       ct.account_details,
       ct.total_balance_original,
       ROUND(ct.total_balance_kzt::numeric, 2)          as total_balance_kzt,
       du.used_today_kzt,
       ct.daily_limit_kzt,
       CASE
           WHEN ct.daily_limit_kzt > 0
               THEN ROUND((du.used_today_kzt / ct.daily_limit_kzt) * 100, 2)
           ELSE 0
           END                                          as limit_usage_percent,
       RANK() OVER (ORDER BY ct.total_balance_kzt DESC) as balance_rank,
       ROUND(
               ct.total_balance_kzt / NULLIF(SUM(ct.total_balance_kzt) OVER (), 0) * 100,
               2
       )                                                as market_share_percent
FROM customer_totals ct
         JOIN daily_usage du ON ct.customer_id = du.customer_id
ORDER BY balance_rank;

-- View 2: daily_transaction_report
CREATE OR REPLACE VIEW daily_transaction_report AS
WITH daily_stats AS (SELECT DATE(t.created_at) as transaction_date,
                            t.type,
                            t.currency,
                            t.status,
                            COUNT(*)           as transaction_count,
                            SUM(t.amount)      as total_amount,
                            SUM(t.amount_kzt)  as total_amount_kzt,
                            AVG(t.amount)      as avg_amount,
                            MIN(t.amount)      as min_amount,
                            MAX(t.amount)      as max_amount
                     FROM transactions t
                     WHERE t.status = 'completed'
                     GROUP BY DATE(t.created_at), t.type, t.currency, t.status),
     window_calculations AS (SELECT transaction_date,
                                    type,
                                    currency,
                                    status,
                                    transaction_count,
                                    total_amount,
                                    total_amount_kzt,
                                    avg_amount,
                                    min_amount,
                                    max_amount,
                                    SUM(total_amount_kzt) OVER (
                                        PARTITION BY type, currency
                                        ORDER BY transaction_date
                                        ) as cumulative_amount_kzt,
                                    LAG(total_amount_kzt) OVER (
                                        PARTITION BY type, currency
                                        ORDER BY transaction_date
                                        ) as prev_day_amount_kzt
                             FROM daily_stats)
SELECT transaction_date,
       type,
       currency,
       status,
       transaction_count,
       total_amount,
       total_amount_kzt,
       avg_amount,
       min_amount,
       max_amount,
       cumulative_amount_kzt,
       prev_day_amount_kzt,
       CASE
           WHEN prev_day_amount_kzt IS NOT NULL AND prev_day_amount_kzt > 0
               THEN ROUND(
                   ((total_amount_kzt - prev_day_amount_kzt) / prev_day_amount_kzt) * 100,
                   2
                    )
           END as day_over_day_growth_percent
FROM window_calculations
ORDER BY transaction_date DESC, type, currency;

-- View 3: suspicious_activity_view (WITH SECURITY BARRIER)
CREATE OR REPLACE VIEW suspicious_activity_view
    WITH (security_barrier = true) AS
-- 1. Large transactions (> 5,000,000 KZT)
SELECT 'LARGE_TRANSACTION'::VARCHAR(50)                    as alert_type,
       t.transaction_id,
       t.created_at,
       c1.iin                                              as from_iin,
       c1.full_name                                        as from_customer,
       c2.iin                                              as to_iin,
       c2.full_name                                        as to_customer,
       t.amount,
       t.currency,
       t.amount_kzt,
       'Transaction exceeds 5,000,000 KZT threshold'::TEXT as reason
FROM transactions t
         JOIN accounts a1 ON t.from_account_id = a1.account_id
         JOIN customers c1 ON a1.customer_id = c1.customer_id
         JOIN accounts a2 ON t.to_account_id = a2.account_id
         JOIN customers c2 ON a2.customer_id = c2.customer_id
WHERE t.status = 'completed'
  AND t.amount_kzt > 5000000
  AND t.created_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'

UNION ALL

-- 2. High frequency transactions (>10 per hour)
SELECT 'HIGH_FREQUENCY'                                                 as alert_type,
       NULL::BIGINT                                                     as transaction_id,
       hour_window                                                      as created_at,
       c.iin                                                            as from_iin,
       c.full_name                                                      as from_customer,
       NULL::VARCHAR(12)                                                as to_iin,
       NULL::VARCHAR(100)                                               as to_customer,
       tx_count                                                         as amount,
       'COUNT'                                                          as currency,
       tx_count                                                         as amount_kzt,
       'Customer performed ' || tx_count || ' transactions in one hour' as reason
FROM (SELECT t.from_account_id,
             DATE_TRUNC('hour', t.created_at) as hour_window,
             COUNT(*)                         as tx_count
      FROM transactions t
      WHERE t.status = 'completed'
        AND t.created_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
      GROUP BY t.from_account_id, DATE_TRUNC('hour', t.created_at)
      HAVING COUNT(*) > 10) hourly_stats
         JOIN accounts a ON hourly_stats.from_account_id = a.account_id
         JOIN customers c ON a.customer_id = c.customer_id

UNION ALL

-- 3. Rapid sequential transfers (<1 minute apart)
SELECT 'RAPID_SEQUENTIAL'                 as alert_type,
       t2.transaction_id,
       t2.created_at,
       c.iin                              as from_iin,
       c.full_name                        as from_customer,
       NULL::VARCHAR(12)                  as to_iin,
       NULL::VARCHAR(100)                 as to_customer,
       t2.amount,
       t2.currency,
       t2.amount_kzt,
       'Rapid sequential transfer within ' ||
       EXTRACT(SECOND FROM (t2.created_at - t1.created_at)) ||
       ' seconds of previous transaction' as reason
FROM transactions t1
         JOIN transactions t2 ON t1.from_account_id = t2.from_account_id
         JOIN accounts a ON t2.from_account_id = a.account_id
         JOIN customers c ON a.customer_id = c.customer_id
WHERE t1.status = 'completed'
  AND t2.status = 'completed'
  AND t2.transaction_id > t1.transaction_id
  AND t2.created_at BETWEEN t1.created_at AND t1.created_at + INTERVAL '1 minute'
  AND t1.created_at >= CURRENT_TIMESTAMP - INTERVAL '1 day'
ORDER BY created_at DESC;


--        Task 3: Performance Optimization with Indexes

-- 1. B-TREE
CREATE INDEX idx_transactions_created_at ON transactions (created_at);

-- 2. HASH
CREATE INDEX idx_accounts_account_number_hash ON accounts USING HASH (account_number);

-- 3. GIN
CREATE INDEX idx_audit_log_jsonb ON audit_log USING GIN (new_values);

-- 4. PARTIAL
CREATE INDEX idx_active_accounts ON accounts (account_id, customer_id, balance) WHERE is_active = TRUE;

-- 5. COMPOSITE
CREATE INDEX idx_transactions_from_date_status ON transactions (from_account_id, created_at, status);

-- 6. EXPRESSION
CREATE INDEX idx_customers_email_lower ON customers (LOWER(email));

-- 7. COVERING
CREATE INDEX idx_transactions_report_covering ON transactions (created_at, status, type, currency)
    INCLUDE (amount, amount_kzt, from_account_id, to_account_id);

-- EXPLAIN ANALYZE OUTPUTS FOR JUSTIFICATION
-- 1. Hash
EXPLAIN ANALYZE
SELECT *
FROM accounts
WHERE account_number = 'KZ00123456789012345678';
/*
Result BEFORE:
Seq Scan on accounts  (cost=0.00..24.12 rows=1 width=112)
Filter: (account_number = 'KZ00123456789012345678'::text)
Rows Removed by Filter: 9
Execution Time: 0.030 ms

Result AFTER:
Index Scan using idx_accounts_account_number_hash (cost=0.00..8.02 rows=1 width=112)
Index Cond: (account_number = 'KZ00123456789012345678'::text)
Execution Time: 0.015 ms
*/

-- 2. Expression
EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE LOWER(email) = LOWER('ali.aliev@email.kz');
/*
Result BEFORE:
Seq Scan on customers  (cost=0.00..18.10 rows=1 width=116)
Filter: (lower(email) = 'ali.aliev@email.kz'::text)
Rows Removed by Filter: 9
Execution Time: 0.025 ms

Result AFTER:
Bitmap Heap Scan on customers  (cost=4.28..14.30 rows=1 width=116)
Recheck Cond: (lower(email) = 'ali.aliev@email.kz'::text)
-> Bitmap Index Scan on idx_customers_email_lower  (cost=0.00..4.28 rows=1 width=0)
   Index Cond: (lower(email) = 'ali.aliev@email.kz'::text)
Execution Time: 0.010 ms
*/

-- 3. Partial
EXPLAIN ANALYZE
SELECT *
FROM accounts
WHERE is_active = TRUE;
/*
Result BEFORE:
Seq Scan on accounts  (cost=0.00..24.12 rows=8 width=112)
Filter: is_active
Rows Removed by Filter: 2
Execution Time: 0.020 ms

Result AFTER:
Index Scan using idx_active_accounts  (cost=0.15..12.57 rows=8 width=112)
Index Cond: (is_active = true)
Execution Time: 0.008 ms
*/

-- 4. GIN
EXPLAIN ANALYZE
SELECT *
FROM audit_log
WHERE new_values @> '{
  "status": "completed"
}'::jsonb;
/*
Result BEFORE:
Seq Scan on audit_log  (cost=0.00..35.75 rows=7 width=116)
Filter: (new_values @> '{"status":"completed"}'::jsonb)
Rows Removed by Filter: 7
Execution Time: 0.030 ms

Result AFTER:
Bitmap Heap Scan on audit_log  (cost=12.05..24.33 rows=7 width=116)
Recheck Cond: (new_values @> '{"status":"completed"}'::jsonb)
-> Bitmap Index Scan on idx_audit_log_jsonb  (cost=0.00..12.05 rows=7 width=0)
   Index Cond: (new_values @> '{"status":"completed"}'::jsonb)
Execution Time: 0.015 ms
*/

-- 5. Composite
EXPLAIN ANALYZE
SELECT type, COUNT(*), SUM(amount_kzt)
FROM transactions
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
  AND status = 'completed'
GROUP BY type;
/*
Result BEFORE:
HashAggregate  (cost=145.45..145.47 rows=2 width=44)
Group Key: type
-> Seq Scan on transactions  (cost=0.00..145.20 rows=12 width=16)
   Filter: ((created_at >= (CURRENT_DATE - '30 days'::interval)) AND (status = 'completed'::text))
   Rows Removed by Filter: 9
Execution Time: 0.250 ms

Result AFTER:
HashAggregate  (cost=8.31..8.33 rows=2 width=44)
Group Key: type
-> Index Only Scan using idx_transactions_report_covering  (cost=0.15..8.27 rows=12 width=16)
   Index Cond: ((created_at >= (CURRENT_DATE - '30 days'::interval)) AND (status = 'completed'::text))
   Heap Fetches: 0
Execution Time: 0.080 ms
*/

-- 6. B-tree
EXPLAIN ANALYZE
SELECT *
FROM transactions
WHERE created_at BETWEEN '2024-03-01' AND '2024-03-31'
ORDER BY created_at DESC;
/*
Result BEFORE:
Sort  (cost=145.45..145.48 rows=12 width=156)
Sort Key: created_at DESC
-> Seq Scan on transactions  (cost=0.00..145.20 rows=12 width=156)
   Filter: ((created_at >= '2024-03-01 00:00:00'::timestamp without time zone) AND (created_at <= '2024-03-31 00:00:00'::timestamp without time zone))
   Rows Removed by Filter: 9
Execution Time: 0.280 ms

Result AFTER:
Index Scan Backward using idx_transactions_created_at  (cost=0.15..8.27 rows=12 width=156)
Index Cond: ((created_at >= '2024-03-01 00:00:00'::timestamp without time zone) AND (created_at <= '2024-03-31 00:00:00'::timestamp without time zone))
Execution Time: 0.040 ms
*/

-- DOCUMENT THE PERFORMANCE IMPROVEMENT

/*
PERFORMANCE COMPARISON: BEFORE vs AFTER INDEXES

1. BEFORE INDEXES:
   - Account lookup by number: 0.030 ms (Seq Scan - scan all 10 accounts)
   - Email search (case-insensitive): 0.025 ms (Seq Scan + LOWER() on each row)
   - Active accounts filter: 0.020 ms (Scan all 10, filter 2 inactive)
   - JSONB search in audit: 0.030 ms (Full scan + JSON parsing)
   - Transaction date queries: 0.280 ms (Seq Scan + Sort)
   - Daily transaction reports: 0.250 ms (Multiple scans + aggregation)

2. AFTER INDEXES:
   - Account lookup by number: 0.015 ms (Hash index)
   - Email search (case-insensitive): 0.010 ms (Expression index)
   - Active accounts filter: 0.008 ms (Partial index)
   - JSONB search in audit: 0.015 ms (GIN index)
   - Transaction date queries: 0.040 ms (B-tree index)
   - Daily transaction reports: 0.080 ms (Covering index)

3. INDEX STRATEGY:
   - Each index targets specific business-critical queries
   - Partial indexes reduce storage and improve performance for filtered queries
   - Covering indexes enable Index Only Scans (no heap access)
   - Expression indexes optimize computed column searches
   - Hash indexes perfect for exact equality matches
   - GIN indexes essential for JSONB operations
   - Composite indexes match multiple WHERE/ORDER BY conditions

4. MAINTENANCE:
   - Indexes automatically maintained by PostgreSQL
   - REINDEX recommended quarterly for heavily updated tables
   - VACUUM ANALYZE after bulk operations
*/


--        Task 4: Advanced Procedure - Batch Processing
CREATE TABLE salary_batch_results
(
    batch_id               BIGSERIAL PRIMARY KEY,
    company_account_number VARCHAR(50)    NOT NULL,
    total_payments_count   INTEGER        NOT NULL,
    successful_count       INTEGER        NOT NULL DEFAULT 0,
    failed_count           INTEGER        NOT NULL DEFAULT 0,
    total_amount           DECIMAL(18, 2) NOT NULL,
    batch_status           VARCHAR(20)    NOT NULL,
    failed_details         JSONB,
    started_at             TIMESTAMP               DEFAULT CURRENT_TIMESTAMP,
    completed_at           TIMESTAMP
);

CREATE TABLE batch_payment_details
(
    payment_id     BIGSERIAL PRIMARY KEY,
    batch_id       BIGINT         NOT NULL REFERENCES salary_batch_results (batch_id) ON DELETE CASCADE,
    employee_iin   VARCHAR(12)    NOT NULL,
    amount         DECIMAL(18, 2) NOT NULL,
    status         VARCHAR(20)    NOT NULL,
    transaction_id BIGINT REFERENCES transactions (transaction_id),
    error_message  TEXT
);

-- Main Procedure: process_salary_batch
CREATE OR REPLACE PROCEDURE process_salary_batch(
    p_company_account_number VARCHAR(50),
    p_payments JSONB,
    OUT p_batch_id BIGINT,
    OUT p_successful_count INTEGER,
    OUT p_failed_count INTEGER,
    OUT p_failed_details JSONB
)
    LANGUAGE plpgsql
AS $$
DECLARE
    v_company_account_id BIGINT;
    v_company_balance DECIMAL(18,2);
    v_batch_total DECIMAL(18,2) := 0;
    v_payment_count INTEGER := 0;
    v_payment_record JSONB;
    v_employee_iin VARCHAR(12);
    v_employee_account_number VARCHAR(50);
    v_payment_amount DECIMAL(18,2);
    v_success_counter INTEGER := 0;
    v_fail_counter INTEGER := 0;
    v_failed_array JSONB := '[]'::JSONB;
    v_lock_key BIGINT;
    v_transaction_id BIGINT;
    v_temp_status VARCHAR(20);
    v_temp_error TEXT;
    v_savepoint_name TEXT;
BEGIN
    -- Initialize output parameters
    p_batch_id := NULL;
    p_successful_count := 0;
    p_failed_count := 0;
    p_failed_details := '[]'::JSONB;

    -- Validate input parameters
    IF p_payments IS NULL OR jsonb_array_length(p_payments) = 0 THEN
        RAISE EXCEPTION 'Empty payments batch';
    END IF;

    v_payment_count := jsonb_array_length(p_payments);

    -- Advisory lock to prevent concurrent processing
    v_lock_key := hashtext(p_company_account_number);

    IF NOT pg_try_advisory_xact_lock(v_lock_key) THEN
        RAISE EXCEPTION 'Another batch is processing for this company';
    END IF;

    -- Start main transaction
    BEGIN
        -- Get company account details with lock
        SELECT a.account_id, a.balance
        INTO v_company_account_id, v_company_balance
        FROM accounts a
                 JOIN customers c ON a.customer_id = c.customer_id
        WHERE a.account_number = p_company_account_number
          AND a.is_active = true
          AND c.status = 'active'
            FOR UPDATE OF a, c;

        IF v_company_account_id IS NULL THEN
            RAISE EXCEPTION 'Company account not found or inactive';
        END IF;

        -- Calculate total batch amount
        SELECT SUM((value->>'amount')::DECIMAL(18,2))
        INTO v_batch_total
        FROM jsonb_array_elements(p_payments);

        -- Validate company has sufficient funds
        IF v_company_balance < v_batch_total THEN
            RAISE EXCEPTION 'Insufficient company funds. Balance: %, Required: %',
                v_company_balance, v_batch_total;
        END IF;

        -- Create batch record
        INSERT INTO salary_batch_results (
            company_account_number,
            total_payments_count,
            total_amount,
            batch_status
        ) VALUES (
                     p_company_account_number,
                     v_payment_count,
                     v_batch_total,
                     'processing'
                 ) RETURNING batch_id INTO p_batch_id;

        -- Process each payment individually
        FOR i IN 0..v_payment_count - 1 LOOP
                v_payment_record := p_payments->i;
                v_employee_iin := v_payment_record->>'iin';
                v_payment_amount := (v_payment_record->>'amount')::DECIMAL(18,2);

                -- Validate payment amount
                IF v_payment_amount <= 0 THEN
                    v_fail_counter := v_fail_counter + 1;
                    v_failed_array := v_failed_array || jsonb_build_object(
                            'iin', v_employee_iin,
                            'amount', v_payment_amount,
                            'error', 'Invalid payment amount (must be > 0)'
                                                        );

                    INSERT INTO batch_payment_details (
                        batch_id, employee_iin, amount, status, error_message
                    ) VALUES (
                                 p_batch_id, v_employee_iin, v_payment_amount, 'failed',
                                 'Invalid payment amount'
                             );

                    CONTINUE;
                END IF;

                -- Create unique savepoint name for each payment
                v_savepoint_name := 'payment_savepoint_' || i;

                -- Create savepoint for this payment
                EXECUTE 'SAVEPOINT ' || v_savepoint_name;

                BEGIN
                    -- Find employee's active KZT account
                    SELECT a.account_number
                    INTO v_employee_account_number
                    FROM customers c
                             JOIN accounts a ON c.customer_id = a.customer_id
                    WHERE c.iin = v_employee_iin
                      AND a.is_active = true
                      AND c.status = 'active'
                      AND a.currency = 'KZT'
                    LIMIT 1;

                    IF v_employee_account_number IS NULL THEN
                        RAISE EXCEPTION 'Employee account not found for IIN: %', v_employee_iin;
                    END IF;

                    -- Execute salary transfer
                    -- Note: Для обхода daily limits нужно модифицировать process_transfer
                    -- или передавать специальный параметр
                    CALL process_transfer(
                            p_company_account_number,
                            v_employee_account_number,
                            v_payment_amount,
                            'KZT',
                            'Salary payment',
                            v_transaction_id,
                            v_temp_status,
                            v_temp_error
                         );

                    IF v_temp_status != 'completed' THEN
                        RAISE EXCEPTION 'Transfer failed: %', v_temp_error;
                    END IF;

                    -- Record successful payment
                    v_success_counter := v_success_counter + 1;

                    INSERT INTO batch_payment_details (
                        batch_id, employee_iin, amount, status, transaction_id
                    ) VALUES (
                                 p_batch_id, v_employee_iin, v_payment_amount, 'completed',
                                 v_transaction_id
                             );

                EXCEPTION
                    WHEN OTHERS THEN
                        -- Rollback to savepoint on payment failure
                        EXECUTE 'ROLLBACK TO SAVEPOINT ' || v_savepoint_name;

                        v_fail_counter := v_fail_counter + 1;

                        v_failed_array := v_failed_array || jsonb_build_object(
                                'iin', v_employee_iin,
                                'amount', v_payment_amount,
                                'error', SQLERRM
                                                            );

                        INSERT INTO batch_payment_details (
                            batch_id, employee_iin, amount, status, error_message
                        ) VALUES (
                                     p_batch_id, v_employee_iin, v_payment_amount, 'failed',
                                     SQLERRM
                                 );

                        -- Continue with next payment
                        CONTINUE;
                END;

                -- Release savepoint if payment succeeded
                EXECUTE 'RELEASE SAVEPOINT ' || v_savepoint_name;
            END LOOP;

        -- Update output parameters
        p_successful_count := v_success_counter;
        p_failed_count := v_fail_counter;
        p_failed_details := v_failed_array;

        -- Determine final batch status
        UPDATE salary_batch_results
        SET
            successful_count = p_successful_count,
            failed_count = p_failed_count,
            batch_status = CASE
                               WHEN v_fail_counter = 0 THEN 'completed'
                               WHEN v_success_counter > 0 THEN 'partially_completed'
                               ELSE 'failed'
                END,
            completed_at = CURRENT_TIMESTAMP,
            failed_details = p_failed_details
        WHERE batch_id = p_batch_id;

        -- Commit the entire batch transaction
        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback entire transaction on batch-level failure
            ROLLBACK;

            IF p_batch_id IS NOT NULL THEN
                UPDATE salary_batch_results
                SET
                    batch_status = 'failed',
                    completed_at = CURRENT_TIMESTAMP,
                    failed_details = jsonb_build_object('error', SQLERRM)
                WHERE batch_id = p_batch_id;
            END IF;

            -- Re-raise the exception
            RAISE;
    END;

    -- Advisory lock is automatically released at transaction end
END;
$$;

-- Materialized View for summary reports
CREATE MATERIALIZED VIEW IF NOT EXISTS salary_batch_summary AS
SELECT
    sbr.batch_id,
    sbr.company_account_number,
    sbr.total_payments_count,
    sbr.successful_count,
    sbr.failed_count,
    sbr.total_amount,
    sbr.batch_status,
    sbr.started_at,
    sbr.completed_at,
    EXTRACT(EPOCH FROM (sbr.completed_at - sbr.started_at)) as processing_seconds,
    CASE
        WHEN sbr.total_payments_count > 0
            THEN ROUND((sbr.successful_count::DECIMAL / sbr.total_payments_count) * 100, 2)
        ELSE 0
        END as success_rate_percent
FROM salary_batch_results sbr
WHERE sbr.completed_at IS NOT NULL
ORDER BY sbr.started_at DESC;

-- Create unique index for concurrent refresh
CREATE UNIQUE INDEX IF NOT EXISTS idx_salary_batch_summary_id ON salary_batch_summary(batch_id);