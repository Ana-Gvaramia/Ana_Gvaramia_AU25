-- TASK 1: Find all animation movies released between 2017-2019 with rental rate over $1
-- CTE Solution
WITH animation_films AS (
    SELECT
        f.film_id,
        f.title,
        f.release_year,
        f.rental_rate
    FROM public.film f
    INNER JOIN public.film_category fc ON f.film_id = fc.film_id
    INNER JOIN public.category c ON fc.category_id = c.category_id
    WHERE UPPER(c.name) = 'ANIMATION'
        AND f.release_year BETWEEN 2017 AND 2019
        AND f.rental_rate > 1)
SELECT
    title,
    release_year,
    rental_rate
FROM animation_films
ORDER BY title;

-- Subquery Solution
SELECT
    f.title,
    f.release_year,
    f.rental_rate
FROM public.film f
WHERE f.film_id IN (
    SELECT fc.film_id
    FROM public.film_category fc
    INNER JOIN public.category c ON fc.category_id = c.category_id
    WHERE UPPER(c.name) = 'ANIMATION')
AND f.release_year BETWEEN 2017 AND 2019
AND f.rental_rate > 1
ORDER BY f.title;

-- JOIN Solution
SELECT
    f.title,
    f.release_year,
    f.rental_rate
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE UPPER(c.name) = 'ANIMATION'
    AND f.release_year BETWEEN 2017 AND 2019
    AND f.rental_rate > 1
ORDER BY f.title;

-- TASK 2: Calculate how much money each store made from April 2017 onwards
-- CTE Solution
WITH
store_payments AS (
    SELECT
        s.store_id,
        s.address_id,
        p.amount
    FROM public.payment p
    INNER JOIN public.rental r ON p.rental_id = r.rental_id
    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN public.store s ON i.store_id = s.store_id
    WHERE p.payment_date >= '2017-04-01'),
store_addresses AS (
    SELECT
        sp.store_id,
        a.address,
        a.address2,
        sp.amount
    FROM store_payments sp
    INNER JOIN public.address a ON sp.address_id = a.address_id)
SELECT
    address || COALESCE(', ' || address2, '') AS full_address,
    SUM(amount) AS revenue
FROM store_addresses
GROUP BY store_id, address, address2
ORDER BY revenue DESC;

-- Subquery Solution
SELECT
    a.address || COALESCE(', ' || a.address2, '') AS full_address,
    (SELECT SUM(p.amount)
     FROM public.payment p
     INNER JOIN public.rental r ON p.rental_id = r.rental_id
     INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
     WHERE i.store_id = s.store_id
         AND p.payment_date >= '2017-04-01') AS revenue
FROM public.store s
INNER JOIN public.address a ON s.address_id = a.address_id
ORDER BY revenue DESC;

-- JOIN Solution
SELECT
    a.address || COALESCE(', ' || a.address2, '') AS full_address,
    SUM(p.amount) AS revenue
FROM public.store s
INNER JOIN public.address a ON s.address_id = a.address_id
INNER JOIN public.inventory i ON s.store_id = i.store_id
INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
INNER JOIN public.payment p ON r.rental_id = p.rental_id
WHERE p.payment_date >= '2017-04-01'
GROUP BY s.store_id, a.address, a.address2
ORDER BY revenue DESC;

-- TASK 3: Find the 5 actors who appeared in the most movies released after 2015
-- CTE Solution
WITH
actor_films AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        f.film_id
    FROM public.actor a
    INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
    INNER JOIN public.film f ON fa.film_id = f.film_id
    WHERE f.release_year > 2015),
actor_counts AS (
    SELECT
        actor_id,
        first_name,
        last_name,
        COUNT(film_id) AS number_of_movies
    FROM actor_films
    GROUP BY actor_id, first_name, last_name)
SELECT
    first_name,
    last_name,
    number_of_movies
FROM actor_counts
ORDER BY number_of_movies DESC
LIMIT 5;

