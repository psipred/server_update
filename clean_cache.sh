#!/bin/sh

psql -U b_c_user -d blast_cache_db -c "SELECT MAX(id) id into idxtmp FROM blast_cache_app_cache_entry GROUP BY (md5, expiry_date);"
psql -U b_c_user -d blast_cache_db -c "DELETE FROM blast_cache_app_cache_entry tt WHERE tt.id NOT IN (select id FROM idxtmp);"
psql -U b_c_user -d blast_cache_db -c "DROP TABLE idxtmp;"
