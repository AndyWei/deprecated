CREATE TABLE reviews (
    id             BIGSERIAL  PRIMARY KEY,
    reviewer_id    BIGINT        NOT NULL,  -- the id of the user who wrote this review
    reviewee_id    BIGINT        NOT NULL,  -- the id of the user who is reviewed
    rating         NUMERIC(2,1)  NOT NULL,  -- the rating score
    comment        TEXT                  ,
    created_at     TIMESTAMP     NOT NULL,
    updated_at     TIMESTAMP     NOT NULL,
    deleted        BOOLEAN       NOT NULL DEFAULT false,

    CHECK (rating > 0),

    FOREIGN KEY (reviewer_id)  REFERENCES users(id),
    FOREIGN KEY (reviewee_id)  REFERENCES users(id)
);


CREATE INDEX reviews_reviewer_id_index ON reviews (reviewer_id);

CREATE INDEX reviews_reviewee_id_index ON reviews (reviewee_id);
