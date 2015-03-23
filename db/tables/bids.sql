CREATE TABLE bids (
    id             BIGSERIAL  PRIMARY KEY,
    user_id        BIGINT        NOT NULL,  -- the id of the user who offered this bid
    order_id       BIGINT        NOT NULL,  -- the id of the order
    offer_price    NUMERIC(19,2) NOT NULL,  -- the price that user_id wants
    status         SMALLINT      NOT NULL DEFAULT 1,  -- 0-inactive, 1-active, 2-failed, 3-canceled, 4-accepted, 5-finished, 6-paid
    description    TEXT          NOT NULL,  -- the description provided by the user_id
    created_at     TIMESTAMP     NOT NULL,
    updated_at     TIMESTAMP     NOT NULL,
    deleted        BOOLEAN       NOT NULL DEFAULT false,

    CHECK (offer_price >= 0),

    FOREIGN KEY (user_id)  REFERENCES users(id),
    FOREIGN KEY (order_id) REFERENCES orders(id)
);


CREATE INDEX bids_user_id_index ON bids (user_id);

CREATE INDEX bids_order_id_index ON bids (order_id);
