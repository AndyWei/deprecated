CREATE TABLE bids (
    id             BIGSERIAL  PRIMARY KEY,
    user_id        BIGINT        NOT NULL,  -- the id of the user who offered this bid
    order_id       BIGINT        NOT NULL,  -- the id of the order
    price          NUMERIC(11,2) NOT NULL,  -- the price that user_id wants
    status         SMALLINT      NOT NULL DEFAULT 0,  -- 0-active, 1-revoked, 2-failed, 3-unfinished, 4-accepted
    note           TEXT          NOT NULL,  -- the description provided by the user_id
    expire_at      NUMERIC(10)   NOT NULL DEFAULT 0,  -- the time when this bid will be expired. It's value in form of the seconds since 1970. 0 means never expire.
    created_at     TIMESTAMP     NOT NULL,
    updated_at     TIMESTAMP     NOT NULL,
    deleted        BOOLEAN       NOT NULL DEFAULT false,

    CHECK (price >= 0),
    CHECK (status >= 0),

    FOREIGN KEY (user_id)  REFERENCES users(id),
    FOREIGN KEY (order_id) REFERENCES orders(id)
);


CREATE INDEX bids_user_id_index ON bids (user_id);

CREATE INDEX bids_order_id_index ON bids (order_id);
