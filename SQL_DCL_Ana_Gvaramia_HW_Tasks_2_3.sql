--Task2:
CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
GRANT SELECT ON public.customer TO rentaluser;
CREATE ROLE rental;
GRANT rental TO rentaluser;
GRANT INSERT, UPDATE ON public.rental TO rental;
REVOKE INSERT ON public.rental FROM rental;
DO $$
DECLARE
    v_customer_id INT := 1;
    v_first_name TEXT;
    v_last_name TEXT;
    v_role_name TEXT;
BEGIN
    SELECT first_name, last_name
    INTO v_first_name, v_last_name
    FROM customer
    WHERE customer_id = v_customer_id;

    v_role_name := 'client_' || LOWER(v_first_name) || '_' || LOWER(v_last_name);

    EXECUTE 'CREATE ROLE ' || v_role_name || ' WITH LOGIN PASSWORD ''customerpassword''';
    RAISE NOTICE 'Role % created for customer ID %.', v_role_name, v_customer_id;
END $$;



--Task 3:
ALTER TABLE public.rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental FORCE ROW LEVEL SECURITY; 
GRANT SELECT ON public.rental TO client_mary_smith;
CREATE POLICY rental_rls_policy ON public.rental
    FOR SELECT
    TO client_mary_smith
    USING (
        customer_id = (
            SELECT c.customer_id
            FROM public.customer c
            WHERE 'client_' || LOWER(c.first_name) || '_' || LOWER(c.last_name) = current_user));
ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment FORCE ROW LEVEL SECURITY; 
GRANT SELECT ON public.payment TO client_mary_smith;
CREATE POLICY payment_rls_policy ON public.payment
    FOR SELECT
    TO client_mary_smith
    USING (
        customer_id = (
            SELECT c.customer_id
            FROM public.customer c
            WHERE 'client_' || LOWER(c.first_name) || '_' || LOWER(c.last_name) = current_user));