# InstaVibe-socialmedia-sql-project

A mini social-media platform, modeled entirely in SQL, built to answer the same questions real platforms like Instagram or TikTok ask about their users every day: which content is going viral, who are the most influential creators, who follows whom, and which followers are actually inactive "ghosts."

This project was built from scratch; schema design, sample data, and every query, as a hands-on way to practice relational database design and intermediate-to-advanced SQL.


## Why This Project

Most SQL practice involves isolated exercises. InstaVibe instead simulates a real, connected product — a social app — so that every query answers an actual business question instead of just demonstrating syntax. It mirrors the kind of analysis a Data Analyst at a social media or content company would actually be asked to do.


## Database Schema

The database consists of 5 interconnected tables:

| Table | Description |
|---|---|
| `users` | Platform users (id, username, signup date) |
| `posts` | Content posted by users (video / image / text) |
| `likes` | Which user liked which post |
| `comments` | Comments left by users on posts |
| `follows` | Follower relationships between users |

### Entity Relationship Overview

```
users ──┬──< posts ──┬──< likes
        │             └──< comments
        └──< follows >──┘  (self-referencing: follower_id & following_id
                             both point back to users)
```

- One user → many posts (1-to-many)
- One post → many likes, many comments (1-to-many)
- Users can follow other users; `follows` is a self-referencing table, since both `follower_id` and `following_id` point back to `users.id`

## Tech Stack

- **Database:** MySQL
- **Concepts used:** Relational schema design, foreign keys, joins, aggregate functions, views, subqueries, CTEs, window functions


## How to Run This Project

1. Clone this repository
2. Open `instaVibe.sql` in MySQL Workbench (or any MySQL client)
3. Run the script top to bottom, it will:
   - Create the `instavibe` database
   - Create all 5 tables with foreign key constraints
   - Insert realistic sample data (10 posts, 31 likes, 8 comments, 7 follow relationships, intentionally designed so one post goes viral and a few followers never engage, to make the analysis interesting)
   - Create a reusable `post_engagement` view
   - Run every analytical query described below

```bash
mysql -u your_username -p < instaVibe.sql
```

## Key Analyses

The full script (`instaVibe.sql`) contains all 8 queries with detailed comments. A few highlights:

### Reusable Engagement View

Combines likes and comments per post into a single `engagement_score`, so the logic can be reused anywhere without rewriting the join. `COUNT(DISTINCT ...)` prevents row-inflation that happens when joining two "many" tables (likes and comments) at once.

```sql
CREATE VIEW post_engagement AS
SELECT p.id AS post_id, p.user_id, u.username, p.content_type, p.caption,
       COUNT(DISTINCT l.id) AS total_likes,
       COUNT(DISTINCT c.id) AS total_comments,
       (COUNT(DISTINCT l.id) + COUNT(DISTINCT c.id)) AS engagement_score
FROM posts p
JOIN users u ON p.user_id = u.id
LEFT JOIN likes l ON p.id = l.post_id
LEFT JOIN comments c ON p.id = c.post_id
GROUP BY p.id, p.user_id, u.username, p.content_type, p.caption;
```

### Ghost Follower Detection — Subquery + UNION

Identifies followers who follow a user but have never liked or commented on any of their posts — a common real-world "fake/inactive follower" check.

```sql
SELECT f.follower_id, u.username AS ghost_follower
FROM follows f
JOIN users u ON f.follower_id = u.id
WHERE f.following_id = 1
  AND f.follower_id NOT IN (
      SELECT l.user_id FROM likes l
      JOIN posts p ON l.post_id = p.id WHERE p.user_id = 1
      UNION
      SELECT c.user_id FROM comments c
      JOIN posts p ON c.post_id = p.id WHERE p.user_id = 1
  );
```

### Creator Leaderboard — CTE + Window Function (RANK)

Sums total engagement per user across all their posts, then ranks every creator on the platform from most to least popular.

```sql
WITH user_totals AS (
    SELECT user_id, username, SUM(engagement_score) AS total_engagement
    FROM post_engagement
    GROUP BY user_id, username
)
SELECT username, total_engagement,
       RANK() OVER (ORDER BY total_engagement DESC) AS creator_rank
FROM user_totals;
```

> See `instaVibe.sql` for the remaining queries: post feed joins, likes-per-post aggregation, full per-post engagement, mutual follows (self-join), and best post per user (`ROW_NUMBER`).


## SQL Concepts Demonstrated

- Relational schema design with foreign keys
- `INNER JOIN`, `LEFT JOIN`, and `SELF JOIN`
- Aggregate functions (`COUNT`, `SUM`) with `GROUP BY`
- `COUNT(DISTINCT ...)` to prevent join-fan-out row inflation
- Views for reusable, maintainable query logic
- Subqueries with `NOT IN` and `UNION`
- Common Table Expressions (CTEs) with `WITH`
- Window functions — `ROW_NUMBER()`, `RANK()`, `PARTITION BY`


## Sample Insights From the Data

- **Most viral post:** `sara_vibes`'s "Dance challenge" video, with the highest combined likes + comments
- **Top creator (leaderboard):** `sara_vibes` ranks #1 by total platform engagement
- **Ghost followers found:** users who follow `ali_creates` but have never liked or commented on any of his posts
- **Mutual connections:** several user pairs follow each other back, forming the platform's "real" social graph


## Repository Structure

```
├── instaVibe.sql     # Full schema, sample data, view, and all queries
└── README.md          # This file
```


## Author

Built as a self-guided SQL learning project, designing the schema, writing every query, and debugging each mistake independently along the way.

Feedback and suggestions are welcome — feel free to open an issue or connect!