-- Subquery Solution
SELECT
    a.first_name,
    a.last_name,
    (SELECT COUNT(*)
     FROM public.film_actor fa
     INNER JOIN public.film f ON fa.film_id = f.film_id
     WHERE fa.actor_id = a.actor_id
         AND f.release_year > 2015) AS number_of_movies
FROM public.actor a
WHERE EXISTS (
    SELECT 1
    FROM public.film_actor fa
    INNER JOIN public.film f ON fa.film_id = f.film_id
    WHERE fa.actor_id = a.actor_id
        AND f.release_year > 2015)
ORDER BY number_of_movies DESC
LIMIT 5;

-- JOIN Solution
SELECT
    a.first_name,
    a.last_name,
    COUNT(f.film_id) AS number_of_movies
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f ON fa.film_id = f.film_id
WHERE f.release_year > 2015
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;

-- TASK 4: Count Drama, Travel, and Documentary films for each year
-- CTE Solution
WITH
genre_films AS (
    SELECT
        f.release_year,
        c.name AS category_name
    FROM public.film f
    INNER JOIN public.film_category fc ON f.film_id = fc.film_id
    INNER JOIN public.category c ON fc.category_id = c.category_id
    WHERE UPPER(c.name) IN ('DRAMA', 'TRAVEL', 'DOCUMENTARY')),
years AS (
    SELECT DISTINCT release_year
    FROM public.film)
SELECT
    y.release_year,
    COALESCE(SUM((UPPER(gf.category_name) = 'DRAMA')::INT), 0) AS number_of_drama_movies,
    COALESCE(SUM((UPPER(gf.category_name) = 'TRAVEL')::INT), 0) AS number_of_travel_movies,
    COALESCE(SUM((UPPER(gf.category_name) = 'DOCUMENTARY')::INT), 0) AS number_of_documentary_movies
FROM years y
LEFT JOIN genre_films gf ON y.release_year = gf.release_year
GROUP BY y.release_year
ORDER BY y.release_year DESC;

-- Subquery Solution
SELECT
    f.release_year,
    (SELECT COUNT(*)
     FROM public.film f2
     INNER JOIN public.film_category fc2 ON f2.film_id = fc2.film_id
     INNER JOIN public.category c2 ON fc2.category_id = c2.category_id
     WHERE UPPER(c2.name) = 'DRAMA'
         AND f2.release_year = f.release_year) AS number_of_drama_movies,
    (SELECT COUNT(*)
     FROM public.film f3
     INNER JOIN public.film_category fc3 ON f3.film_id = fc3.film_id
     INNER JOIN public.category c3 ON fc3.category_id = c3.category_id
     WHERE UPPER(c3.name) = 'TRAVEL'
         AND f3.release_year = f.release_year) AS number_of_travel_movies,
    (SELECT COUNT(*)
     FROM public.film f4
     INNER JOIN public.film_category fc4 ON f4.film_id = fc4.film_id
     INNER JOIN public.category c4 ON fc4.category_id = c4.category_id
     WHERE UPPER(c4.name) = 'DOCUMENTARY'
         AND f4.release_year = f.release_year) AS number_of_documentary_movies
FROM (SELECT DISTINCT release_year FROM public.film) f
ORDER BY f.release_year DESC;

-- JOIN Solution
SELECT
    f.release_year,
    COALESCE(SUM((UPPER(c.name) = 'DRAMA')::INT), 0) AS number_of_drama_movies,
    COALESCE(SUM((UPPER(c.name) = 'TRAVEL')::INT), 0) AS number_of_travel_movies,
    COALESCE(SUM((UPPER(c.name) = 'DOCUMENTARY')::INT), 0) AS number_of_documentary_movies
FROM public.film f
LEFT JOIN public.film_category fc ON f.film_id = fc.film_id
LEFT JOIN public.category c ON fc.category_id = c.category_id
    AND UPPER(c.name) IN ('DRAMA', 'TRAVEL', 'DOCUMENTARY')
