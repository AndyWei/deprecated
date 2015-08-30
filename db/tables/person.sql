CREATE TABLE person (
    id                 BIGSERIAL  PRIMARY KEY,
    email              TEXT          NOT NULL, -- email is used as identity to signup and signin
    password           TEXT          NOT NULL, -- bcrypt hashed password, it always 60 bytes, however TEXT makes it flexible
    name               TEXT          NOT NULL, -- person display name
    verified           BOOLEAN       NOT NULL DEFAULT false,
    hearts             INTEGER       NOT NULL DEFAULT 0, -- the number of hearts
    friends            SMALLINT      NOT NULL DEFAULT 0, -- the number of friends
    score              INTEGER       NOT NULL DEFAULT 0, -- score will be used to sort person in a cell. score = 5 * hearts + 10 * friends. In the future, more factors will contribute to score 
    cell               TEXT          NOT NULL DEFAULT '0', -- the cell where the person last reported
    gender             SMALLINT      NOT NULL DEFAULT 0, -- 0 - unknown,  1 - male, 2 - famale, 3 - other
    org                TEXT                  , -- organization name that the person belongs to. E.g., ibm, apple, twitter, stanford, etc.
    orgtype            SMALLINT              , -- organization type. 0 - unknown, 1 - com,  2 - edu, 3 - org, 4 - gov, 100 - other.
    yob                NUMERIC(4)            , -- year of birth
    bio                TEXT                  ,
    avatar             TEXT                  , -- avatar filename
    coords             GEOMETRY(Point, 4326) , -- the point where the person last reported
    met                BIGINT                , -- membership expiry timestamp.
    ct                 BIGINT        NOT NULL, -- created_at timestamp
    ut                 BIGINT        NOT NULL, -- updated_at timestamp
    deleted            BOOLEAN       NOT NULL DEFAULT false,

    UNIQUE (email)
);


CREATE INDEX person_email_index  ON person (email);
CREATE INDEX person_score_index  ON person (score);
CREATE INDEX person_cell_index   ON person (cell);
CREATE INDEX person_org_index    ON person (org);
