-- Task 1
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

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'sales_revenue_by_category_qtr') THEN
        RAISE NOTICE 'View sales_revenue_by_category_qtr created successfully';
    ELSE
        RAISE EXCEPTION 'Failed to create view sales_revenue_by_category_qtr';
    END IF;
END $$;

SELECT * FROM sales_revenue_by_category_qtr;



-- Task 2
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(
    reference_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    category VARCHAR,
    total_sales_revenue NUMERIC) AS $$
BEGIN
    IF reference_date IS NULL THEN
        RAISE EXCEPTION 'reference_date parameter cannot be NULL';
    END IF;

RETURN QUERY
SELECT c.name AS category,
       SUM(p.amount) AS total_sales_revenue
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

$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname = 'get_sales_revenue_by_category_qtr'
        AND n.nspname = 'public') THEN
        RAISE NOTICE 'Function get_sales_revenue_by_category_qtr created successfully';
    ELSE
        RAISE EXCEPTION 'Failed to create function get_sales_revenue_by_category_qtr';
    END IF;
END $$;



-- Task 3
CREATE OR REPLACE FUNCTION most_popular_films_by_countries(
    country_names TEXT[])
RETURNS TABLE (
    country TEXT,
    film TEXT,
    rating TEXT,
    language TEXT,
    length INTEGER,
    release_year INTEGER) AS $$
BEGIN
    IF country_names IS NULL OR array_length(country_names, 1) IS NULL THEN
        RAISE EXCEPTION 'country_names parameter cannot be NULL or empty';
    END IF;
	
    RETURN QUERY
    WITH film_rentals_by_country AS (
        SELECT 
            co.country,
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
            co.country = ANY(country_names)
        GROUP BY 
            co.country, f.film_id, f.title, f.rating, l.name, f.length, f.release_year),
    max_rentals_by_country AS (
        SELECT 
            country,
            MAX(rental_count) AS max_rental_count
        FROM 
            film_rentals_by_country
        GROUP BY 
            country)
    SELECT 
        frc.country,
        frc.film,
        frc.rating,
        frc.language,
        frc.length,
        frc.release_year
    FROM 
        film_rentals_by_country frc
        INNER JOIN max_rentals_by_country mrc 
            ON frc.country = mrc.country 
            AND frc.rental_count = mrc.max_rental_count
    ORDER BY 
        frc.country,
        frc.film
    LIMIT (SELECT COUNT(DISTINCT country) FROM max_rentals_by_country);
	
    IF NOT FOUND THEN
        RAISE NOTICE 'No rental data found for the specified countries';
    END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname = 'most_popular_films_by_countries'
        AND n.nspname = 'public') THEN
        RAISE NOTICE 'Function most_popular_films_by_countries created successfully';
    ELSE
        RAISE EXCEPTION 'Failed to create function most_popular_films_by_countries';
    END IF;
END $$;


-- Task 4
CREATE OR REPLACE FUNCTION films_in_stock_by_title(
    title_pattern TEXT)
RETURNS TABLE (
    row_num BIGINT,
    film_title TEXT,
    language TEXT,
    customer_name TEXT,
    rental_date TIMESTAMP) AS $$
DECLARE
    result_count INTEGER;
