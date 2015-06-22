CREATE TABLE orders (
    id                 BIGSERIAL  PRIMARY KEY,
    user_id            BIGINT        NOT NULL,  -- the id of the consumer who placed this order
    price              NUMERIC(11)   NOT NULL,  -- the price that the consumer wants. In cents.
    currency           CHAR(3)       NOT NULL DEFAULT 'usd',  -- ISO 4217 Currency Codes
    country            CHAR(2)       NOT NULL DEFAULT 'us',  -- country code
    status             SMALLINT      NOT NULL DEFAULT 0,  -- 0-active, 1-pending, 2-ongoing, 3-finished, 10-paid, 20-revoked, 30-refunded
    category           SMALLINT      NOT NULL DEFAULT 0,  -- the service category: 0-uncategorized, 1-roadside_aid, 2-ride, 3-moving, 4-delivery, 5-cleaning, 6-handyman, 7-assistance
    title              VARCHAR(100)  NOT NULL,
    note               VARCHAR(1000) NOT NULL,  -- the description from the consumer
    start_time         BIGINT        NOT NULL,
    start_point        GEOMETRY(Point, 4326) NOT NULL,  -- the point where order should be serviced from, used for searching and calculating distance
    start_city         TEXT          NOT NULL,  -- the city where order should be serviced, it will be shown on the order nearby view
    start_address      TEXT          NOT NULL,  -- the full address where order should be serviced, used for indicating the service seller
    end_point          GEOMETRY(Point, 4326) ,
    end_address        TEXT                  ,  -- the address where order should be serviced to, used for indicating the service seller
    created_at         TIMESTAMPTZ   NOT NULL,
    updated_at         TIMESTAMPTZ   NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false,
    photo_urls         TEXT                  ,  -- the urls of the order photos, separated by space
    winner_id          BIGINT                ,  -- the id of the user who wins this order
    final_price        NUMERIC(11)           ,  -- the final offered by provider and accepted by consumer. In cents.
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
CREATE INDEX orders_start_point_index ON orders USING gist(start_point)
WHERE status = 0;

