CREATE TABLE orders (
    id                 BIGSERIAL  PRIMARY KEY,
    user_id            BIGINT        NOT NULL,  -- the id of the customer who placed this order
    price              NUMERIC(11)   NOT NULL,  -- the price that the customer wants. In cents.
    currency           CHAR(3)       NOT NULL DEFAULT 'usd',  -- ISO 4217 Currency Codes
    country            CHAR(2)       NOT NULL DEFAULT 'us',  -- country code
    status             SMALLINT      NOT NULL DEFAULT 0,  -- 0-active, 1-dealt, 2-started, 3-finished, 10-paid, 20-revoked, 30-refunded
    category           SMALLINT      NOT NULL DEFAULT 0,  -- the service category: 0-none, 10-assistant, 20-escort, 30-massage, 40-performer
    title              VARCHAR(100)  NOT NULL,
    note               VARCHAR(1000) NOT NULL,  -- the description from the customer
    start_time         BIGINT        NOT NULL,
    coordinate         GEOMETRY(Point, 4326) NOT NULL,  -- the point where order should be serviced from, used for searching and calculating distance
    city               TEXT          NOT NULL,  -- the city where order should be serviced, it will be shown on the order nearby view
    address            TEXT          NOT NULL,  -- the full address where order should be serviced, used for indicating the service seller
    created_at         TIMESTAMPTZ   NOT NULL,
    updated_at         TIMESTAMPTZ   NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false,
    finished_at        TIMESTAMPTZ           ,  -- the timestamp of finished the order
    winner_id          BIGINT                ,  -- the id of the user who wins this order
    winner_name        TEXT                  ,  -- the username of the user who wins this order. Putting here to reduce join.
    final_price        NUMERIC(11)           ,  -- the final offered by provider and accepted by customer. In cents.
    stripe_token       TEXT                  ,  -- the string that represents a credit card (start with tok_ ) or a stripe customer object (start with cus_ )
    stripe_charge_id   TEXT                  ,  -- the string that represents a sucessful charge, which will be used for refund
    stripe_refund_id   TEXT                  ,  -- the string that represents a sucessful refund, which will be used for tracking purpose


    CHECK (price >= 0),
    CHECK (final_price >= 0),
    CHECK (status >= 0),
    CHECK (category >= 0),

    FOREIGN KEY (user_id)   REFERENCES users(id),
    FOREIGN KEY (winner_id) REFERENCES users(id)
);


CREATE INDEX orders_user_id_index ON orders (user_id);

CREATE INDEX orders_category_index ON orders (category);

/* partial index on not null winner_id only, which is to reduce index size */
CREATE INDEX orders_winner_id_index ON orders (winner_id)
WHERE winner_id IS NOT NULL;

/* partial index on start point for active orders only, which is to reduce index size */
CREATE INDEX orders_start_point_index ON orders USING gist(coordinate)
WHERE status = 0;

