select *
from sead_utility.table_columns
where table_name like 'tbl_%'
  and column_name not in ('date_updated')

select table_name, column_name
from sead_utility.table_columns
where table_name like 'tbl_%'
  and is_pk = 'YES'
