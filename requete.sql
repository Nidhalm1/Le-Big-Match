-- Active: 1739617017649@@localhost@5432@le_big_match@public
/*a faire par mon ami d'afrique*/
-- =============================
-- REQUETES SQL - Le Big Match
-- =============================

-- 1. Liste des événements futurs d'une ville donnée
SELECT title, starts_at
FROM event
WHERE city = 'Paris'
  AND starts_at > CURRENT_TIMESTAMP;

-- 2. Nombre de likes reçus par utilisateur
SELECT u.pseudo, COUNT(l.source_user_id) AS likes_received
FROM "user" u
LEFT JOIN likes l ON l.target_user_id = u.user_id
WHERE l.value = 'like'
GROUP BY u.user_id, u.pseudo
ORDER BY likes_received DESC;

-- 3. Utilisateurs ayant liké réciproquement (matches)
SELECT a.pseudo AS user1, b.pseudo AS user2
FROM likes l1
JOIN likes l2 ON l1.source_user_id = l2.target_user_id
             AND l1.target_user_id = l2.source_user_id
JOIN "user" a ON l1.source_user_id = a.user_id
JOIN "user" b ON l1.target_user_id = b.user_id
WHERE l1.value = 'like' AND l2.value = 'like'
  AND l1.source_user_id < l1.target_user_id;

-- 4. Utilisateurs n'ayant jamais liké personne
SELECT pseudo
FROM "user" u
WHERE NOT EXISTS (
    SELECT 1
    FROM likes l
    WHERE l.source_user_id = u.user_id
);

-- 5. Nombre d'événements par lieu
SELECT p.name, e.event_count
FROM place p
JOIN (
    SELECT place_id, COUNT(*) AS event_count
    FROM event
    GROUP BY place_id
) e ON p.place_id = e.place_id;

-- 6. Utilisateurs avec au moins un abonnement actif
SELECT pseudo
FROM "user"
WHERE user_id IN (
    SELECT user_id
    FROM subscription
    WHERE start_date <= CURRENT_DATE
      AND (end_date IS NULL OR end_date >= CURRENT_DATE)
);

-- 7. Lieux ayant au moins 3 événements
SELECT p.name, COUNT(e.event_id) AS event_count
FROM place p
JOIN event e ON p.place_id = e.place_id
GROUP BY p.place_id, p.name
HAVING COUNT(e.event_id) >= 3;

-- 8. Moyenne et somme des prix d'événements
SELECT AVG(price) AS average_price, SUM(price) AS total_price
FROM event
WHERE price IS NOT NULL;

-- 9. Tous les événements même sans lieu
SELECT e.title, p.name
FROM event e
LEFT JOIN place p ON e.place_id = p.place_id;

-- 10. Utilisateurs ayant liké tous les autres (sous-requête corrélée)
SELECT u1.pseudo
FROM "user" u1
WHERE NOT EXISTS (
    SELECT 1
    FROM "user" u2
    WHERE u1.user_id <> u2.user_id
      AND NOT EXISTS (
          SELECT 1
          FROM likes l
          WHERE l.source_user_id = u1.user_id
            AND l.target_user_id = u2.user_id
            AND l.value = 'like'
      )
);

-- 11. Utilisateurs ayant liké tous les autres (agrégation)
SELECT u1.pseudo
FROM "user" u1
JOIN likes l ON u1.user_id = l.source_user_id
GROUP BY u1.user_id, u1.pseudo
HAVING COUNT(DISTINCT l.target_user_id) = (SELECT COUNT(*) - 1 FROM "user");

-- 12A. Comparaison simple avec NULLs
SELECT pseudo
FROM "user"
WHERE country = 'France';

-- 12B. Comparaison NULL-safe
SELECT pseudo
FROM "user"
WHERE country IS NOT DISTINCT FROM 'France';

-- 13. Catégories et sous-catégories (requête récursive)
WITH RECURSIVE category_tree AS (
    SELECT category_id, name, parent_id
    FROM category
    WHERE parent_id IS NULL
    UNION ALL
    SELECT c.category_id, c.name, c.parent_id
    FROM category c
    JOIN category_tree ct ON c.parent_id = ct.category_id
)
SELECT * FROM category_tree;

-- 14. Top 5 utilisateurs par nombre de likes reçus par mois (fenêtrage)
SELECT pseudo, month, likes_received
FROM (
    SELECT u.pseudo,
           EXTRACT(MONTH FROM l.created_at) AS month,
           COUNT(*) AS likes_received,
           RANK() OVER (PARTITION BY EXTRACT(MONTH FROM l.created_at) ORDER BY COUNT(*) DESC) as rank
    FROM likes l
    JOIN "user" u ON l.target_user_id = u.user_id
    GROUP BY u.pseudo, month
) ranked
WHERE rank <= 5;

-- 15. Événements avec plus de 5 utilisateurs intéressés
SELECT e.title, COUNT(p.user_id) as interested_count
FROM event e
JOIN participation p ON p.event_id = e.event_id
WHERE p.status = 'interested'
GROUP BY e.event_id, e.title
HAVING COUNT(p.user_id) > 5;

-- 16. Utilisateurs ayant participé à des événements gratuits
SELECT DISTINCT u.pseudo
FROM "user" u
JOIN participation p ON u.user_id = p.user_id
JOIN event e ON e.event_id = p.event_id
WHERE e.price = 0;

-- 17. Liste des abonnements expirés
SELECT user_id, start_date, end_date
FROM subscription
WHERE end_date IS NOT NULL AND end_date < CURRENT_DATE;

-- 18. Événements sans participants
SELECT e.title
FROM event e
LEFT JOIN participation p ON e.event_id = p.event_id
WHERE p.user_id IS NULL;

-- 19. Nombre de tags par utilisateur
SELECT target_id AS user_id, COUNT(tag_id) AS tag_count
FROM tag_assignment
WHERE target_type = 'user'
GROUP BY target_id;

-- 20. Nombre de comptes sociaux par utilisateur
SELECT u.pseudo, COUNT(sa.sa_id) AS social_accounts
FROM "user" u
LEFT JOIN social_account sa ON sa.user_id = u.user_id
GROUP BY u.pseudo;
