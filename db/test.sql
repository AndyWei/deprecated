\ir  setup.sql


INSERT INTO users
    (username,                                                       password,                 email, role, status, created_at, updated_at, deleted) VALUES
    (  'jack', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'jack.davi@gmail.com',    1,      1,      now(),      now(),   FALSE),
    (  'andy', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'andy94555@gmail.com',    1,      1,      now(),      now(),   FALSE),
    (  'ping', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'ping@gmail.com',         1,      1,      now(),      now(),   FALSE),
    (  'mike', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'mike95273@gmail.com',    1,      1,      now(),      now(),   FALSE);


INSERT INTO reviews
    (reviewer_id, reviewee_id, rating,          comment, created_at,  updated_at) VALUES
    (          2,           1,      4, 'fixedin 5 mins',      now(),      now()),
    (          3,           2,      5, 'best quality!!',      now(),      now()),
    (          4,           2,    4.5,     'super pro!',      now(),      now());


INSERT INTO orders
    (user_id, winner_id, review_id, initial_price,  status, category, created_at, updated_at,  description, venue) VALUES
    (      1,         1,         1,          0.99,       1,        1,      now(),      now(),  'jumpstart', ST_SetSRID(ST_MakePoint(-122.4164623, 37.7766092), 4326)),
    (      1,         3,         2,         89.99,       2,        5,      now(),      now(),      'clean', ST_SetSRID(ST_MakePoint(-122.4074981, 37.7879331), 4326)),
    (      1,         3,         3,     234567.99,       3,        2,      now(),      now(), 'ride to LA', ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326));


INSERT INTO bids
    (user_id, order_id,    offer_price,  status, created_at, updated_at,     description) VALUES
    (      2,         1,          3.99,       1,      now(),      now(),     'in 5 mins'),
    (      4,         1,          2.99,       4,      now(),      now(),  'best quality'),
    (      4,         1,          0.99,       5,      now(),      now(),    'super pro!');



