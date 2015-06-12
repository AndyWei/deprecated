\ir  setup.sql


INSERT INTO users
    (username,                                                       password,                 email, joyyor_status, rating_total, rating_count, created_at, updated_at, deleted) VALUES
    (  'jack', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG',      'jack@gmail.com',             0,           10,            2,      now(),      now(),   FALSE),
    (  'andy', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'andy94555@gmail.com',             1,            9,            2,      now(),      now(),   FALSE),
    (  'ping', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'ping@gmail.com',                  0,            0,            0,      now(),      now(),   FALSE),
    (  'mike', '$2a$10$sTaFcBz.lhDXr2bVNZJZeenPJ3qiKG.NaQQ5zqiz0peku0fDvO0YG', 'mike95273@gmail.com',             0,           13,            3,      now(),      now(),   FALSE);


INSERT INTO accounts
    (user_id,                 email,       stripe_account_id,                             secret,                        publishable,  created_at, updated_at) VALUES
    (      2, 'andy94555@gmail.com', 'acct_16CNevL3foSC1Ck4', 'sk_test_y6qiee71SA8RB4eA7ubfcabt', 'pk_test_A5X5cmWlRb6OvOzjdBlpKszB',       now(),      now());


INSERT INTO orders
    (user_id, winner_id,  price,  status, category, created_at, updated_at,      title,     note,                                              start_point,   start_city,     start_address, start_time) VALUES
    (      1,      NULL,    199,       0,        1,      now(),      now(),    'clean', 'order0', ST_SetSRID(ST_MakePoint(-122.4164623, 37.7766092), 4326),    'Fremont',      '1 Joyy Way', 450694731),
    (      1,      NULL,    899,       0,        5,      now(),      now(),   'moving', 'order1', ST_SetSRID(ST_MakePoint(-122.4074981, 37.7879331), 4326), 'Menlo Park',      '1 Hack Way', 451594731),
    (      1,      NULL, 234567,       0,        4,      now(),      now(), 'handyman', 'order2', ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326),  'Cupertino', '1 Infinite Loop', 450794731),
    (      1,         3,  56799,      10,        0,      now(),      now(),    'Other', 'order3', ST_SetSRID(ST_MakePoint(-121.9989519, 37.5293864), 4326),  'Cupertino', '1 Infinite Loop', 450894731);


INSERT INTO bids
    (user_id, order_id, price, status, expire_at, created_at, updated_at,         note) VALUES
    (      2,        1,   399,      3, 1427159567,     now(),      now(), 'for accept'),
    (      2,        1,   299,     10, 1427159543,     now(),      now(), 'for accept'),
    (      2,        1,    99,      2, 1427160123,     now(),      now(), 'for accept'),
    (      2,        1,    99,      0, 1427160123,     now(),      now(), 'for accept'),
    (      2,        3,   399,      0, 1427159567,     now(),      now(), 'for revoke'),
    (      2,        3,   299,      3, 1427159543,     now(),      now(), 'for revoke'),
    (      2,        3,    99,      2, 1427160123,     now(),      now(), 'for revoke'),
    (      2,        3,    99,     10, 1427160123,     now(),      now(), 'for revoke');


INSERT INTO comments
    (order_id, user_id, username, created_at, updated_at, body) VALUES
    (       1,       2,   'andy',      now(),      now(), 'How many sqft?'),
    (       1,       3,   'ping',      now(),      now(), 'Include kitchen as well?'),
    (       1,       4,   'mike',      now(),      now(), 'I know your house is quite huge bro, its really difficult at this price man. I may consider 500 bucks'),
    (       1,       1,   'jack',      now(),      now(), '@mike Just 3000 sqft, and 500 bucks is ridiculous！$499 is my bottomline!!'),
    (       2,       2,   'andy',      now(),      now(), 'This is andy!'),
    (       2,       3,   'ping',      now(),      now(), 'Ping'),
    (       2,       4,   'mike',      now(),      now(), 'Mike always talk a lot: I know your house is quite huge bro, its really difficult at this price man. I may consider 500 bucks'),
    (       2,       1,   'jack',      now(),      now(), '@mike Just 3000 sqft, and 500 bucks is ridiculous！$499 is my bottomline!!');

INSERT INTO reviews
    (reviewer_id, reviewee_id, order_id, rating,             body, created_at,  updated_at) VALUES
    (          2,           1,        1,      4, 'fixedin 5 mins',      now(),      now()),
    (          3,           2,        2,      5, 'best quality!!',      now(),      now()),
    (          4,           2,        3,    4.5,     'super pro!',      now(),      now());


