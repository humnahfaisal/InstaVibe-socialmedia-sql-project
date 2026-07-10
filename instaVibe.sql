CREATE DATABASE instavibe;
USE instavibe;

---------------------TABLE CREATION & JOINS---------------------------

CREATE TABLE users (
    id INT PRIMARY KEY,
    username VARCHAR(50),
    signup_date DATE
);
INSERT INTO users VALUES
(1, 'ali_creates', '2024-01-05'),
(2, 'sara_vibes',  '2024-01-10'),
(3, 'ahmed_daily', '2024-01-15'),
(4, 'fatima_art',  '2024-02-01'),
(5, 'bilal_gamer', '2024-02-05');
SELECT * FROM users;

CREATE TABLE posts (
    id INT PRIMARY KEY,
    user_id INT,
    content_type VARCHAR(20),
    caption VARCHAR(200),
    posted_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
INSERT INTO posts VALUES
(101, 1, 'video', 'My morning routine!', '2024-03-01 08:00:00'),
(102, 1, 'image', 'Sunset vibes', '2024-03-05 18:30:00'),
(103, 2, 'video', 'Dance challenge', '2024-03-02 14:00:00'),
(104, 2, 'image', 'Cafe hopping', '2024-03-10 10:00:00'),
(105, 3, 'text', 'Thoughts on productivity', '2024-03-03 09:00:00'),
(106, 4, 'image', 'New painting done!', '2024-03-04 12:00:00'),
(108, 5, 'video', 'Insane gaming clutch', '2024-03-06 20:00:00');

--Shows every post along with the username of the person who created it, 
--by joining the two tables together.--

SELECT u.username,u.id,p.caption, p.content_type, p.posted_at
from users u
join posts p on u.id=p.user_id;
CREATE TABLE likes (
    id INT PRIMARY KEY,
    post_id INT,
    user_id INT,
    liked_at DATETIME,
    FOREIGN KEY (post_id) REFERENCES posts(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
INSERT INTO likes VALUES
(1, 103, 1, '2024-03-02 14:05:00'),
(2, 103, 3, '2024-03-02 14:10:00'),
(3, 103, 4, '2024-03-02 14:15:00'),
(4, 103, 5, '2024-03-02 14:20:00'),
(5, 101, 2, '2024-03-01 09:00:00'),
(6, 101, 3, '2024-03-01 10:00:00'),
(7, 102, 2, '2024-03-05 19:00:00'),
(8, 106, 1, '2024-03-04 13:00:00'),
(9, 106, 2, '2024-03-04 14:00:00'),
(10, 108, 1, '2024-03-06 21:00:00');
SELECT * FROM likes;

--------------------------GROUP BY + COUNT (Aggregate Function)--------------
--Counts how many likes each post received, by grouping all like-records 
--by post_id.--

select post_id, count(id) AS total_likes
from likes
group by post_id;
CREATE TABLE comments (
    id INT PRIMARY KEY,
    post_id INT,
    user_id INT,
    comment_text VARCHAR(200),
    commented_at DATETIME,
    FOREIGN KEY (post_id) REFERENCES posts(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
INSERT INTO comments VALUES
(1, 103, 1, 'This is amazing!', '2024-03-02 14:12:00'),
(2, 103, 4, 'You are so talented', '2024-03-02 14:20:00'),
(3, 101, 2, 'Great routine bro', '2024-03-01 09:15:00'),
(4, 106, 3, 'Love the colors', '2024-03-04 14:30:00'),
(5, 108, 2, 'Insane play!!', '2024-03-06 21:15:00');
SELECT * FROM comments;

-------------------------LEFT JOIN + COUNT(DISTINCT)------------------
--hows both the total likes AND total comments for every post in one result — 
--even posts with zero engagement--

select p.id, count(DISTINCT l.id) AS total_likes, count(DISTINCT c.id) AS total_comments
from posts p
left join likes l on p.id=l.post_id
left join comments c on p.id=c.post_id
group by p.id;

--------------------------VIEW---------------------------
--Saves the above likes+comments logic permanently as a 
--reusable "virtual table" called post_engagement, so you never have 
--to rewrite that JOIN again.--

CREATE VIEW post_engagement AS
SELECT p.id AS post_id, p.user_id, u.username, p.content_type, p.caption,
    COUNT(DISTINCT l.id) AS total_likes, COUNT(DISTINCT c.id) AS total_comments,
    (COUNT(DISTINCT l.id) + COUNT(DISTINCT c.id)) AS engagement_score
FROM posts p
JOIN users u ON p.user_id = u.id
LEFT JOIN likes l ON p.id = l.post_id
LEFT JOIN comments c ON p.id = c.post_id
GROUP BY p.id, p.user_id, u.username, p.content_type, p.caption;

-- Uses that view to pull out the top 3 most
-- engaging posts on the platform (highest combined likes+comments).--

SELECT * FROM post_engagement
ORDER BY engagement_score DESC
LIMIT 3;

CREATE TABLE follows (
    follower_id INT,
    following_id INT,
    followed_at DATETIME,
    FOREIGN KEY (follower_id) REFERENCES users(id),
    FOREIGN KEY (following_id) REFERENCES users(id)
);
INSERT INTO follows VALUES
(2, 1, '2024-01-20'),
(1, 2, '2024-01-22'),
(3, 1, '2024-01-25'),
(4, 1, '2024-02-05'),
(1, 4, '2024-02-10'),
(5, 1, '2024-02-15'),
(1, 5, '2024-02-16');
SELECT COUNT(*) AS ali_followers
FROM follows
WHERE following_id = 1;

-------------------Mutual Follows (SELF JOIN)---------------
--Finds pairs of users who follow each other back (mutual connections) --

SELECT u1.username AS user_a, u2.username AS user_b
FROM follows f1
JOIN follows f2 ON f1.follower_id = f2.following_id AND f1.following_id = f2.follower_id
JOIN users u1 ON f1.follower_id = u1.id
JOIN users u2 ON f1.following_id = u2.id
WHERE u1.id < u2.id;

--------------------------Ghost Followers----------------------
--Identifies followers who follow Ali but have never liked
-- or commented on any of his posts — i.e., inactive/"ghost" followers.--

SELECT f.follower_id, u.username AS ghost_follower
FROM follows f
JOIN users u ON f.follower_id = u.id
WHERE f.following_id = 1
  AND f.follower_id NOT IN (
      SELECT l.user_id FROM likes l
      JOIN posts p ON l.post_id = p.id
      WHERE p.user_id = 1
      UNION
      SELECT c.user_id FROM comments c
      JOIN posts p ON c.post_id = p.id
      WHERE p.user_id = 1
  );
  
  -------------------Top Post Per User-----------------------------
  --For each user individually, finds their single best-performing post
  --using a window function to rank each user's own posts separately--
  
  WITH ranked_posts AS (
    SELECT user_id, username, caption, engagement_score,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY engagement_score DESC) AS rn
    FROM post_engagement
)
SELECT username, caption, engagement_score
FROM ranked_posts
WHERE rn = 1;

-----------------------Creator Leaderboard--------------------
--Adds up all engagement across all posts for each user, then 
--ranks every user from #1 (most popular creator) downward--

WITH user_totals AS (
    SELECT user_id, username, SUM(engagement_score) AS total_engagement
    FROM post_engagement
    GROUP BY user_id, username
)
SELECT username, total_engagement,
       RANK() OVER (ORDER BY total_engagement DESC) AS creator_rank
FROM user_totals;