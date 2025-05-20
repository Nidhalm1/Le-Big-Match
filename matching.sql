-- Création d’une vue temporaire avec score d’affinité entre utilisateurs
CREATE MATERIALIZED VIEW mv_affinity AS
SELECT
    u1.user_id AS user_a,
    u2.user_id AS user_b,
    COUNT(DISTINCT tu1.tag_id) AS common_tags,
    COUNT(DISTINCT p1.event_id) FILTER (WHERE p1.event_id = p2.event_id) AS common_events
FROM "user" u1
JOIN "user" u2 ON u1.user_id < u2.user_id
LEFT JOIN tag_user_assignment tu1 ON u1.user_id = tu1.user_id
LEFT JOIN tag_user_assignment tu2 ON u2.user_id = tu2.user_id AND tu1.tag_id = tu2.tag_id
LEFT JOIN participation p1 ON u1.user_id = p1.user_id
LEFT JOIN participation p2 ON u2.user_id = p2.user_id AND p1.event_id = p2.event_id
GROUP BY u1.user_id, u2.user_id;

-- Utilisateurs les plus compatibles avec l’utilisateur X
-- Pondération simple : 2 pts par tag commun, 1 pt par participation commune
SELECT
    user_b,
    (common_tags * 2 + common_events) AS affinity_score
FROM mv_affinity
WHERE user_a = 1
ORDER BY affinity_score DESC
LIMIT 5;

-- Événements recommandés à partir des profils compatibles
-- Basé sur affinité avec participants à l’événement
SELECT
    e.event_id,
    e.title,
    COUNT(*) AS compatible_attendees,
    AVG(a.common_tags * 2 + a.common_events) AS avg_affinity_score
FROM event e
JOIN participation p ON p.event_id = e.event_id
JOIN mv_affinity a ON a.user_b = p.user_id AND a.user_a = 1
WHERE e.starts_at > NOW()
GROUP BY e.event_id, e.title
ORDER BY avg_affinity_score DESC, compatible_attendees DESC
LIMIT 5;
