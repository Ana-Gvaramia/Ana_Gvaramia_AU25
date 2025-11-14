INSERT INTO public.film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features, last_update)
SELECT 
    'Mean Girls', 
    'High school movie', 
    2004, 
    (SELECT language_id FROM public.language WHERE UPPER(name) = UPPER('English')), 
    1, 
    4.99, 
    97, 
    19.99, 
    'PG-13', 
    ARRAY['Funny'], 
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 
    FROM public.film 
    WHERE UPPER(title) = UPPER('Mean Girls'))
RETURNING film_id, title;

INSERT INTO public.film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features, last_update)
SELECT 
    'Planet of the Apes', 
    'Old sci-fi with apes', 
    1968, 
    (SELECT language_id FROM public.language WHERE UPPER(name) = UPPER('English')), 
    2, 
    9.99, 
    112, 
    24.99, 
    'G', 
    ARRAY['Trailers'], 
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 
    FROM public.film 
    WHERE UPPER(title) = UPPER('Planet of the Apes'))
RETURNING film_id, title;

INSERT INTO public.film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features, last_update)
SELECT 
    'The Handmaid''s Tale', 
    'Dark future story', 
    1990, 
    (SELECT language_id FROM public.language WHERE UPPER(name) = UPPER('English')), 
    3, 
    19.99, 
    108, 
    21.99, 
    'R', 
    ARRAY['Deleted Scenes'], 
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 
    FROM public.film 
    WHERE UPPER(title) = UPPER('The Handmaid''s Tale'))
RETURNING film_id, title;

COMMIT;



INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 
    'Lindsay', 
    'Lohan', 
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 
    FROM public.actor 
    WHERE UPPER(first_name) = UPPER('Lindsay') 
    AND UPPER(last_name) = UPPER('Lohan'))
RETURNING actor_id, first_name, last_name;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 
    'Rachel', 
    'McAdams', 
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 
    FROM public.actor 
    WHERE UPPER(first_name) = UPPER('Rachel') 
    AND UPPER(last_name) = UPPER('McAdams'))
RETURNING actor_id, first_name, last_name;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 
    'Charlton', 
    'Heston', 
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 
    FROM public.actor 
    WHERE UPPER(first_name) = UPPER('Charlton') 
    AND UPPER(last_name) = UPPER('Heston'))
RETURNING actor_id, first_name, last_name;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 
    'Roddy', 
    'McDowall', 
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 
    FROM public.actor 
    WHERE UPPER(first_name) = UPPER('Roddy') 
    AND UPPER(last_name) = UPPER('McDowall'))
RETURNING actor_id, first_name, last_name;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 
    'Natasha', 
    'Richardson', 
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 
    FROM public.actor 
    WHERE UPPER(first_name) = UPPER('Natasha') 
    AND UPPER(last_name) = UPPER('Richardson'))
RETURNING actor_id, first_name, last_name;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 
    'Faye', 
    'Dunaway', 
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 
    FROM public.actor 
    WHERE UPPER(first_name) = UPPER('Faye') 
    AND UPPER(last_name) = UPPER('Dunaway'))
RETURNING actor_id, first_name, last_name;

COMMIT;



INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT 
    a.actor_id, 
    f.film_id, 
    CURRENT_DATE
FROM public.actor a
INNER JOIN public.film f ON UPPER(f.title) = UPPER('Mean Girls')
WHERE UPPER(a.first_name) = UPPER('Lindsay') 
AND UPPER(a.last_name) = UPPER('Lohan')
AND NOT EXISTS (
    SELECT 1 
    FROM public.film_actor fa 
    WHERE fa.actor_id = a.actor_id 
    AND fa.film_id = f.film_id)
RETURNING actor_id, film_id;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT 
    a.actor_id, 
    f.film_id, 
    CURRENT_DATE
FROM public.actor a
INNER JOIN public.film f ON UPPER(f.title) = UPPER('Mean Girls')
WHERE UPPER(a.first_name) = UPPER('Rachel') 
AND UPPER(a.last_name) = UPPER('McAdams')
AND NOT EXISTS (
    SELECT 1 
    FROM public.film_actor fa 
    WHERE fa.actor_id = a.actor_id 
    AND fa.film_id = f.film_id)
