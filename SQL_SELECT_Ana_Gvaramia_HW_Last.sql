-- TASK 1: Find all animation movies released between 2017-2019 with rental rate over $1
-- Task asks to find animation films within a specific 3-year window that have premium pricing (above basic $1 rate), likely to identify higher-value inventory

-- CTE Solution
WITH animation_films AS (
    SELECT 
        f.film_id,        
        f.title,           
        f.release_year,  
        f.rental_rate      
    FROM public.film f
    INNER JOIN public.film_category fc ON f.film_id = fc.film_id  -- connect to category table through film_category
    INNER JOIN public.category c ON fc.category_id = c.category_id  --get category name
    WHERE c.name = 'Animation'                        
        AND f.release_year BETWEEN 2017 AND 2019    
        AND f.rental_rate > 1)

SELECT 
    title,
    release_year,
    rental_rate
FROM animation_films
ORDER BY title;  

--	Advantages: Most readable with clear separation of logic; Fast execution
--	Disadvantages: A bit too complicated and time-consuming; Unnecessarily resource usage heavy




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
    WHERE c.name = 'Animation')  --all animation film IDs
    AND f.release_year BETWEEN 2017 AND 2019 
    AND f.rental_rate > 1
ORDER BY f.title;


--	Advantages: Compact; Well optimized, Fast execution
--	Disadvantages: Less readable; the IN subquery could be inefficient with large datasets


-- JOIN Solution
SELECT 
    f.title,
    f.release_year,
    f.rental_rate
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id  --connect to categogry thorugh film_category
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE c.name = 'Animation'
    AND f.release_year BETWEEN 2017 AND 2019
    AND f.rental_rate > 1
ORDER BY f.title;

--	Advantages: Most straightforward and compact, Fast Execution, Least resource usage
--	Disadvantages: All logic can be harder to follow with complex conditions



-- TASK 2:Calculate how much money each store made from April 2017 onwards
--Task asks to calculate total revenue per physical store location from a specific date forward, connecting payments through staff assignments to determine which store gets credit

-- CTE Solution
WITH 
store_payments AS (
    SELECT 
        s.store_id,      
        s.address_id,    
        p.amount        
    FROM public.payment p
    INNER JOIN public.staff st ON p.staff_id = st.staff_id  --connect to involved staff
    INNER JOIN public.store s ON st.store_id = s.store_id  --connect to store
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
    CONCAT(address, COALESCE(', ' || address2, '')) AS full_address,
    SUM(amount) AS revenue
FROM store_addresses
GROUP BY store_id, address, address2
ORDER BY revenue DESC;

--	Advantages: Clear logic, Each CTE is independently testable, Moderately fast execution
--	Disadvantages: Creates two intermediate result sets; most resource-intensive


-- Subquery Solution
SELECT 
    CONCAT(a.address, COALESCE(', ' || a.address2, '')) AS full_address,
       (SELECT SUM(p.amount)
        FROM public.payment p
        INNER JOIN public.staff st ON p.staff_id = st.staff_id
        WHERE st.store_id = s.store_id
            AND p.payment_date >= '2017-04-01') AS revenue
FROM public.store s
INNER JOIN public.address a ON s.address_id = a.address_id
ORDER BY revenue DESC;


--	Advantages: Less complex
-- Disadvantages: Inefficient with large data, Does not scale well


-- JOIN Solution
SELECT 
    CONCAT(a.address, COALESCE(', ' || a.address2, '')) AS full_address,
    SUM(p.amount) AS revenue
FROM public.store s
INNER JOIN public.address a ON s.address_id = a.address_id  
INNER JOIN public.staff st ON s.store_id = st.store_id    
INNER JOIN public.payment p ON st.staff_id = p.staff_id     
WHERE p.payment_date >= '2017-04-01' 
GROUP BY s.store_id, a.address, a.address2  
ORDER BY revenue DESC;


--	Advantages: Optimal performance
-- Disadvantages: Aggregation can be complex


-- TASK 3:Find the 5 actors who appeared in the most movies released after 2015
-- Task asks to identify most active actors in recent productions (post-2015), likely for contract negotiations or marketing decisions


-- CTE Solution
WITH 
actor_films AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        f.film_id
    FROM public.actor a
    INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id --connect to film through film_Actor
    INNER JOIN public.film f ON fa.film_id = f.film_id
    WHERE f.release_year > 2015 ),
