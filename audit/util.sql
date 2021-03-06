create or replace function per_column(
  snippet varchar, delimeter varchar, search_schema text, search_table varchar, skip varchar[]
) returns varchar
language plpgsql AS $$
declare
  result varchar;
  cols record;
begin
  result := '';
  
  for cols in
    select * 
    from information_schema.columns c
    where c.table_name = search_table
      and c.table_schema = search_schema
      and not (c.column_name = any (skip))
    order by ordinal_position
  loop     
    result := result || 
      replace(snippet, '${column}', cols.column_name) || delimeter;          
  end loop;

  result := 
    substring(
      result 
      from 0 
      for length(result) - length(delimeter) + 1);
  
  return result;
end;
$$;


create or replace function create_ne() returns void
language plpgsql AS $$
declare
  type_list text[];
  t text;
begin
  type_list := 
	  array['char', 'abstime', 'anyarray', 'bigint', 'boolean', 'bytea',
	        'character', 'character varying', 'date', 'double precision', 'inet',
				  'integer', 'interval', 'name', 'real', 
					'regproc', 'smallint', 'text', 'timestamp with time zone',
          'timestamp without time zone', 'tstzrange', 'xid'];

  for t in select unnest(type_list)
  loop
    execute format('create or replace function ne(a %s, b %s) returns boolean
language plpgsql AS $ne$
begin
  return (a is null and b is not null) or (a is not null and b is null) or (a <> b);
end;
$ne$;', t, t);
  end loop;
end;
$$;

select create_ne();

create or replace function get_audit_columns() returns varchar[]
language plpgsql AS $$
begin
  return array['audit_action', 'audit_date', 'audit_request', 'audit_txid', 'audit_user', 'id'];
end;
$$;


