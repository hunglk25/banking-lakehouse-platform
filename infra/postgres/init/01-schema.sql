CREATE TABLE accounts (
    id            BIGSERIAL PRIMARY KEY,
    customer_name TEXT          NOT NULL,
    balance       NUMERIC(18,2) NOT NULL DEFAULT 0,
    currency      CHAR(3)       NOT NULL DEFAULT 'VND',
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE TABLE transactions (
    id          BIGSERIAL PRIMARY KEY,
    account_id  BIGINT        NOT NULL REFERENCES accounts(id),
    amount      NUMERIC(18,2) NOT NULL,
    type        TEXT          NOT NULL CHECK (type IN ('deposit','withdraw','transfer')),
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now()
);

ALTER TABLE accounts     REPLICA IDENTITY FULL;
ALTER TABLE transactions REPLICA IDENTITY FULL;

INSERT INTO accounts (customer_name, balance) VALUES
    ('Nguyen Van A', 1000000),
    ('Tran Thi B',   2500000);

INSERT INTO transactions (account_id, amount, type) VALUES
    (1, 1000000, 'deposit'),
    (2, 2500000, 'deposit');