actor_counts AS (
    SELECT 
        first_name,
        last_name,
        COUNT(film_id) AS number_of_movies 
    FROM actor_films
    GROUP BY actor_id, first_name, last_name )

SELECT 
    first_name,
    last_name,
    number_of_movies
FROM actor_counts
ORDER BY number_of_movies DESC  
LIMIT 5;  

--	Advantages: Clear logic and easy to manage
--  Disadvantages: Too resource usage heavy



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
    SELECT *
    FROM public.film_actor fa
    INNER JOIN public.film f ON fa.film_id = f.film_id
    WHERE fa.actor_id = a.actor_id
        AND f.release_year > 2015)
ORDER BY number_of_movies DESC
LIMIT 5;


--	Advantages: Less resource usage heavy
-- 	Disadvantages: Highly inefficient and query runs for every actor, Slower


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


-- 	Advantages: Fast execution, Optimal,
-- 	Disadvantages: Can be hard to manage


-- TASK 4: Count Drama, Travel, and Documentary films for each year
-- Task asks to analyze genre distribution across years to identify content acquisition trends or catalog gaps for specific popular categories


-- CTE Solution
WITH 
genre_films AS (
    SELECT 
        f.release_year,
        c.name AS category_name 
    FROM public.film f
    INNER JOIN public.film_category fc ON f.film_id = fc.film_id
    INNER JOIN public.category c ON fc.category_id = c.category_id
    WHERE c.name IN ('Drama', 'Travel', 'Documentary') ),
years AS (
    SELECT DISTINCT release_year
    FROM public.film)

SELECT 
    y.release_year,
    COALESCE(SUM(
        COALESCE((gf.category_name = 'Drama')::INT, 0)), 0) AS number_of_drama_movies,
    COALESCE(SUM(
        COALESCE((gf.category_name = 'Travel')::INT, 0)), 0) AS number_of_travel_movies,
    COALESCE(SUM(
        COALESCE((gf.category_name = 'Documentary')::INT, 0)), 0) AS number_of_documentary_movies
FROM years y
LEFT JOIN genre_films gf ON y.release_year = gf.release_year
GROUP BY y.release_year 
ORDER BY y.release_year DESC;

-- Advantages: Clear logic, Moderately fast execution
-- Disadvantages: Complex 


-- Subquery Solution
SELECT 
    f.release_year,
    (SELECT COUNT(*)
     FROM public.film f2
     INNER JOIN public.film_category fc2 ON f2.film_id = fc2.film_id
     INNER JOIN public.category c2 ON fc2.category_id = c2.category_id
     WHERE c2.name = 'Drama'
            AND f2.release_year = f.release_year  ) AS number_of_drama_movies,
    (SELECT COUNT(*)
     FROM public.film f3
     INNER JOIN public.film_category fc3 ON f3.film_id = fc3.film_id
     INNER JOIN public.category c3 ON fc3.category_id = c3.category_id
     WHERE c3.name = 'Travel'
            AND f3.release_year = f.release_year) AS number_of_travel_movies,
    (SELECT COUNT(*)
     FROM public.film f4
     INNER JOIN public.film_category fc4 ON f4.film_id = fc4.film_id
     INNER JOIN public.category c4 ON fc4.category_id = c4.category_id
     WHERE c4.name = 'Documentary'
            AND f4.release_year = f.release_year) AS number_of_documentary_movies
FROM (SELECT DISTINCT release_year FROM public.film) f 
ORDER BY f.release_year DESC;


-- 	Advantages: Clear logic
-- Disadvantages: Slow performance, Hard scaling

-- JOIN Solution
SELECT 
    f.release_year,
    COALESCE(SUM(COALESCE((c.name = 'Drama')::INT, 0)), 0) AS number_of_drama_movies,
    COALESCE(SUM(COALESCE((c.name = 'Travel')::INT, 0)), 0) AS number_of_travel_movies,
    COALESCE(SUM(COALESCE((c.name = 'Documentary')::INT, 0)), 0) AS number_of_documentary_movies
