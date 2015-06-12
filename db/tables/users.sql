CREATE TABLE users (
    id            BIGSERIAL  PRIMARY KEY,
    username      TEXT          NOT NULL,  -- when user signup, this field is generated automatically, and the user can modify it later
    password      TEXT          NOT NULL,  -- bcrypt hashed password, it always 60 bytes, however TEXT provides flexible
    email         TEXT          NOT NULL,  -- user use email to signup
    role          SMALLINT      NOT NULL DEFAULT 0,  -- 0-user, 1-admin, 2-test, 3-robot
    joyyor_status SMALLINT      NOT NULL DEFAULT 0,  -- 0-unverified, 1-verified
    rating_total  NUMERIC(8,1)  NOT NULL DEFAULT 0,
    rating_count  NUMERIC(6)    NOT NULL DEFAULT 0,
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
