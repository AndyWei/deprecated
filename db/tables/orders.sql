CREATE TABLE orders (
    id             BIGSERIAL  PRIMARY KEY,
    user_id        BIGINT        NOT NULL,  -- the id of the consumer who placed this order
    price          NUMERIC(11,2) NOT NULL,  -- the price that the consumer wants
    currency       CHAR(3)       NOT NULL DEFAULT 'usd',  -- ISO 4217 Currency Codes
    country        CHAR(2)       NOT NULL DEFAULT 'us',  -- country code
    status         SMALLINT      NOT NULL DEFAULT 0,  -- 0-active, 1-revoked, 2-pending, 3-ongoing, 4-finished, 5-paid
    category       SMALLINT      NOT NULL DEFAULT 0,  -- the service category: 0-uncategorized, 1-roadside_aid, 2-ride, 3-moving, 4-delivery, 5-cleaning, 6-handyman, 7-assistance
    description    VARCHAR(1000) NOT NULL,
    venue  GEOMETRY(Point, 4326) NOT NULL,  -- the venue where order should be serviced, used for searching and calculating distance
    address        TEXT                  ,  -- the address where order should be serviced, used for indicating the service seller
    winner_id      BIGINT                ,  -- the id of the user who wins this order
    final_price    NUMERIC(19,2)         ,  -- the final offered by provider and accepted by consumer
    created_at     TIMESTAMP     NOT NULL,
    updated_at     TIMESTAMP     NOT NULL,
    deleted        BOOLEAN       NOT NULL DEFAULT false,

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

/* partial index on venue for active orders only, which is to reduce index size */
CREATE INDEX orders_venue_index ON orders USING gist(venue)
WHERE status = 0;