FROM public.film f
LEFT JOIN public.film_category fc ON f.film_id = fc.film_id
LEFT JOIN public.category c ON fc.category_id = c.category_id 
    AND c.name IN ('Drama', 'Travel', 'Documentary')
GROUP BY f.release_year
ORDER BY f.release_year DESC;

-- 	Advantages: Efficient, Fast
-- Disadvantages: Unclear logic, Hard to manage


-- TASK 5: Find which 3 employees made the most money in 2017
-- Task asks to identify top performers for bonuses/recognition, using their most recent store assignment in 2017


-- CTE Solution
WITH 
employee_payments AS (
    SELECT 
        st.staff_id,
        st.first_name,
        st.last_name,
        p.amount,
        p.payment_date,
        st.store_id 
    FROM public.payment p
    INNER JOIN public.staff st ON p.staff_id = st.staff_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017),
last_store_per_employee AS (
    SELECT 
        ep.staff_id,
        ep.store_id
    FROM employee_payments ep
    WHERE ep.payment_date = (
        SELECT MAX(ep2.payment_date)
        FROM employee_payments ep2
        WHERE ep2.staff_id = ep.staff_id)),
employee_revenue AS (
    SELECT 
        ep.staff_id,
        ep.first_name,
        ep.last_name,
        ls.store_id,
        SUM(ep.amount) AS total_revenue  
    FROM employee_payments ep
    INNER JOIN last_store_per_employee ls ON ep.staff_id = ls.staff_id
    GROUP BY ep.staff_id, ep.first_name, ep.last_name, ls.store_id)

SELECT 
    first_name,
    last_name,
    store_id,
    total_revenue
FROM employee_revenue
ORDER BY total_revenue DESC 
LIMIT 3;   --this ran for 10 mins i dont know if thats okay

-- 	Advantages: Clear logic flow
-- 	Disadvantages: Very slow 


-- Subquery Solution
SELECT 
    st.first_name,
    st.last_name,
    (SELECT st2.store_id
        FROM public.payment p2
        INNER JOIN public.staff st2 ON p2.staff_id = st2.staff_id
        WHERE p2.staff_id = st.staff_id
            AND EXTRACT(YEAR FROM p2.payment_date) = 2017
        ORDER BY p2.payment_date DESC 
        LIMIT 1 ) AS store_id,
    SUM(p.amount) AS total_revenue
FROM public.staff st
INNER JOIN public.payment p ON st.staff_id = p.staff_id
WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
GROUP BY st.staff_id, st.first_name, st.last_name
ORDER BY total_revenue DESC
LIMIT 3;

-- 	Advantages: Concise, Fast
-- 	Disadvantages: Inefficient, query runs for each row

-- JOIN Solution
SELECT 
    st.first_name,
    st.last_name,
    last_store.store_id, 
    SUM(p.amount) AS total_revenue
FROM public.staff st
INNER JOIN public.payment p ON st.staff_id = p.staff_id
INNER JOIN (SELECT 
        p_inner.staff_id,
        st_inner.store_id,
        p_inner.payment_date
    FROM public.payment p_inner
    INNER JOIN public.staff st_inner ON p_inner.staff_id = st_inner.staff_id
    WHERE EXTRACT(YEAR FROM p_inner.payment_date) = 2017
        AND p_inner.payment_date = (
            SELECT MAX(p_max.payment_date)
            FROM public.payment p_max
            WHERE p_max.staff_id = p_inner.staff_id
                AND EXTRACT(YEAR FROM p_max.payment_date) = 2017)) last_store ON st.staff_id = last_store.staff_id
WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
GROUP BY st.staff_id, st.first_name, st.last_name, last_store.store_id
ORDER BY total_revenue DESC
LIMIT 3;

-- 	Advantages: Clear logic
-- 	Disadvantages: Slow, Complex



-- TASK 6: Find the 5 most popular movies and show recommended age
-- Task asks to identify inventory to promote, with parental guidance for different customer segments based on MPAA-style ratings


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
        tf.film_id,
        tf.number_of_rentals,
        f.title,
        f.rating,
        (SELECT 'All ages' WHERE f.rating = 'G') AS age_g,
        (SELECT '7+ (Parental guidance)' WHERE f.rating = 'PG') AS age_pg,
        (SELECT '13+' WHERE f.rating = 'PG-13') AS age_pg13,
        (SELECT '17+' WHERE f.rating = 'R') AS age_r,
        (SELECT '18+' WHERE f.rating = 'NC-17') AS age_nc17
    FROM top_films tf
    INNER JOIN public.film f ON tf.film_id = f.film_id)
	
