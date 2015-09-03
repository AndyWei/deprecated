CREATE TABLE post (
    id                 BIGSERIAL  PRIMARY KEY,
    owner              BIGINT        NOT NULL,  -- the person.id of the owner who uploaded this post
    filename           TEXT          NOT NULL,  -- the file name with suffix. e.g., j0176_458354045799.jpg
    caption            TEXT          NOT NULL,
    cell               TEXT          NOT NULL, -- the cell where the post belongs to
    coords             GEOMETRY(Point, 4326) NOT NULL,  -- the coordinate of the place where the post was uploaded. It's used for searching
    likes              INTEGER       NOT NULL DEFAULT 0, -- the number of likes
    comments           INTEGER       NOT NULL DEFAULT 0, -- the number of comments
    ct                 BIGINT        NOT NULL,
    deleted            BOOLEAN       NOT NULL DEFAULT false
);


CREATE INDEX post_owner_index  ON post (owner);
CREATE INDEX post_ct_index     ON post (ct);

/* 
 * Note: the post url = base_url/filename, where the base_url has been hardcoded to post.joyyapp.com
*/