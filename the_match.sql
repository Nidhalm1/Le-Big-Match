-- =============================
-- ALGORITHME DE MATCHING - Le Big Match
-- =============================

-- Paramètre : ID de l'utilisateur connecté
-- Remplacer :current_user_id par l'ID réel souhaité

-- 1. Calcul des matches effectifs par événement
WITH effective AS (
    SELECT 
        e.event_id,
        COUNT(*) AS effective_matches
    FROM mv_matches m
    JOIN participation p1 ON p1.user_id = m.user_a
    JOIN participation p2 ON p2.user_id = m.user_b
    JOIN event e ON p1.event_id = e.event_id AND p2.event_id = e.event_id
    WHERE p1.status = 'going' AND p2.status = 'going'
    GROUP BY e.event_id
),

-- 2. Calcul des matches potentiels par événement
potential AS (
    SELECT 
        e.event_id,
        COUNT(*) AS potential_matches
    FROM participation p
    JOIN (
        SELECT u.user_id
        FROM "user" u
        JOIN (SELECT * FROM "user" WHERE user_id = :current_user_id) AS ui
          ON u.city = ui.city
        WHERE u.user_id != ui.user_id
          AND (
              (ui.orientation = 'heterosexual' AND u.gender <> ui.gender)
              OR (ui.orientation = 'other')
          )
    ) pm ON p.user_id = pm.user_id
    JOIN event e ON e.event_id = p.event_id
    WHERE p.status = 'going'
    GROUP BY e.event_id
)

-- 3. Recommandation finale : calcul de l'indice
SELECT 
    e.event_id,
    e.title,
    COALESCE(2 * effective.effective_matches, 0) + COALESCE(1 * potential.potential_matches, 0) AS recommendation_index
FROM event e
LEFT JOIN effective ON e.event_id = effective.event_id
LEFT JOIN potential ON e.event_id = potential.event_id
ORDER BY recommendation_index DESC;

-- =============================
-- Exemple d'exécution :
-- =============================
-- Remplacer :current_user_id par une vraie valeur
-- Exemple :
-- (Supposons que l'utilisateur courant a l'ID 5)

-- Exécution rapide :
-- SET current_user_id = 5; -- si on utilise des variables, sinon remplacer manuellement
-- Puis exécuter le script ci-dessus.

-- Sinon remplacer directement :
-- WHERE user_id = 5
-- (au lieu de :current_user_id)
