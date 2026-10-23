Last login: Fri Oct 23 13:13:32 on ttys001
/Users/danel/.zshrc:27: no such file or directory: /opt/homebrew/bin/brew
/Users/danel/.zshrc:28: no such file or directory: /opt/homebrew/bin/brew
danel@1111QD-rs ~ % docker --version && docker compose version
Docker version 29.9.2, build a82e528901
Docker Compose version 5.6.1
danel@1111QD-rs ~ % mkdir -p ~/streaming-replication && cd ~/streaming-replication
danel@1111QD-rs streaming-replication % cat > 00_init.sql <<'EOF'
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator_password';
SELECT pg_create_physical_replication_slot('replication_slot');
EOF
danel@1111QD-rs streaming-replication % cat > docker-compose.yaml <<'EOF'
name: streaming-replication

x-postgres-common: &postgres-common
  image: postgres:18.3-alpine3.23
  user: postgres
  restart: always
  healthcheck:
    test: 'pg_isready -U zuser --dbname=zdb'
    interval: 10s
    timeout: 5s
    retries: 5

services:
  postgres_primary:
    <<: *postgres-common
    ports:
      - 5432:5432
    environment:
      POSTGRES_USER: zuser
      POSTGRES_DB: zdb
      POSTGRES_PASSWORD: zpass
      POSTGRES_HOST_AUTH_METHOD: "scram-sha-256\nhost replication replicator 0.0.0.0/0 md5"
      POSTGRES_INITDB_ARGS: "--auth-host=scram-sha-256"
    command: |
      postgres
      -c wal_level=replica
      -c hot_standby=on
      -c max_wal_senders=10
      -c max_replication_slots=10
      -c hot_standby_feedback=on
    volumes:
      - ./00_init.sql:/docker-entrypoint-initdb.d/00_init.sql

  postgres_replica:
    <<: *postgres-common
    ports:
      - 5433:5432
    environment:
      PGUSER: replicator
      PGPASSWORD: replicator_password
      PGDATA: /var/lib/postgresql/18/docker
    command:
      - bash
      - -c
      - |
        if [ ! -s "$$PGDATA/PG_VERSION" ]; then
          until pg_basebackup --pgdata="$$PGDATA" -R --slot=replication_slot --host=postgres_primary --port=5432 -X stream; do
            echo 'pg_basebackup failed. Retrying in 5 seconds ...'
            sleep 5
          done
          echo 'Backup done, starting replica...'
        fi
        chmod 0700 "$$PGDATA"
        exec postgres
    depends_on:
      postgres_primary:
        condition: service_healthy
EOF
danel@1111QD-rs streaming-replication % cat > env.sh <<'EOF'
alias dcu="docker compose up -d --wait"
alias dcd="docker compose down -v"
alias dps="docker ps"
alias der="docker compose exec postgres_replica bash"
alias dep="docker compose exec postgres_primary bash"
alias dlr="docker compose logs postgres_replica"
alias dlp="docker compose logs postgres_primary"
EOF
danel@1111QD-rs streaming-replication % ls -la
source env.sh
total 24
drwxr-xr-x    5 danel  staff   160 Oct 23 03:17 .
drwxr-xr-x+ 146 danel  staff  4672 Oct 23 13:15 ..
-rw-r--r--    1 danel  staff   146 Oct 23 13:15 00_init.sql
-rw-r--r--    1 danel  staff  1536 Oct 23 13:15 docker-compose.yaml
-rw-r--r--    1 danel  staff   303 Oct 23 13:15 env.sh
danel@1111QD-rs streaming-replication % dcu
failed to connect to the docker API at unix:///Users/danel/.colima/default/docker.sock; check if the path is correct and if the daemon is running: dial unix /Users/danel/.colima/default/docker.sock: connect: no such file or directory
danel@1111QD-rs streaming-replication % dps
failed to connect to the docker API at unix:///Users/danel/.colima/default/docker.sock; check if the path is correct and if the daemon is running: dial unix /Users/danel/.colima/default/docker.sock: connect: no such file or directory
danel@1111QD-rs streaming-replication % dcu
[+] up 3/3
 ✔ Network streaming-replication_default              Created                  0.1s
 ✔ Container streaming-replication-postgres_primary-1 Healthy                 12.3s
 ✔ Container streaming-replication-postgres_replica-1 Healthy                 22.1s