SELECT 
    title,
    number_of_rentals,
    rating,
    age_g || age_pg || age_pg13 || age_r || age_nc17 AS expected_age
FROM films_with_ages
ORDER BY number_of_rentals DESC;

-- Advantages: Clear logic
-- Disadvantages: Complex, Not scalable



-- Subquery Solution
SELECT 
    f.title,
    (SELECT COUNT(r.rental_id)
        FROM public.rental r
        INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
        WHERE i.film_id = f.film_id) AS number_of_rentals,
    f.rating,
    (SELECT 'All ages' WHERE f.rating = 'G') ||
    (SELECT '7+ (Parental guidance)' WHERE f.rating = 'PG') ||
    (SELECT '13+' WHERE f.rating = 'PG-13') ||
    (SELECT '17+' WHERE f.rating = 'R') ||
    (SELECT '18+' WHERE f.rating = 'NC-17') AS expected_age
FROM public.film f
WHERE EXISTS (
    SELECT *
    FROM public.inventory i
    INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
    WHERE i.film_id = f.film_id)
ORDER BY number_of_rentals DESC
LIMIT 5;


-- Advantages: Compact; Moderately fast execution
-- Disadvantages: Can be hard to catch the logic


-- JOIN Solution
SELECT 
    f.title,
    COUNT(r.rental_id) AS number_of_rentals,
    f.rating,
    (SELECT 'All ages' WHERE f.rating = 'G') ||
    (SELECT '7+ (Parental guidance)' WHERE f.rating = 'PG') ||
    (SELECT '13+' WHERE f.rating = 'PG-13') ||
    (SELECT '17+' WHERE f.rating = 'R') ||
    (SELECT '18+' WHERE f.rating = 'NC-17') AS expected_age
FROM public.film f
INNER JOIN public.inventory i ON f.film_id = i.film_id
INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title, f.rating
ORDER BY number_of_rentals DESC
LIMIT 5;

-- Advantages: Fast, Optimal
-- Disadvantages: Can be hard to catch the logic


-- TASK 7 VERSION 1:Calculate how many years since each actor's last movie
-- Task asks to identify inactive actors for potential retirement assessment or reunion opportunities


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

-- Advantages: Clear logic, Fast execution
-- Disadvantages: Too complex


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
    SELECT *
    FROM public.film_actor fa
    WHERE fa.actor_id = a.actor_id)
ORDER BY years_since_last_film DESC, 
         a.last_name, 
         a.first_name;

-- Advantages: Compact, Moderately fast
-- Disadvantages: Not optimal - repeats same subquery twice 


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

-- 	Advantages: Optimal , fast
-- 	Disadvantages: Logic can be hard to catch

-- TASK 7 VERSION 2:Find gaps between consecutive films for each actor

-- Task asks to analyze actor career patterns - identify career breaks or regular working patterns for contract timing or comeback opportunities

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
    FROM actor_films af1)

SELECT 
    first_name,
    last_name,
    current_year,  
    next_year,   
    (next_year - current_year) AS gap_years 
FROM film_pairs
WHERE next_year IS NOT NULL 
ORDER BY last_name, 
         first_name, 
         current_year;


-- Advantages: Clear logic,
-- Disadvantages: Complex, Inefficient


-- Subquery Solution
SELECT 
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
FROM (SELECT DISTINCT
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
        AND f3.release_year > af.release_year)
ORDER BY af.last_name, 
         af.first_name, 
         af.release_year;

-- Advantages: Clear logic
-- Disadvantages: Complex


-- JOIN Solution
SELECT 
    af1.first_name,
    af1.last_name,
    af1.release_year AS current_year,
    MIN(af2.release_year) AS next_year,
    (MIN(af2.release_year) - af1.release_year) AS gap_years
FROM (SELECT DISTINCT
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
HAVING MIN(af2.release_year) IS NOT NULL
ORDER BY af1.last_name, 
         af1.first_name, 
         af1.release_year;


-- Advantages: Fast, Compact
-- Disadvatages: Logic is hard to catch