GROUP BY f.release_year
ORDER BY f.release_year DESC;

-- TASK 5: Find which 3 employees made the most money in 2017
-- CTE Solution
WITH employee_revenue AS (
    SELECT
        p.staff_id,
        SUM(p.amount) AS total_revenue
    FROM public.payment p
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY p.staff_id),
last_store AS (
    SELECT DISTINCT ON (p.staff_id)
        p.staff_id,
        st.store_id
    FROM public.payment p
    INNER JOIN public.staff st ON p.staff_id = st.staff_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    ORDER BY p.staff_id, p.payment_date DESC),
staff_info AS (
    SELECT
        st.staff_id,
        st.first_name,
        st.last_name
    FROM public.staff st)
SELECT
    si.first_name,
    si.last_name,
    ls.store_id,
    er.total_revenue
FROM employee_revenue er
INNER JOIN staff_info si ON er.staff_id = si.staff_id
INNER JOIN last_store ls ON er.staff_id = ls.staff_id
ORDER BY er.total_revenue DESC
LIMIT 3;

-- Subquery Solution
SELECT
    st.first_name,
    st.last_name,
    (   SELECT st2.store_id
        FROM public.payment p2
        INNER JOIN public.staff st2 ON p2.staff_id = st2.staff_id
        WHERE p2.staff_id = st.staff_id
          AND EXTRACT(YEAR FROM p2.payment_date) = 2017
        ORDER BY p2.payment_date DESC
        LIMIT 1) AS store_id,
    SUM(p.amount) AS total_revenue
FROM public.staff st
INNER JOIN public.payment p ON st.staff_id = p.staff_id
WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
GROUP BY st.staff_id, st.first_name, st.last_name
ORDER BY total_revenue DESC
LIMIT 3;

-- JOIN Solution
SELECT
    st.first_name,
    st.last_name,
    ls.store_id,
    SUM(p.amount) AS total_revenue
FROM public.staff st
INNER JOIN public.payment p 
    ON st.staff_id = p.staff_id
    AND EXTRACT(YEAR FROM p.payment_date) = 2017
INNER JOIN (
    SELECT DISTINCT ON (staff_id)
        staff_id,
        store_id
    FROM (
        SELECT
            p.staff_id,
            s.store_id,
            p.payment_date
        FROM public.payment p
        INNER JOIN public.staff s ON p.staff_id = s.staff_id
        WHERE EXTRACT(YEAR FROM p.payment_date) = 2017) AS ranked
    ORDER BY staff_id, payment_date DESC) ls ON st.staff_id = ls.staff_id
GROUP BY st.staff_id, st.first_name, st.last_name, ls.store_id
ORDER BY total_revenue DESC
LIMIT 3;

-- TASK 6: Find the 5 most popular movies and show recommended age
-- CTE Solution
WITH
rental_counts AS (
    SELECT
        i.film_id,
        COUNT(r.rental_id) AS number_of_rentals
    FROM public.rental r
    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
    GROUP BY i.film_id),
top_films AS (
    SELECT
        film_id,
        number_of_rentals
    FROM rental_counts
    ORDER BY number_of_rentals DESC
    LIMIT 5),
films_with_ages AS (
    SELECT
        f.title,
        tf.number_of_rentals,
        f.rating,
        COALESCE((SELECT 'All ages' WHERE (f.rating) = 'G'), '') ||
        COALESCE((SELECT '7+ (Parental guidance)' WHERE (f.rating) = 'PG'), '') ||
        COALESCE((SELECT '13+' WHERE (f.rating) = 'PG-13'), '') ||
        COALESCE((SELECT '17+' WHERE (f.rating) = 'R'), '') ||
        COALESCE((SELECT '18+' WHERE (f.rating) = 'NC-17'), '') AS expected_age
    FROM top_films tf
    INNER JOIN public.film f ON tf.film_id = f.film_id)
SELECT
    title,
    number_of_rentals,
    rating,
    expected_age