danel@1111QD-rs streaming-replication % dps
CONTAINER ID   IMAGE                      COMMAND                  CREATED          STATUS                    PORTS                                         NAMES
ff48a47b7fdd   postgres:18.3-alpine3.23   "docker-entrypoint.s…"   29 seconds ago   Up 18 seconds (healthy)   0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp   streaming-replication-postgres_replica-1
f1253648b62a   postgres:18.3-alpine3.23   "docker-entrypoint.s…"   30 seconds ago   Up 29 seconds (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp   streaming-replication-postgres_primary-1
danel@1111QD-rs streaming-replication % dlr
postgres_replica-1  | Backup done, starting replica...
postgres_replica-1  | 2026-10-23 06:19:06.682 UTC [1] LOG:  starting PostgreSQL 18.3 on x86_64-pc-linux-musl, compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit
postgres_replica-1  | 2026-10-23 06:19:06.682 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
postgres_replica-1  | 2026-10-23 06:19:06.682 UTC [1] LOG:  listening on IPv6 address "::", port 5432
postgres_replica-1  | 2026-10-23 06:19:06.693 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
postgres_replica-1  | 2026-10-23 06:19:06.710 UTC [15] LOG:  database system was interrupted; last known up at 2026-10-23 06:19:05 UTC
postgres_replica-1  | 2026-10-23 06:19:06.947 UTC [15] LOG:  starting backup recovery with redo LSN 0/2000028, checkpoint LSN 0/2000080, on timeline ID 1
postgres_replica-1  | 2026-10-23 06:19:06.947 UTC [15] LOG:  entering standby mode
postgres_replica-1  | 2026-10-23 06:19:06.958 UTC [15] LOG:  redo starts at 0/2000028
postgres_replica-1  | 2026-10-23 06:19:06.960 UTC [15] LOG:  completed backup recovery with redo LSN 0/2000028 and end LSN 0/2000120
postgres_replica-1  | 2026-10-23 06:19:06.960 UTC [15] LOG:  consistent recovery state reached at 0/2000120
postgres_replica-1  | 2026-10-23 06:19:06.961 UTC [1] LOG:  database system is ready to accept read-only connections
postgres_replica-1  | 2026-10-23 06:19:06.991 UTC [16] LOG:  started streaming WAL from primary at 0/3000000 on timeline 1
danel@1111QD-rs streaming-replication % docker compose exec postgres_primary psql -U zuser -d zdb -x -c "SELECT * FROM pg_stat_replication;"
-[ RECORD 1 ]----+------------------------------
pid              | 67
usesysid         | 16385
usename          | replicator
application_name | walreceiver
client_addr      | 172.19.0.3
client_hostname  | 
client_port      | 42166
backend_start    | 2026-10-23 06:19:06.971368+00
backend_xmin     | 
state            | streaming
sent_lsn         | 0/3000060
write_lsn        | 0/3000060
flush_lsn        | 0/3000060
replay_lsn       | 0/3000060
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async
reply_time       | 2026-10-23 06:19:43.749438+00

danel@1111QD-rs streaming-replication % docker compose exec postgres_primary psql -U zuser -d zdb -x -c "SELECT * FROM pg_replication_slots;"
-[ RECORD 1 ]-------+-----------------
slot_name           | replication_slot
plugin              | 
slot_type           | physical
datoid              | 
database            | 
temporary           | f
active              | t
active_pid          | 67
xmin                | 
catalog_xmin        | 
restart_lsn         | 0/301E030
confirmed_flush_lsn | 
wal_status          | reserved
safe_wal_size       | 
two_phase           | f
two_phase_at        | 
inactive_since      | 
conflicting         | 
invalidation_reason | 
failover            | f
synced              | f

danel@1111QD-rs streaming-replication % docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT pg_is_in_recovery();"
 pg_is_in_recovery 
-------------------
 t
(1 row)

danel@1111QD-rs streaming-replication % docker compose exec postgres_primary psql -U zuser -d zdb -c "\dt"
Did not find any tables.
danel@1111QD-rs streaming-replication % docker compose exec postgres_replica psql -U zuser -d zdb -c "\dt"
Did not find any tables.
danel@1111QD-rs streaming-replication % docker compose exec postgres_primary psql -U zuser -d zdb -c "CREATE TABLE testrep (first INT, second VARCHAR(15));"
docker compose exec postgres_primary psql -U zuser -d zdb -c "INSERT INTO testrep (first, second) VALUES (21, 'Test pertama');"
docker compose exec postgres_primary psql -U zuser -d zdb -c "INSERT INTO testrep (first, second) VALUES (23, 'Test ke dua');"
docker compose exec postgres_primary psql -U zuser -d zdb -c "SELECT * FROM testrep;"
CREATE TABLE
INSERT 0 1
INSERT 0 1
 first |    second    
-------+--------------
    21 | Test pertama
    23 | Test ke dua
(2 rows)

danel@1111QD-rs streaming-replication % sleep 2
docker compose exec postgres_replica psql -U zuser -d zdb -c "\dt"
docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT * FROM testrep;"
          List of tables
 Schema |  Name   | Type  | Owner 
--------+---------+-------+-------
 public | testrep | table | zuser
(1 row)

 first |    second    
-------+--------------
    21 | Test pertama
    23 | Test ke dua
(2 rows)

danel@1111QD-rs streaming-replication % docker compose exec postgres_replica psql -U zuser -d zdb -c "INSERT INTO testrep VALUES (99, 'gagal');"
ERROR:  cannot execute INSERT in a read-only transaction
danel@1111QD-rs streaming-replication % dep
f1253648b62a:/$ docker compose stop postgres_primary
bash: docker: command not found
f1253648b62a:/$ docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT pg_is_in_recovery();"
bash: docker: command not found
f1253648b62a:/$ docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT pg_promote();"
sleep 3
bash: docker: command not found
f1253648b62a:/$ docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT pg_is_in_recovery();"
bash: docker: command not found
f1253648b62a:/$ docker compose exec postgres_replica psql -U zuser -d zdb -c "INSERT INTO testrep VALUES (25, 'Setelah promote');"
docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT * FROM testrep;"
bash: docker: command not found
bash: docker: command not found
f1253648b62a:/$ exit
exit
danel@1111QD-rs streaming-replication % docker compose stop postgres_primary

[+] stop 1/1
 ✔ Container streaming-replication-postgres_primary-1 Stopped                  0.3s
danel@1111QD-rs streaming-replication % docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT pg_is_in_recovery();"

 pg_is_in_recovery 
-------------------
 t
(1 row)

danel@1111QD-rs streaming-replication % docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT pg_promote();"

 pg_promote 
------------
 t
(1 row)

danel@1111QD-rs streaming-replication % docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT pg_is_in_recovery();"

 pg_is_in_recovery 
-------------------
 f
(1 row)

danel@1111QD-rs streaming-replication % docker compose exec postgres_replica psql -U zuser -d zdb -c "INSERT INTO testrep VALUES (25, 'Setelah promote');"

INSERT 0 1
danel@1111QD-rs streaming-replication % dcd
[+] down 3/3
 ✔ Container streaming-replication-postgres_replica-1 Removed                  0.3s
 ✔ Container streaming-replication-postgres_primary-1 Removed                  0.1s
 ✔ Network streaming-replication_default              Removed                  0.1s
danel@1111QD-rs streaming-replication % dps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
danel@1111QD-rs streaming-replication % 
