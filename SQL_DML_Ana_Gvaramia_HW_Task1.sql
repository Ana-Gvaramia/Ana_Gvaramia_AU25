-- 1. Add my 3 favorite movies
-- solved it this way to ensure there are no duplicates

INSERT INTO public.film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features, last_update)
SELECT 'Mean Girls', 
       'High school movie', 
       2004, 1, 1, 4.99, 97, 19.99, 'PG-13', 
       ARRAY['Funny'], CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM public.film WHERE title = 'Mean Girls')
RETURNING film_id, title;
commit;

INSERT INTO public.film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features, last_update)
SELECT 'Planet of the Apes', 
       'Old sci-fi with apes', 
       1968, 1, 2, 9.99, 112, 24.99, 'G', 
       ARRAY['Trailers'], CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM public.film WHERE title = 'Planet of the Apes')
RETURNING film_id, title;
COMMIT;

INSERT INTO public.film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features, last_update)
SELECT 'The Handmaid''s Tale', 
       'Dark future story', 
       1990, 1, 3, 19.99, 108, 21.99, 'R', 
       ARRAY['Deleted Scenes'], CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM public.film WHERE title = 'The Handmaid''s Tale')
RETURNING film_id, title;
COMMIT;


-- 2. Add real actors 
-- solved it this way to ensure there are no duplicates

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Lindsay', 'Lohan', CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE first_name = 'Lindsay' AND last_name = 'Lohan')
RETURNING actor_id, first_name, last_name;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Charlton', 'Heston', CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE first_name = 'Charlton' AND last_name = 'Heston')
RETURNING actor_id, first_name, last_name;

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT 'Natasha', 'Richardson', CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM public.actor WHERE first_name = 'Natasha' AND last_name = 'Richardson')
RETURNING actor_id, first_name, last_name;

COMMIT;

-- 3. Add 2 copies of each movie to Store 1
-- i solved this way to see more clearly the logic, if there are fewer than 2 copies, i add more

INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT 
    (SELECT film_id FROM public.film WHERE title = 'Mean Girls'), 1, CURRENT_TIMESTAMP
WHERE (SELECT COUNT(*) FROM public.inventory i 
       JOIN public.film f ON i.film_id = f.film_id 
       WHERE f.title = 'Mean Girls' AND i.store_id = 1) < 2
RETURNING inventory_id, film_id;

INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT 
    (SELECT film_id FROM public.film WHERE title = 'Mean Girls'), 1, CURRENT_TIMESTAMP
WHERE (SELECT COUNT(*) FROM public.inventory i 
       JOIN public.film f ON i.film_id = f.film_id 
       WHERE f.title = 'Mean Girls' AND i.store_id = 1) < 2
RETURNING inventory_id, film_id;

INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT 
    (SELECT film_id FROM public.film WHERE title = 'Planet of the Apes'), 1, CURRENT_TIMESTAMP
WHERE (SELECT COUNT(*) FROM public.inventory i 
       JOIN public.film f ON i.film_id = f.film_id 
       WHERE f.title = 'Planet of the Apes' AND i.store_id = 1) < 2
RETURNING inventory_id, film_id;

INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT 
    (SELECT film_id FROM public.film WHERE title = 'Planet of the Apes'), 1, CURRENT_TIMESTAMP
WHERE (SELECT COUNT(*) FROM public.inventory i 
       JOIN public.film f ON i.film_id = f.film_id 
       WHERE f.title = 'Planet of the Apes' AND i.store_id = 1) < 2;
RETURNING inventory_id, film_id;

INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT 
    (SELECT film_id FROM public.film WHERE title = 'The Handmaid''s Tale'), 1, CURRENT_TIMESTAMP
WHERE (SELECT COUNT(*) FROM public.inventory i 
       JOIN public.film f ON i.film_id = f.film_id 
       WHERE f.title = 'The Handmaid''s Tale' AND i.store_id = 1) < 2
RETURNING inventory_id, film_id;

INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT 
    (SELECT film_id FROM public.film WHERE title = 'The Handmaid''s Tale'), 1, CURRENT_TIMESTAMP
WHERE (SELECT COUNT(*) FROM public.inventory i 
       JOIN public.film f ON i.film_id = f.film_id 
       WHERE f.title = 'The Handmaid''s Tale' AND i.store_id = 1) < 2
RETURNING inventory_id, film_id;

COMMIT;

-- 4. Change customer info
-- i dont have particular explanation, its just simple and clear way to solve this

UPDATE public.customer
SET 
    first_name = 'Ana',
    last_name = 'Gvaramia',
    email = 'anagvaramia@gmail.com',
    address_id = 1,
    store_id = 1,
    active = 1,
    create_date = CURRENT_DATE,
    last_update = CURRENT_TIMESTAMP
WHERE customer_id = 1
RETURNING customer_id, first_name, last_name, email;
COMMIT;


-- 5. Delete my old rentals and payments
-- i chose this because i needed to delete particular data and rows

DELETE FROM public.payment WHERE customer_id = 1
RETURNING rental_id;
DELETE FROM public.rental WHERE customer_id = 1
RETURNING rental_id;
COMMIT;


-- 6. Rent my 3 movies
-- i used this so that renting is not duplicated

INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT '2017-06-15', 
       (SELECT MIN(inventory_id) FROM public.inventory i 
        JOIN public.film f ON i.film_id = f.film_id 
        WHERE f.title = 'Mean Girls' AND i.store_id = 1),
       1, '2017-06-22', 1, CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1 FROM public.rental 
    WHERE inventory_id = (SELECT MIN(inventory_id) FROM public.inventory i 
                          JOIN public.film f ON i.film_id = f.film_id 
                          WHERE f.title = 'Mean Girls' AND i.store_id = 1)
    AND rental_date = '2017-06-15')
RETURNING rental_id, inventory_id;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT '2017-06-15', 
       (SELECT MIN(inventory_id) FROM public.inventory i 
        JOIN public.film f ON i.film_id = f.film_id 
        WHERE f.title = 'Planet of the Apes' AND i.store_id = 1),
       1, '2017-06-29', 1, CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1 FROM public.rental 
    WHERE inventory_id = (SELECT MIN(inventory_id) FROM public.inventory i 
                          JOIN public.film f ON i.film_id = f.film_id 
                          WHERE f.title = 'Planet of the Apes' AND i.store_id = 1)
    AND rental_date = '2017-06-15')
RETURNING rental_id, inventory_id;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT '2017-06-15', 
       (SELECT MIN(inventory_id) FROM public.inventory i 
        JOIN public.film f ON i.film_id = f.film_id 
        WHERE f.title = 'The Handmaid''s Tale' AND i.store_id = 1),
       1, '2017-07-06', 1, CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1 FROM public.rental 
    WHERE inventory_id = (SELECT MIN(inventory_id) FROM public.inventory i 
                          JOIN public.film f ON i.film_id = f.film_id 
                          WHERE f.title = 'The Handmaid''s Tale' AND i.store_id = 1)
    AND rental_date = '2017-06-15')
RETURNING rental_id, inventory_id;


INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 1, 1, r.rental_id, f.rental_rate, '2017-06-15'
FROM public.rental r
JOIN public.inventory i ON r.inventory_id = i.inventory_id
JOIN public.film f ON i.film_id = f.film_id
WHERE r.customer_id = 1 AND r.rental_date = '2017-06-15'
AND NOT EXISTS (SELECT 1 FROM public.payment WHERE rental_id = r.rental_id)
RETURNING payment_id, rental_id, amount;

COMMIT;
