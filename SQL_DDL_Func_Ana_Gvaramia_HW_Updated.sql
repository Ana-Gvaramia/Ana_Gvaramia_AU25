

-- Task 1: Create a View sales_revenue_by_category_qtr
DROP VIEW IF EXISTS sales_revenue_by_category_qtr;
CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT
    c.name AS category,
    SUM(p.amount) AS total_sales_revenue
FROM
    public.payment p
    INNER JOIN public.rental r ON p.rental_id = r.rental_id
    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN public.film f ON i.film_id = f.film_id
    INNER JOIN public.film_category fc ON f.film_id = fc.film_id
    INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE
    EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM CURRENT_DATE)
    AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY
    c.name
HAVING
    SUM(p.amount) > 0
ORDER BY
    total_sales_revenue DESC;


-- Task 2: Create a query language function 'get_sales_revenue_by_category_qtr'
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(
    reference_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    category VARCHAR,
    total_sales_revenue DECIMAL) AS $$
BEGIN
    IF reference_date IS NULL THEN
        RAISE EXCEPTION 'reference_date parameter cannot be NULL';
    END IF;

    RETURN QUERY
    SELECT c.name AS category,
           SUM(p.amount)::DECIMAL AS total_sales_revenue -- Explicitly cast SUM to DECIMAL
    FROM
        public.payment p
        INNER JOIN public.rental r ON p.rental_id = r.rental_id
        INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
        INNER JOIN public.film f ON i.film_id = f.film_id
        INNER JOIN public.film_category fc ON f.film_id = fc.film_id
        INNER JOIN public.category c ON fc.category_id = c.category_id
    WHERE
        EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM reference_date)
        AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM reference_date)
    GROUP BY
        c.name
    HAVING
        SUM(p.amount) > 0
    ORDER BY
        total_sales_revenue DESC;
END;
$$ LANGUAGE sql;



-- Task 3: Create a function that takes a country name array and returns the most popular film in those countries.
CREATE OR REPLACE FUNCTION most_popular_films_by_countries(
    country_names TEXT[])
RETURNS TABLE (
    country_name TEXT,
    film TEXT,
    rating TEXT,
    language TEXT,
    length SMALLINT,
    release_year INTEGER) AS $$
BEGIN
    IF country_names IS NULL OR array_length(country_names, 1) IS NULL THEN
        RAISE EXCEPTION 'country_names parameter cannot be NULL or empty';
    END IF;

    RETURN QUERY
    WITH film_rentals_by_country AS (
        SELECT
            co.country AS country_name,
            f.film_id,
            f.title AS film,
            f.rating::TEXT AS rating,
            l.name AS language,
            f.length,
            f.release_year,
            COUNT(r.rental_id) AS rental_count
        FROM
            public.country co
            INNER JOIN public.city ci ON co.country_id = ci.country_id
            INNER JOIN public.address a ON ci.city_id = a.city_id
            INNER JOIN public.customer cu ON a.address_id = cu.address_id
            INNER JOIN public.rental r ON cu.customer_id = r.customer_id
            INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
            INNER JOIN public.film f ON i.film_id = f.film_id
            INNER JOIN public.language l ON f.language_id = l.language_id
        WHERE
            LOWER(co.country) = ANY(LOWER(country_names))
        GROUP BY
            co.country, f.film_id, f.title, f.rating, l.name, f.length, f.release_year
    ),
    max_rentals_by_country AS (
        SELECT
            country_name,
            MAX(rental_count) AS max_rental_count
        FROM
            film_rentals_by_country
        GROUP BY
            country_name)
    SELECT
        frc.country_name,
        frc.film,
        frc.rating,
        frc.language,
        frc.length,
        frc.release_year
    FROM
        film_rentals_by_country frc
        INNER JOIN max_rentals_by_country mrc
             ON frc.country_name = mrc.country_name
             AND frc.rental_count = mrc.max_rental_count
    ORDER BY
        frc.country_name,
        frc.film;

    IF NOT FOUND THEN
        RAISE NOTICE 'No rental data found for the specified countries';
    END IF;
END;
$$ LANGUAGE plpgsql;



-- Task 4: Create a function that generates a list of movies available in stock.

CREATE OR REPLACE FUNCTION films_in_stock_by_title(
    title_pattern TEXT)
RETURNS TABLE (
    row_num BIGINT,
    film_title TEXT,
    language TEXT,
    customer_name TEXT,
    rental_date TIMESTAMP) AS $$
