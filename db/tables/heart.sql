CREATE TABLE heart (
    id                 BIGSERIAL  PRIMARY KEY,
    sender             BIGINT        NOT NULL,  -- the person.id of sender
    receiver           BIGINT        NOT NULL,  -- the person.id of receiver
    status             SMALLINT      NOT NULL DEFAULT 0,  -- 0-sent, 10-accepted, 20-rejected
    ct                 BIGINT        NOT NULL,
    ut                 BIGINT        NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false
);


CREATE INDEX heart_sender_index ON heart (sender);
CREATE INDEX heart_receiver_index ON heart (receiver);

