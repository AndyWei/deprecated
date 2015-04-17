CREATE TABLE users (
    id            BIGSERIAL  PRIMARY KEY,
    username      TEXT          NOT NULL,  -- when user signup, this field is generated automatically, and the user can modify it later
    password      TEXT          NOT NULL,  -- bcrypt hashed password, it always 60 bytes, however TEXT provides flexible
    email         TEXT          NOT NULL,  -- user use email to signup
    role          SMALLINT      NOT NULL,  -- 1-user, 2-admin, 3-test, 4-robot
    status        SMALLINT      NOT NULL DEFAULT 1,  -- 0-inactive, 1-active, 2-closed, 3-suspended
    rating_total  NUMERIC(8,1)  NOT NULL DEFAULT 0,
    rating_count  NUMERIC(6)    NOT NULL DEFAULT 0,
    bio           TEXT                  ,
    created_at    TIMESTAMPTZ   NOT NULL,
    updated_at    TIMESTAMPTZ   NOT NULL,
    deleted       BOOLEAN       NOT NULL DEFAULT false,

    UNIQUE (username),

    CHECK (rating_total >= 0),
    CHECK (rating_count >= 0)
);


/* To reduce index size, we don't use UNIQUE constraint on email field. In stead, we created a expression index that
 * only indexes the account part of an email address, which could make the email index about 50% smaller.
 */
CREATE INDEX users_email_index ON users (split_part(email, '@', 1));