FROM films_with_ages
ORDER BY number_of_rentals DESC;

-- Subquery Solution
SELECT 
    f.title,
    (SELECT COUNT(r.rental_id)
     FROM public.rental r
     INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
     WHERE i.film_id = f.film_id) AS number_of_rentals,
    f.rating,
    CASE --couldnt think of anything else to deal with NULLs
        WHEN (f.rating) = 'G' THEN 'All ages'
        WHEN (f.rating) = 'PG' THEN '7+ (Parental guidance)'
        WHEN (f.rating) = 'PG-13' THEN '13+'
        WHEN (f.rating) = 'R' THEN '17+'
        WHEN (f.rating) = 'NC-17' THEN '18+'
        ELSE 'Not rated'
    END AS expected_age
FROM public.film f
WHERE EXISTS (
    SELECT 1
    FROM public.inventory i
    INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
    WHERE i.film_id = f.film_id)
ORDER BY number_of_rentals DESC
LIMIT 5;

-- JOIN Solution
SELECT
    f.title,
    COUNT(r.rental_id) AS number_of_rentals,
    f.rating,
    COALESCE((SELECT 'All ages' WHERE (f.rating) = 'G'), '') ||
    COALESCE((SELECT '7+ (Parental guidance)' WHERE (f.rating) = 'PG'), '') ||
    COALESCE((SELECT '13+' WHERE (f.rating) = 'PG-13'), '') ||
    COALESCE((SELECT '17+' WHERE (f.rating) = 'R'), '') ||
    COALESCE((SELECT '18+' WHERE (f.rating) = 'NC-17'), '') AS expected_age
FROM public.film f
INNER JOIN public.inventory i ON f.film_id = i.film_id
INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title, f.rating
ORDER BY number_of_rentals DESC
LIMIT 5;

-- TASK 7 VERSION 1: Calculate how many years since each actor's last movie
-- CTE Solution
WITH actor_latest_film AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        MAX(f.release_year) AS latest_release_year
    FROM public.actor a
    INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
    INNER JOIN public.film f ON fa.film_id = f.film_id
    GROUP BY a.actor_id, a.first_name, a.last_name)
SELECT
    first_name,
    last_name,
    latest_release_year,
    (2025 - latest_release_year) AS years_since_last_film
FROM actor_latest_film
ORDER BY years_since_last_film DESC,
         last_name,
         first_name;

-- Subquery Solution
SELECT
    a.first_name,
    a.last_name,
    (SELECT MAX(f.release_year)
     FROM public.film_actor fa
     INNER JOIN public.film f ON fa.film_id = f.film_id
     WHERE fa.actor_id = a.actor_id) AS latest_release_year,
    2025 - (SELECT MAX(f.release_year)
            FROM public.film_actor fa
            INNER JOIN public.film f ON fa.film_id = f.film_id
            WHERE fa.actor_id = a.actor_id) AS years_since_last_film
FROM public.actor a
WHERE EXISTS (
    SELECT 1
    FROM public.film_actor fa
    WHERE fa.actor_id = a.actor_id)
ORDER BY years_since_last_film DESC,
         a.last_name,
         a.first_name;

-- JOIN Solution
SELECT
    a.first_name,
    a.last_name,
    MAX(f.release_year) AS latest_release_year,
    (2025 - MAX(f.release_year)) AS years_since_last_film
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY years_since_last_film DESC,
         a.last_name,
         a.first_name;

-- TASK 7 VERSION 2: Find the largest gap between consecutive films for each actor
-- CTE Solution
WITH actor_films AS (
    SELECT DISTINCT
        a.actor_id,
        a.first_name,
        a.last_name,
        f.release_year
    FROM public.actor a
    INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
    INNER JOIN public.film f ON fa.film_id = f.film_id),
film_pairs AS (
    SELECT
        af1.actor_id,
        af1.first_name,
        af1.last_name,
        af1.release_year AS current_year,
        (SELECT MIN(af2.release_year)
         FROM actor_films af2
         WHERE af2.actor_id = af1.actor_id
             AND af2.release_year > af1.release_year) AS next_year
    FROM actor_films af1),
