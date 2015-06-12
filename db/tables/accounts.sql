CREATE TABLE accounts (
    id                 BIGSERIAL  PRIMARY KEY,
    user_id            BIGINT        NOT NULL,
    email              TEXT          NOT NULL,  -- The user email provided on creating account, it's to make the account easier to identify with Stripe
    account_type       SMALLINT      NOT NULL DEFAULT 0, -- 0-individual, 1-company
    stripe_account_id  TEXT          NOT NULL,
    secret             TEXT          NOT NULL,
    publishable        TEXT          NOT NULL,
    created_at         TIMESTAMPTZ   NOT NULL,
    updated_at         TIMESTAMPTZ   NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false,

    FOREIGN KEY (user_id)  REFERENCES users(id)
);


CREATE INDEX accounts_user_id_index ON accounts (user_id);
