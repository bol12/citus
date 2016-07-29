
ALTER SEQUENCE pg_catalog.pg_dist_shardid_seq RESTART 410000;
ALTER SEQUENCE pg_catalog.pg_dist_jobid_seq RESTART 410000;


-- ===================================================================
-- create test functions
-- ===================================================================

CREATE FUNCTION initialize_remote_temp_table(cstring, integer)
	RETURNS bool
	AS 'citus'
	LANGUAGE C STRICT;

CREATE FUNCTION count_remote_temp_table_rows(cstring, integer)
	RETURNS integer
	AS 'citus'
	LANGUAGE C STRICT;

CREATE FUNCTION get_and_purge_connection(cstring, integer)
	RETURNS bool
	AS 'citus'
	LANGUAGE C STRICT;

CREATE FUNCTION connect_and_purge_connection(cstring, integer)
	RETURNS bool
	AS 'citus'
	LANGUAGE C STRICT;

CREATE FUNCTION set_connection_status_bad(cstring, integer)
	RETURNS bool
	AS 'citus'
	LANGUAGE C STRICT;

-- ===================================================================
-- test connection hash functionality
-- ===================================================================

-- worker port number is set in pg_regress_multi.pl
\set worker_port 57638

-- reduce verbosity to squelch chatty warnings
\set VERBOSITY terse

-- connect to non-existent host
SELECT initialize_remote_temp_table('dummy-host-name', 12345);

\set VERBOSITY default

-- try to use hostname over 255 characters
SELECT initialize_remote_temp_table(repeat('a', 256)::cstring, :worker_port);

-- connect to localhost and build a temp table
SELECT initialize_remote_temp_table('localhost', :worker_port);

-- table should still be visible since session is reused
SELECT count_remote_temp_table_rows('localhost', :worker_port);

-- purge existing connection to localhost
SELECT get_and_purge_connection('localhost', :worker_port);

-- squelch WARNINGs that contain worker_port
SET client_min_messages TO ERROR;

-- should not be able to see table anymore
SELECT count_remote_temp_table_rows('localhost', :worker_port);

-- recreate once more
SELECT initialize_remote_temp_table('localhost', :worker_port);

-- set the connection status to bad
SELECT set_connection_status_bad('localhost', :worker_port);

-- should get connection failure (cached connection bad)
SELECT count_remote_temp_table_rows('localhost', :worker_port);

-- should get result failure (reconnected, so no temp table)
SELECT count_remote_temp_table_rows('localhost', :worker_port);

-- purge the connection so that we clean up the bad connection
SELECT get_and_purge_connection('localhost', :worker_port);

SET client_min_messages TO DEFAULT;

\c

-- purge existing connection to localhost
SELECT connect_and_purge_connection('localhost', :worker_port);