gaps_calculated AS (
    SELECT
        actor_id,
        first_name,
        last_name,
        current_year,
        next_year,
        (next_year - current_year) AS gap_years
    FROM film_pairs
    WHERE next_year IS NOT NULL)
SELECT
    gc.first_name,
    gc.last_name,
    gc.current_year,
    gc.next_year,
    gc.gap_years
FROM gaps_calculated gc
WHERE gc.gap_years = (
    SELECT MAX(gc2.gap_years)
    FROM gaps_calculated gc2
    WHERE gc2.actor_id = gc.actor_id)
ORDER BY gc.last_name,
         gc.first_name;

-- Subquery Solution
WITH all_gaps AS (
    SELECT
        af.actor_id,
        af.first_name,
        af.last_name,
        af.release_year AS current_year,
        (SELECT MIN(f2.release_year)
         FROM public.actor a2
         INNER JOIN public.film_actor fa2 ON a2.actor_id = fa2.actor_id
         INNER JOIN public.film f2 ON fa2.film_id = f2.film_id
         WHERE a2.actor_id = af.actor_id
             AND f2.release_year > af.release_year) AS next_year,
        ((SELECT MIN(f2.release_year)
          FROM public.actor a2
          INNER JOIN public.film_actor fa2 ON a2.actor_id = fa2.actor_id
          INNER JOIN public.film f2 ON fa2.film_id = f2.film_id
          WHERE a2.actor_id = af.actor_id
              AND f2.release_year > af.release_year) - af.release_year) AS gap_years
    FROM (
        SELECT DISTINCT
            a.actor_id,
            a.first_name,
            a.last_name,
            f.release_year
        FROM public.actor a
        INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
        INNER JOIN public.film f ON fa.film_id = f.film_id) af
    WHERE EXISTS (
        SELECT 1
        FROM public.film_actor fa3
        INNER JOIN public.film f3 ON fa3.film_id = f3.film_id
        WHERE fa3.actor_id = af.actor_id
            AND f3.release_year > af.release_year))
SELECT
    ag.first_name,
    ag.last_name,
    ag.current_year,
    ag.next_year,
    ag.gap_years
FROM all_gaps ag
WHERE ag.gap_years = (
    SELECT MAX(ag2.gap_years)
    FROM all_gaps ag2
    WHERE ag2.actor_id = ag.actor_id)
ORDER BY ag.last_name,
         ag.first_name;

-- JOIN Solution
WITH all_gaps AS (
    SELECT
        af1.actor_id,
        af1.first_name,
        af1.last_name,
        af1.release_year AS current_year,
        MIN(af2.release_year) AS next_year,
        (MIN(af2.release_year) - af1.release_year) AS gap_years
    FROM (
        SELECT DISTINCT
            a.actor_id,
            a.first_name,
            a.last_name,
            f.release_year
        FROM public.actor a
        INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
        INNER JOIN public.film f ON fa.film_id = f.film_id) af1
    LEFT JOIN (
        SELECT DISTINCT
            a.actor_id,
            f.release_year
        FROM public.actor a
        INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
        INNER JOIN public.film f ON fa.film_id = f.film_id) af2 ON af1.actor_id = af2.actor_id
        AND af2.release_year > af1.release_year
    GROUP BY af1.actor_id, af1.first_name, af1.last_name, af1.release_year
    HAVING MIN(af2.release_year) IS NOT NULL)
SELECT
    ag.first_name,
    ag.last_name,
    ag.current_year,
    ag.next_year,
    ag.gap_years
FROM all_gaps ag
WHERE ag.gap_years = (
    SELECT MAX(ag2.gap_years)
    FROM all_gaps ag2
    WHERE ag2.actor_id = ag.actor_id)
ORDER BY ag.last_name,
         ag.first_name;