\ir  setup.sql


INSERT INTO users
    (username,                                                       password,                 email, role, status, created_at, updated_at, deleted) VALUES
    (  'jack', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'jack.davi@gmail.com',    1,      1,      now(),      now(),   FALSE),
    (  'andy', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'andy94555@gmail.com',    1,      1,      now(),      now(),   FALSE),
    (  'ping', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'ping@gmail.com',         1,      1,      now(),      now(),   FALSE),
    (  'mike', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'mike95273@gmail.com',    1,      1,      now(),      now(),   FALSE);


INSERT INTO orders
    (user_id, winner_id,     price,  status, category, created_at, updated_at,  description, venue) VALUES
    (      1,         1,      0.99,       0,        1,      now(),      now(),  'jumpstart', ST_SetSRID(ST_MakePoint(-122.4164623, 37.7766092), 4326)),
    (      1,         3,     89.99,       0,        5,      now(),      now(),      'clean', ST_SetSRID(ST_MakePoint(-122.4074981, 37.7879331), 4326)),
    (      1,      NULL, 234567.99,       0,        2,      now(),      now(), 'ride to LA', ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326)),
    (      1,         3,    567.99,       4,        2,      now(),      now(), 'ride to SF', ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326));


INSERT INTO bids
    (user_id, order_id, price, status, expire_at, created_at, updated_at,           note) VALUES
    (      2,        1,  3.99,      0, 1427159567,     now(),      now(),     'in 5 mins'),
    (      4,        1,  2.99,      4, 1427159543,     now(),      now(),  'best quality'),
    (      4,        1,  0.99,      4, 1427160123,     now(),      now(),    'super pro!');


INSERT INTO reviews
    (reviewer_id, reviewee_id, order_id, rating,          comment, created_at,  updated_at) VALUES
    (          2,           1,        1,      4, 'fixedin 5 mins',      now(),      now()),
    (          3,           2,        2,      5, 'best quality!!',      now(),      now()),
    (          4,           2,        3,    4.5,     'super pro!',      now(),      now());