RETURNING actor_id, film_id;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT 
    a.actor_id, 
    f.film_id, 
    CURRENT_DATE
FROM public.actor a
INNER JOIN public.film f ON UPPER(f.title) = UPPER('Planet of the Apes')
WHERE UPPER(a.first_name) = UPPER('Charlton') 
AND UPPER(a.last_name) = UPPER('Heston')
AND NOT EXISTS (
    SELECT 1 
    FROM public.film_actor fa 
    WHERE fa.actor_id = a.actor_id 
    AND fa.film_id = f.film_id)
RETURNING actor_id, film_id;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT 
    a.actor_id, 
    f.film_id, 
    CURRENT_DATE
FROM public.actor a
INNER JOIN public.film f ON UPPER(f.title) = UPPER('Planet of the Apes')
WHERE UPPER(a.first_name) = UPPER('Roddy') 
AND UPPER(a.last_name) = UPPER('McDowall')
AND NOT EXISTS (
    SELECT 1 
    FROM public.film_actor fa 
    WHERE fa.actor_id = a.actor_id 
    AND fa.film_id = f.film_id)
RETURNING actor_id, film_id;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT 
    a.actor_id, 
    f.film_id, 
    CURRENT_DATE
FROM public.actor a
INNER JOIN public.film f ON UPPER(f.title) = UPPER('The Handmaid''s Tale')
WHERE UPPER(a.first_name) = UPPER('Natasha') 
AND UPPER(a.last_name) = UPPER('Richardson')
AND NOT EXISTS (
    SELECT 1 
    FROM public.film_actor fa 
    WHERE fa.actor_id = a.actor_id 
    AND fa.film_id = f.film_id)
RETURNING actor_id, film_id;

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT 
    a.actor_id, 
    f.film_id, 
    CURRENT_DATE
FROM public.actor a
INNER JOIN public.film f ON UPPER(f.title) = UPPER('The Handmaid''s Tale')
WHERE UPPER(a.first_name) = UPPER('Faye') 
AND UPPER(a.last_name) = UPPER('Dunaway')
AND NOT EXISTS (
    SELECT 1 
    FROM public.film_actor fa 
    WHERE fa.actor_id = a.actor_id 
    AND fa.film_id = f.film_id)
RETURNING actor_id, film_id;

COMMIT;


INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT 
    f.film_id,
    1,
    CURRENT_DATE
FROM public.film f
INNER JOIN (SELECT 1 AS copy_num UNION ALL SELECT 2) copies ON 1=1
WHERE UPPER(f.title) IN (UPPER('Mean Girls'), UPPER('Planet of the Apes'), UPPER('The Handmaid''s Tale'))
AND (
    SELECT COUNT(*) 
    FROM public.inventory i 
    WHERE i.film_id = f.film_id 
    AND i.store_id = 1
) < 2
RETURNING inventory_id, film_id, store_id;

COMMIT;


SELECT 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    COUNT(DISTINCT r.rental_id) AS rental_count,
    COUNT(DISTINCT p.payment_id) AS payment_count
FROM public.customer c
LEFT JOIN public.rental r ON c.customer_id = r.customer_id
LEFT JOIN public.payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT r.rental_id) >= 43 
AND COUNT(DISTINCT p.payment_id) >= 43
ORDER BY rental_count DESC
LIMIT 1;


UPDATE public.customer
SET 
    first_name = 'Ana',
    last_name = 'Gvaramia',
    email = 'anagvaramia@gmail.com',
    address_id = (
        SELECT address_id 
        FROM public.address 
        WHERE UPPER(city_id::TEXT) IS NOT NULL 
        LIMIT 1),
    store_id = 1,
    active = 1,
    create_date = CURRENT_DATE,
    last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT c.customer_id
    FROM public.customer c
    LEFT JOIN public.rental r ON c.customer_id = r.customer_id
    LEFT JOIN public.payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43 
    AND COUNT(DISTINCT p.payment_id) >= 43
    ORDER BY COUNT(DISTINCT r.rental_id) DESC
    LIMIT 1)
RETURNING customer_id, first_name, last_name, email;

COMMIT;



SELECT 
    p.payment_id, 
    p.rental_id, 
    p.amount
