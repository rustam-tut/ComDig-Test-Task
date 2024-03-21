CREATE OR REPLACE FUNCTION primary_key_columns(tbl name)
	RETURNS table (
		pk_col_name name
	)AS
$$
	BEGIN
		RETURN QUERY
			SELECT a.attname
			  FROM   pg_index i
			  JOIN   pg_attribute a ON a.attrelid = i.indrelid
					AND a.attnum = ANY(i.indkey)
			 WHERE  i.indrelid = $1 ::regclass
					AND    i.indisprimary;
	END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION exists_column(tbl name, col name)
	RETURNS boolean AS
$$
	BEGIN
	RETURN
	EXISTS(SELECT column_name 
		 FROM information_schema.columns 
		WHERE table_name = tbl AND column_name = col
		   		AND data_type = 'character varying');
 	END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION is_valid_int4_value(val character varying)
	RETURNS boolean AS
	'SELECT ($1 ~ ''^(-)?[0-9]{1,9}$'') OR ($1 ~ ''^[0-9]{10}$'' AND $1 <= ''2147483647'')
										 OR ($1 ~ ''^(-)?[0-9]{10}$'' AND val <= ''-2147483648'')
	AS RESULT' LANGUAGE sql;
	
	
CREATE OR REPLACE PROCEDURE alter_columns_datatype_by_column_name(col name)
AS $$
	DECLARE
		tbl name;
	BEGIN
		FOR tbl IN
			SELECT table_name FROM information_schema.tables
			 WHERE table_type = 'BASE TABLE' AND table_schema = 'public'
		LOOP
			IF exists_column(tbl, col) THEN
				BEGIN
					IF col IN (SELECT primary_key_columns(tbl)) THEN
						BEGIN
							EXECUTE
							format('DELETE FROM %s 
								 WHERE NOT is_valid_int4_value(%s)', tbl, col);
						END;
					ELSE
						BEGIN
							EXECUTE 
							format('UPDATE %s SET %s = -1
								 WHERE NOT is_valid_int4_value(%s) 
								   		OR %s IS NULL', tbl, col, col, col);
							EXECUTE
							format('ALTER TABLE %s 
								ALTER COLUMN %s SET NOT NULL', tbl, col);
						END;
					END IF;
				END;
				EXECUTE
				format('ALTER TABLE %s
    				    	ALTER COLUMN %s TYPE int4 USING (%s::numeric::int4);', 
					tbl, col, col, col);
			END IF;
		END LOOP;
	END
$$ LANGUAGE plpgsql;

--//-------------------------------------------------------------------------

--type column name in procedure arg

CALL alter_columns_datatype_by_column_name('row_num');