BEGIN
    IF title_pattern IS NULL OR title_pattern = '' THEN
        RAISE EXCEPTION 'title_pattern parameter cannot be NULL or empty';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.film f WHERE LOWER(f.title) LIKE LOWER(title_pattern)) THEN
        RAISE NOTICE 'No films found matching pattern: %', title_pattern;
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.film f
        INNER JOIN public.inventory i ON f.film_id = i.film_id
        LEFT JOIN public.rental r ON i.inventory_id = r.inventory_id
            AND r.return_date IS NULL
        WHERE LOWER(f.title) LIKE LOWER(title_pattern)
        AND r.rental_id IS NULL) THEN
        RAISE NOTICE 'Films matching "%" are not currently in stock', title_pattern;
        RETURN;
    END IF;

    RETURN QUERY
    WITH film_inventory_status AS (
        SELECT
            f.title AS film_title,
            l.name AS language,
            'Available' AS customer_name,
            NULL::TIMESTAMP AS rental_date
        FROM
            public.film f
            INNER JOIN public.language l ON f.language_id = l.language_id
            INNER JOIN public.inventory i ON f.film_id = i.film_id
            LEFT JOIN public.rental r ON i.inventory_id = r.inventory_id AND r.return_date IS NULL
        WHERE
            LOWER(f.title) LIKE LOWER(title_pattern)
            AND r.rental_id IS NULL
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY fis.film_title, fis.customer_name) AS row_num, -- Generate row counter
        fis.film_title,
        fis.language,
        fis.customer_name,
        fis.rental_date
    FROM
        film_inventory_status fis
    ORDER BY
        row_num;
END;
$$ LANGUAGE plpgsql;




-- Task 5: Create a procedure language function 'new_movie' to insert a new film.
CREATE OR REPLACE FUNCTION new_movie(
    movie_title TEXT,
    release_year_param INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER,
    language_name TEXT DEFAULT 'Klingon')
RETURNS INTEGER AS $$
DECLARE
    new_film_id INTEGER;
    language_id_var INTEGER;
    current_year INTEGER;
BEGIN
    IF movie_title IS NULL OR TRIM(movie_title) = '' THEN
        RAISE EXCEPTION 'movie_title parameter cannot be NULL or empty';
    END IF;

    IF language_name IS NULL OR TRIM(language_name) = '' THEN
        RAISE EXCEPTION 'language_name parameter cannot be NULL or empty';
    END IF;

    current_year := EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER;

    IF release_year_param < 1888 OR release_year_param > current_year + 10 THEN
        RAISE EXCEPTION 'Invalid release_year: % is not between 1888 and %', release_year_param, current_year + 10;
    END IF;

    SELECT l.language_id INTO language_id_var
    FROM public.language l
    WHERE LOWER(l.name) = LOWER(language_name);

    IF language_id_var IS NULL THEN
        RAISE EXCEPTION 'Language does not exist in the language table: %', language_name;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.film
        WHERE LOWER(title) = LOWER(movie_title)
        AND release_year = release_year_param) THEN
        RAISE NOTICE 'A film with this title and release year already exists: % (%)', movie_title, release_year_param;
        RETURN 0;
    END IF;

    INSERT INTO public.film (
        title,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost,
        release_year,
        last_update)
    VALUES (
        movie_title,
        language_id_var,
        3,
        4.99,
        19.99,
        release_year_param,
        CURRENT_TIMESTAMP)
    RETURNING film_id INTO new_film_id;

    RAISE NOTICE 'Successfully created new movie: % (ID: %)', movie_title, new_film_id;

RETURN new_film_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating new movie: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;



--Task 6:

CREATE OR REPLACE FUNCTION public.rewards_report(
    min_monthly_purchases INTEGER,
    min_dollar_amount_purchased NUMERIC)
RETURNS SETOF customer
LANGUAGE plpgsql
AS $function$
DECLARE
    reference_date DATE := '2005-08-01';
    last_month_start DATE;
    last_month_end DATE;
BEGIN
    IF min_monthly_purchases <= 0 THEN
        RAISE EXCEPTION 'Minimum monthly purchases parameter must be > 0';
    END IF;
    IF min_dollar_amount_purchased <= 0.00 THEN
        RAISE EXCEPTION 'Minimum monthly dollar amount purchased parameter must be > $0.00';
    END IF;

    last_month_start := date_trunc('month', reference_date - INTERVAL '1 month')::DATE;
    last_month_end := (date_trunc('month', reference_date)::DATE - INTERVAL '1 day');

    RETURN QUERY
    SELECT c.*
    FROM customer c
    WHERE EXISTS (
        SELECT 1
        FROM payment AS p
        WHERE p.customer_id = c.customer_id
        AND p.payment_date::DATE BETWEEN last_month_start AND last_month_end
        GROUP BY p.customer_id
        HAVING SUM(p.amount) > min_dollar_amount_purchased
        AND COUNT(p.customer_id) > min_monthly_purchases
    )
    ORDER BY c.customer_id;
END
$function$;