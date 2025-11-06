CREATE TABLE table_to_delete AS
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)


SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';

--results:
-- total_bytes - 602505216
-- index_bytes - 0
-- toast_bytes - 8192
-- table_bytes - 602497024
-- total - 575 MB
-- index - o bytes
-- toast - 8192 bytes
-- table - 575 MB


DELETE FROM table_to_delete
               WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows

-- ran for 24 secs 631 msecs

-- results after:
-- total_bytes - 602611712
-- index_bytes - 0
-- toast_bytes - 8192
-- table_bytes - 602603520
-- total - 575 MB
-- index - o bytes
-- toast - 8192 bytes
-- table - 575 MB

--insights: table size did not redeuce, doesnt reclaim space, dead tuples remain, slow

VACUUM FULL VERBOSE table_to_delete;

-- ran for 11 secs 96 msecs

-- results after:
-- total_bytes - 401580032
-- index_bytes - 0
-- toast_bytes - 8192
-- table_bytes - 401571840
-- total - 383 MB
-- index - o bytes
-- toast - 8192 bytes
-- table - 383 MB

--insights: removed dead tuples, table size reduced accordingly, faster, reclaimed space

DROP TABLE IF EXISTS table_to_delete;

CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, (10^7)::int) x;


TRUNCATE table_to_delete;

--ran for 1 sec 220 msecs

-- results after:
-- total_bytes - 8192
-- index_bytes - 0
-- toast_bytes - 8192
-- table_bytes - 0
-- total - 8192 MB
-- index - o bytes
-- toast - 8192 bytes
-- table - 0 MB

--insights: reset table storage, very fast, near zero table

			   