BEGIN
    IF title_pattern IS NULL OR title_pattern = '' THEN
        RAISE EXCEPTION 'title_pattern parameter cannot be NULL or empty';
    END IF;
    
    SELECT COUNT(DISTINCT f.film_id)
    INTO result_count
    FROM public.film f
    WHERE LOWER(f.title) LIKE LOWER(title_pattern);
    
    IF result_count = 0 THEN
        RAISE NOTICE 'No films found matching pattern: %', title_pattern;
        RETURN;
    END IF;
    
    SELECT COUNT(*)
    INTO result_count
    FROM public.film f
    INNER JOIN public.inventory i ON f.film_id = i.film_id
    LEFT JOIN public.rental r ON i.inventory_id = r.inventory_id
        AND r.return_date IS NULL 
    WHERE f.title LIKE title_pattern
        AND r.rental_id IS NULL; 
    
    IF result_count = 0 THEN
        RAISE NOTICE 'Films matching "%" are not currently in stock', title_pattern;
        RETURN;
    END IF;
    
    RETURN QUERY
    WITH film_rentals AS (
        SELECT 
            f.film_id,
            f.title AS film_title,
            l.name AS language,
            COALESCE(cu.first_name || ' ' || cu.last_name, 'Available') AS customer_name,
            r.rental_date
        FROM 
            public.film f
            INNER JOIN public.language l ON f.language_id = l.language_id
            INNER JOIN public.inventory i ON f.film_id = i.film_id
            LEFT JOIN public.rental r ON i.inventory_id = r.inventory_id
            LEFT JOIN public.customer cu ON r.customer_id = cu.customer_id
        WHERE 
            LOWER(f.title) LIKE LOWER(title_pattern)
            AND i.inventory_id IN (
                SELECT inv.inventory_id
                FROM public.inventory inv
                LEFT JOIN public.rental rent ON inv.inventory_id = rent.inventory_id
                    AND rent.return_date IS NULL
                WHERE inv.film_id = f.film_id
                    AND rent.rental_id IS NULL)),
    ordered_rentals AS (
        SELECT 
            fr.film_title,
            fr.language,
            fr.customer_name,
            fr.rental_date
        FROM 
            film_rentals fr
        ORDER BY 
            fr.rental_date DESC NULLS LAST, 
            fr.film_title, 
            fr.customer_name)
    SELECT 
        (SELECT COUNT(*) 
         FROM ordered_rentals or2 
         WHERE (or2.rental_date > or1.rental_date OR (or2.rental_date IS NOT NULL AND or1.rental_date IS NULL))
            OR (or2.rental_date = or1.rental_date AND or2.film_title < or1.film_title)
            OR (or2.rental_date = or1.rental_date AND or2.film_title = or1.film_title AND or2.customer_name < or1.customer_name)) + 1 AS row_num,
        or1.film_title,
        or1.language,
        or1.customer_name,
        or1.rental_date
    FROM 
        ordered_rentals or1
    ORDER BY 
        row_num;
        
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname = 'films_in_stock_by_title'
        AND n.nspname = 'public') THEN
        RAISE NOTICE 'Function films_in_stock_by_title created successfully';
    ELSE
        RAISE EXCEPTION 'Failed to create function films_in_stock_by_title';
    END IF;
END $$;




-- Task 5
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
    
    IF release_year_param IS NULL THEN
        release_year_param := current_year;
    END IF;
    
    IF release_year_param < 1888 OR release_year_param > current_year + 10 THEN
        RAISE EXCEPTION 'Invalid release_year', 
            release_year_param, current_year + 10;
    END IF;
    
    SELECT l.language_id INTO language_id_var
    FROM public.language l
    WHERE LOWER(l.name) = LOWER(language_name);
    
    IF language_id_var IS NULL THEN
        RAISE EXCEPTION 'Language does not exist in the language table', language_name;
    END IF;
    
    IF EXISTS (
        SELECT 1 
        FROM public.film 
        WHERE LOWER(title) = LOWER(movie_title) 
        AND release_year = release_year_param) THEN
        RAISE NOTICE 'A film with this title and release year already exists', 
            movie_title, release_year_param;
    END IF;
    
    SELECT COALESCE(MAX(film_id), 0) + 1 INTO new_film_id
    FROM public.film;
    
    INSERT INTO public.film (
        film_id,
        title,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost,
        release_year,
        last_update) VALUES (
        new_film_id,
        movie_title,
        language_id_var,
        3,                      
        4.99,                   
        19.99,                  
        release_year_param,     
        CURRENT_TIMESTAMP);
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Failed to insert new movie', movie_title;
    END IF;
    
    RAISE NOTICE 'Successfully created new movie', movie_title, new_film_id;
   
RETURN new_film_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating new movie', SQLERRM;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname = 'new_movie'
        AND n.nspname = 'public') THEN
        RAISE NOTICE 'Function new_movie created successfully';
    ELSE
        RAISE EXCEPTION 'Failed to create function new_movie';
    END IF;
END $$;