FROM public.payment p
WHERE p.customer_id = (
    SELECT customer_id 
    FROM public.customer 
    WHERE UPPER(first_name) = UPPER('Ana') 
    AND UPPER(last_name) = UPPER('Gvaramia'));

DELETE FROM public.payment
WHERE customer_id = (
    SELECT customer_id 
    FROM public.customer 
    WHERE UPPER(first_name) = UPPER('Ana') 
    AND UPPER(last_name) = UPPER('Gvaramia'))
RETURNING payment_id, rental_id, amount;

SELECT 
    r.rental_id, 
    r.inventory_id, 
    r.rental_date
FROM public.rental r
WHERE r.customer_id = (
    SELECT customer_id 
    FROM public.customer 
    WHERE UPPER(first_name) = UPPER('Ana') 
    AND UPPER(last_name) = UPPER('Gvaramia'));

DELETE FROM public.rental
WHERE customer_id = (
    SELECT customer_id 
    FROM public.customer 
    WHERE UPPER(first_name) = UPPER('Ana') 
    AND UPPER(last_name) = UPPER('Gvaramia'))
RETURNING rental_id, inventory_id, rental_date;

COMMIT;



INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT 
    '2017-06-15'::DATE,
    i.inventory_id,
    c.customer_id,
    '2017-06-22'::DATE,
    1,
    CURRENT_DATE
FROM public.customer c
INNER JOIN public.inventory i ON i.store_id = 1
INNER JOIN public.film f ON i.film_id = f.film_id
WHERE UPPER(c.first_name) = UPPER('Ana')
AND UPPER(c.last_name) = UPPER('Gvaramia')
AND UPPER(f.title) = UPPER('Mean Girls')
AND NOT EXISTS (
    SELECT 1 
    FROM public.rental r
    WHERE r.inventory_id = i.inventory_id
    AND r.customer_id = c.customer_id
    AND r.rental_date = '2017-06-15'::DATE)
LIMIT 1
RETURNING rental_id, inventory_id, customer_id;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT 
    '2017-06-15'::DATE,
    i.inventory_id,
    c.customer_id,
    '2017-06-29'::DATE,
    1,
    CURRENT_DATE
FROM public.customer c
INNER JOIN public.inventory i ON i.store_id = 1
INNER JOIN public.film f ON i.film_id = f.film_id
WHERE UPPER(c.first_name) = UPPER('Ana')
AND UPPER(c.last_name) = UPPER('Gvaramia')
AND UPPER(f.title) = UPPER('Planet of the Apes')
AND NOT EXISTS (
    SELECT 1 
    FROM public.rental r
    WHERE r.inventory_id = i.inventory_id
    AND r.customer_id = c.customer_id
    AND r.rental_date = '2017-06-15'::DATE)
LIMIT 1
RETURNING rental_id, inventory_id, customer_id;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT 
    '2017-06-15'::DATE,
    i.inventory_id,
    c.customer_id,
    '2017-07-06'::DATE,
    CURRENT_DATE
FROM public.customer c
INNER JOIN public.inventory i ON i.store_id = 1
INNER JOIN public.film f ON i.film_id = f.film_id
WHERE UPPER(c.first_name) = UPPER('Ana')
AND UPPER(c.last_name) = UPPER('Gvaramia')
AND UPPER(f.title) = UPPER('The Handmaid''s Tale')
AND NOT EXISTS (
    SELECT 1 
    FROM public.rental r
    WHERE r.inventory_id = i.inventory_id
    AND r.customer_id = c.customer_id
    AND r.rental_date = '2017-06-15'::DATE)
LIMIT 1
RETURNING rental_id, inventory_id, customer_id;

COMMIT;




INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 
    c.customer_id,
    1,
    r.rental_id,
    f.rental_rate,
    '2017-06-15'::TIMESTAMP
FROM public.customer c
INNER JOIN public.rental r ON r.customer_id = c.customer_id
INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
INNER JOIN public.film f ON i.film_id = f.film_id
WHERE UPPER(c.first_name) = UPPER('Ana')
AND UPPER(c.last_name) = UPPER('Gvaramia')
AND r.rental_date = '2017-06-15'::DATE
AND NOT EXISTS (
    SELECT 1 
    FROM public.payment p 
    WHERE p.rental_id = r.rental_id)
RETURNING payment_id, rental_id, amount, payment_date;

COMMIT;