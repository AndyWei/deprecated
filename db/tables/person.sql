CREATE TABLE person (
    id                 BIGSERIAL  PRIMARY KEY,
    email              TEXT          NOT NULL, -- email is used as identity to signup and signin
    password           TEXT          NOT NULL, -- bcrypt hashed password, it always 60 bytes, however TEXT makes it flexible
    name               TEXT          NOT NULL, -- person display name
    role               SMALLINT      NOT NULL DEFAULT 0, -- 0 - user,  1 - admin, 2 - test, 3 - robot.
    validated          BOOLEAN       NOT NULL DEFAULT false,
    org_name           TEXT                  , -- organization name that the person belongs to. E.g., ibm, apple, twitter, stanford, etc. It's extracted from the registration email
    org_type           SMALLINT              , -- 0 - com,  1 - edu, 2 - org, 3 - other. This is from the email suffix
    gender             SMALLINT              , -- 0 - unknown,  1 - male, 2 - famale, 3 - other
    yob                NUMERIC(4)            , -- year of birth
    bio                TEXT                  ,
    url                TEXT                  , -- the url of the portrait photo
    coordinate         GEOMETRY(Point, 4326) , -- the point where the person last reported
    member_expire_at   BIGINT                , -- the time when this person's membership expires. Th value is the seconds from 01/01/2001 12:00am
    created_at         BIGINT        NOT NULL,
    updated_at         BIGINT        NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false,

    UNIQUE (email)
);


CREATE INDEX person_email_index      ON person (email);
CREATE INDEX person_org_name_index   ON person (org_name);
CREATE INDEX person_coordinate_index ON person USING gist(coordinate);
