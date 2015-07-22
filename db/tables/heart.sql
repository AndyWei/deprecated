CREATE TABLE heart (
    id                 BIGSERIAL  PRIMARY KEY,
    sender_id          BIGINT        NOT NULL,  -- the person.id of sender
    receiver_id        BIGINT        NOT NULL,  -- the person.id of receiver
    status             SMALLINT      NOT NULL DEFAULT 0,  -- 0-sent, 10-accepted, 20-rejected
    created_at         BIGINT        NOT NULL,
    updated_at         BIGINT        NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false
);


CREATE INDEX heart_sender_id_index ON heart (sender_id);
CREATE INDEX heart_receiver_id_index ON heart (receiver_id);

