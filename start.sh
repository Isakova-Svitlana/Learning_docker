#!/bin/sh
#pg_ctl start -D /var/lib/postgresql/data && tail -F /dev/null

set -e
pg_ctl start -D /var/lib/postgresql/data -l /var/lib/postgresql/log.log && cat 
exec "$@";

