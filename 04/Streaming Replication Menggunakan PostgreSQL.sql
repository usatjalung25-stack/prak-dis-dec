Last login: Fri Oct 23 13:15:09 on ttys000
/Users/danel/.zshrc:27: no such file or directory: /opt/homebrew/bin/brew
/Users/danel/.zshrc:28: no such file or directory: /opt/homebrew/bin/brew
danel@1111QD-rs ~ % colima start

INFO[0001] starting colima                              
INFO[0001] runtime: docker                              
INFO[0002] starting ...                                  context=vm
INFO[0031] provisioning ...                              context=docker
INFO[0037] starting ...                                  context=docker
INFO[0040] done                                         
danel@1111QD-rs ~ % dcu
zsh: command not found: dcu
danel@1111QD-rs ~ % dps
zsh: command not found: dps
danel@1111QD-rs ~ % 

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

Last login: Fri Oct 23 13:42:57 on ttys002
/Users/danel/.zshrc:27: no such file or directory: /opt/homebrew/bin/brew
/Users/danel/.zshrc:28: no such file or directory: /opt/homebrew/bin/brew
danel@1111QD-rs ~ % mkdir -p ~/ignite3 && cd ~/ignite3

curl -fLO https://ignite.apache.org/docs/ignite3/latest/quick-start/sql-files/docker-compose.yml
curl -fLO https://ignite.apache.org/docs/ignite3/latest/quick-start/sql-files/sql.zip

mkdir -p sql sql_tmp
unzip -o sql.zip -d sql_tmp
find sql_tmp -name '*.sql' -not -path '*__MACOSX*' -not -name '._*' -exec cp {} sql/ \;
rm -rf sql_tmp
ls sql
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1553  100  1553    0     0  15840      0 --:--:-- --:--:-- --:--:-- 16010
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  134k  100  134k    0     0   931k      0 --:--:-- --:--:-- --:--:--  937k
Archive:  sql.zip
   creating: /Users/danel/ignite3/sql_tmp/sql
  inflating: sql_tmp/sql/current_catalog.sql  
  inflating: sql_tmp/sql/ee_and_cust.sql  
  inflating: sql_tmp/sql/invoices.sql  
  inflating: sql_tmp/sql/media_and_genre.sql  
  inflating: sql_tmp/sql/schema.sql  
  inflating: sql_tmp/sql/tracks.sql  
current_catalog.sql	ee_and_cust.sql		invoices.sql		media_and_genre.sql	schema.sql		tracks.sql
danel@1111QD-rs ignite3 % mkdir -p ~/ignite3 && cd ~/ignite3

curl -fLO https://ignite.apache.org/docs/ignite3/latest/quick-start/sql-files/docker-compose.yml
curl -fLO https://ignite.apache.org/docs/ignite3/latest/quick-start/sql-files/sql.zip

mkdir -p sql sql_tmp
unzip -o sql.zip -d sql_tmp
find sql_tmp -name '*.sql' -not -path '*__MACOSX*' -not -name '._*' -exec cp {} sql/ \;
rm -rf sql_tmp
ls sql
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1553  100  1553    0     0  16312      0 --:--:-- --:--:-- --:--:-- 16177
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  134k  100  134k    0     0   890k      0 --:--:-- --:--:-- --:--:--  893k
Archive:  sql.zip
   creating: /Users/danel/ignite3/sql_tmp/sql
  inflating: sql_tmp/sql/current_catalog.sql  
  inflating: sql_tmp/sql/ee_and_cust.sql  
  inflating: sql_tmp/sql/invoices.sql  
  inflating: sql_tmp/sql/media_and_genre.sql  
  inflating: sql_tmp/sql/schema.sql  
  inflating: sql_tmp/sql/tracks.sql  
current_catalog.sql	docker-compose.yml	ee_and_cust.sql		invoices.sql		media_and_genre.sql	schema.sql		tracks.sql
danel@1111QD-rs ignite3 % [ -f sql/schema.sql ] || cat > sql/schema.sql <<'EOF'
CREATE ZONE IF NOT EXISTS Chinook WITH replicas=2, storage_profiles='default';
CREATE ZONE IF NOT EXISTS ChinookReplicated WITH replicas=3, partitions=25, storage_profiles='default';
CREATE TABLE Artist (ArtistId INT NOT NULL, Name VARCHAR(120), PRIMARY KEY (ArtistId)) ZONE Chinook;
CREATE TABLE Album (AlbumId INT NOT NULL, Title VARCHAR(160) NOT NULL, ArtistId INT NOT NULL, ReleaseYear INT, PRIMARY KEY (AlbumId, ArtistId)) COLOCATE BY (ArtistId) ZONE Chinook;
CREATE TABLE Genre (GenreId INT NOT NULL, Name VARCHAR(120), PRIMARY KEY (GenreId)) ZONE ChinookReplicated;
CREATE TABLE MediaType (MediaTypeId INT NOT NULL, Name VARCHAR(120), PRIMARY KEY (MediaTypeId)) ZONE ChinookReplicated;
CREATE TABLE Track (TrackId INT NOT NULL, Name VARCHAR(200) NOT NULL, AlbumId INT, MediaTypeId INT NOT NULL, GenreId INT, Composer VARCHAR(220), Milliseconds INT NOT NULL, Bytes INT, UnitPrice NUMERIC(10,2) NOT NULL, PRIMARY KEY (TrackId, AlbumId)) COLOCATE BY (AlbumId) ZONE Chinook;
CREATE TABLE Employee (EmployeeId INT NOT NULL, LastName VARCHAR(20) NOT NULL, FirstName VARCHAR(20) NOT NULL, Title VARCHAR(30), ReportsTo INT, BirthDate DATE, HireDate DATE, Address VARCHAR(70), City VARCHAR(40), State VARCHAR(40), Country VARCHAR(40), PostalCode VARCHAR(10), Phone VARCHAR(24), Fax VARCHAR(24), Email VARCHAR(60), PRIMARY KEY (EmployeeId)) ZONE Chinook;
CREATE TABLE Customer (CustomerId INT NOT NULL, FirstName VARCHAR(40) NOT NULL, LastName VARCHAR(20) NOT NULL, Company VARCHAR(80), Address VARCHAR(70), City VARCHAR(40), State VARCHAR(40), Country VARCHAR(40), PostalCode VARCHAR(10), Phone VARCHAR(24), Fax VARCHAR(24), Email VARCHAR(60) NOT NULL, SupportRepId INT, PRIMARY KEY (CustomerId)) ZONE Chinook;
CREATE TABLE Invoice (InvoiceId INT NOT NULL, CustomerId INT NOT NULL, InvoiceDate DATE NOT NULL, BillingAddress VARCHAR(70), BillingCity VARCHAR(40), BillingState VARCHAR(40), BillingCountry VARCHAR(40), BillingPostalCode VARCHAR(10), Total NUMERIC(10,2) NOT NULL, PRIMARY KEY (InvoiceId, CustomerId)) COLOCATE BY (CustomerId) ZONE Chinook;
CREATE TABLE InvoiceLine (InvoiceLineId INT NOT NULL, InvoiceId INT NOT NULL, TrackId INT NOT NULL, UnitPrice NUMERIC(10,2) NOT NULL, Quantity INT NOT NULL, PRIMARY KEY (InvoiceLineId, TrackId)) COLOCATE BY (TrackId) ZONE Chinook;
CREATE TABLE Playlist (PlaylistId INT NOT NULL, Name VARCHAR(120), PRIMARY KEY (PlaylistId)) ZONE Chinook;
CREATE TABLE PlaylistTrack (PlaylistId INT NOT NULL, TrackId INT NOT NULL, PRIMARY KEY (PlaylistId, TrackId)) ZONE Chinook;
CREATE INDEX idx_track_name ON Track (Name);
CREATE INDEX idx_album_artist ON Album (ArtistId, Title);
CREATE INDEX idx_track_albumid_name ON Track(AlbumId, Name);
CREATE INDEX idx_album_title ON Album(Title);
CREATE INDEX idx_invoiceline_trackid_invoiceid ON InvoiceLine(TrackId, InvoiceId);
CREATE INDEX idx_customer_email ON Customer USING HASH (Email);
EOF
danel@1111QD-rs ignite3 % cat > env.sh <<'EOF'
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dps="docker ps"
ignite_net() { docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' "$(docker compose ps -q node1)"; }
dcli() { docker run --rm -it --network="$(ignite_net)" -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 apacheignite/ignite:3.1.0 cli; }
dclm() { docker run --rm -it --network="$(ignite_net)" -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 -v "$PWD/sql:/opt/ignite/sql" apacheignite/ignite:3.1.0 cli; }
EOF
source env.sh
danel@1111QD-rs ignite3 % dcu
sleep 10
dps
[+] up 3/3
 ✔ Container ignite3-node3-1 Running                                                                                                                                                                                                      0.0s
 ✔ Container ignite3-node1-1 Running                                                                                                                                                                                                      0.0s
 ✔ Container ignite3-node2-1 Running                                                                                                                                                                                                      0.0s
CONTAINER ID   IMAGE                       COMMAND                  CREATED         STATUS         PORTS                                                                                                        NAMES
146ea7478453   apacheignite/ignite:3.1.0   "docker-entrypoint.s…"   6 minutes ago   Up 4 minutes   0.0.0.0:10300->10300/tcp, [::]:10300->10300/tcp, 3344/tcp, 0.0.0.0:10800->10800/tcp, [::]:10800->10800/tcp   ignite3-node1-1
507990733c5b   apacheignite/ignite:3.1.0   "docker-entrypoint.s…"   6 minutes ago   Up 4 minutes   3344/tcp, 0.0.0.0:10301->10300/tcp, [::]:10301->10300/tcp, 0.0.0.0:10801->10800/tcp, [::]:10801->10800/tcp   ignite3-node2-1
5c33ba87703c   apacheignite/ignite:3.1.0   "docker-entrypoint.s…"   6 minutes ago   Up 4 minutes   3344/tcp, 0.0.0.0:10302->10300/tcp, [::]:10302->10300/tcp, 0.0.0.0:10802->10800/tcp, [::]:10802->10800/tcp   ignite3-node3-1
danel@1111QD-rs ignite3 % for n in node1 node2 node3; do
  echo -n "$n: "
  docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$(docker compose ps -q $n)"
done
node1: 172.19.0.2
node2: 172.19.0.3
node3: 172.19.0.4
danel@1111QD-rs ignite3 % dclm


           #              ___                         __
         ###             /   |   ____   ____ _ _____ / /_   ___
     #  #####           / /| |  / __ \ / __ `// ___// __ \ / _ \
   ###  ######         / ___ | / /_/ // /_/ // /__ / / / // ___/
  #####  #######      /_/  |_|/ .___/ \__,_/ \___//_/ /_/ \___/
  #######  ######            /_/
    ########  ####        ____               _  __           _____
   #  ########  ##       /  _/____ _ ____   (_)/ /_ ___     |__  /
  ####  #######  #       / / / __ `// __ \ / // __// _ \     /_ <
   #####  #####        _/ / / /_/ // / / // // /_ / ___/   ___/ /
     ####  ##         /___/ \__, //_/ /_//_/ \__/ \___/   /____/
       ##                  /____/

                      Apache Ignite CLI version 3.1.0


You appear to have not connected to any node yet. Do you want to connect to the default node http://localhost:10300? [Y/n] n
[disconnected]> connect http://node1:10300
> cluster init --name=ignite3 --metastorage-group=node1,node2,node3
> cluster status
Unmatched arguments from index 2: 'cluster', 'init', '--name=ignite3', '--metastorage-group=node1,node2,node3', 'cluster', 'status'

USAGE
 connect [OPTIONS] <nodeUrl>

DESCRIPTION
Connects to Ignite 3 node

PARAMETERS * - required parameter
*     <nodeUrl>   URL of a node that will be used as a communication endpoint. It can be any node URL. If not set, then the default URL from the profile settings will be used

OPTIONS * - required option
* -u, --username=<username>
                  Username to connect to cluster
* -p, --password=<password>
                  Password to connect to cluster
  -h, --help      Show help for the specified command
  -v, --verbose   Show additional information: logs, REST calls. This flag is useful for debugging. Specify multiple options to increase verbosity for REST calls. Single option shows request and response, second option (-vv) shows
                    headers, third one (-vvv) shows body
[disconnected]> connect http://node1:10300
Connected to http://node1:10300
The cluster is not initialized. Run cluster init command to initialize it.
[node1]> cluster init --name=ignite3 --metastorage-group=node1,node2,node3
Cluster was initialized successfully
[node1]> cluster status
[nodes: N/A, status: not initialized]
[node1]> cluster init --cluster-name=ignite3_cluster --meta-storage-node=node1 --meta-storage-node=node2 --meta-storage-node=node3
> 
Missing required option: '--name=<clusterName>'

USAGE
 cluster init [OPTIONS]

DESCRIPTION
Initializes an Ignite cluster

OPTIONS * - required option
*     --name=<clusterName>   Human-readable name of the cluster
      --metastorage-group=<node name>[,<node name>...]
                             Metastorage group nodes (use comma-separated list of node names '--metastorage-group node1, node2' to specify more than one node) that will host the Meta Storage. If the --cluster-management-group option is
                               omitted, the same nodes will also host the Cluster Management Group.
      --cluster-management-group=<node name>[,<node name>...]
                             Names of nodes (use comma-separated list of node names '--cluster-management-group node1, node2' to specify more than one node) that will host the Cluster Management Group. If omitted, then
                               --metastorage-group values will also supply the nodes for the Cluster Management Group.
      --config=<config>      Cluster configuration that will be applied during the cluster initialization
      --config-files=<file path>[,<file path>...]
                             Path to cluster configuration files (use comma-separated list of paths '--config-files path1, path2' to specify more than one file)
      --url=<clusterUrl>     URL of cluster endpoint. It can be any node URL.If not set, then the default URL from the profile settings will be used
  -h, --help                 Show help for the specified command
  -v, --verbose              Show additional information: logs, REST calls. This flag is useful for debugging. Specify multiple options to increase verbosity for REST calls. Single option shows request and response, second option (-vv)
                               shows headers, third one (-vvv) shows body
[node1]> cluster status
> 
[name: ignite3, nodes: 3, status: active, cmgNodes: [node1, node2, node3], msNodes: [node1, node2, node3]]
[node1]> sql --file=/opt/ignite/sql/schema.sql
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.
Updated 0 rows.

[node1]> sql --file=/opt/ignite/sql/current_catalog.sql
Updated 275 rows.
Updated 347 rows.

[node1]> sql --file=/opt/ignite/sql/media_and_genre.sql
Updated 25 rows.
Updated 5 rows.

[node1]> sql --file=/opt/ignite/sql/tracks.sql
Updated 1000 rows.
Updated 1000 rows.
Updated 1000 rows.
Updated 503 rows.

[node1]> sql --file=/opt/ignite/sql/ee_and_cust.sql
Updated 8 rows.
Updated 59 rows.

[node1]> sql --file=/opt/ignite/sql/invoices.sql
Updated 412 rows.
Updated 1000 rows.
Updated 1000 rows.
Updated 240 rows.
Updated 18 rows.
Updated 1000 rows.
Updated 1000 rows.
Updated 1000 rows.
Updated 1000 rows.
Updated 1000 rows.
Updated 1000 rows.
Updated 1000 rows.
Updated 1000 rows.
Updated 715 rows.

[node1]> sql
sql-cli> SELECT * FROM system.tables WHERE schema = 'PUBLIC';
╔═════════════╤═══════════════╤══════════╤═══════════════════╤═══════════════════╤═════════════════╤══════════════════════════╤═══════════╤═════════╤════════╤═══════════════╤════╤═════════════╤══════════════════════╤═══════════════════╗
║ SCHEMA_NAME │ TABLE_NAME    │ TABLE_ID │ TABLE_PK_INDEX_ID │ ZONE_NAME         │ STORAGE_PROFILE │ TABLE_COLOCATION_COLUMNS │ SCHEMA_ID │ ZONE_ID │ SCHEMA │ NAME          │ ID │ PK_INDEX_ID │ COLOCATION_KEY_INDEX │ ZONE              ║
╠═════════════╪═══════════════╪══════════╪═══════════════════╪═══════════════════╪═════════════════╪══════════════════════════╪═══════════╪═════════╪════════╪═══════════════╪════╪═════════════╪══════════════════════╪═══════════════════╣
║ PUBLIC      │ ALBUM         │ 22       │ 23                │ CHINOOK           │ default         │ ARTISTID                 │ 1         │ 20      │ PUBLIC │ ALBUM         │ 22 │ 23          │ ARTISTID             │ CHINOOK           ║
╟─────────────┼───────────────┼──────────┼───────────────────┼───────────────────┼─────────────────┼──────────────────────────┼───────────┼─────────┼────────┼───────────────┼────┼─────────────┼──────────────────────┼───────────────────╢
║ PUBLIC      │ PLAYLISTTRACK │ 40       │ 41                │ CHINOOK           │ default         │ PLAYLISTID, TRACKID      │ 1         │ 20      │ PUBLIC │ PLAYLISTTRACK │ 40 │ 41          │ PLAYLISTID, TRACKID  │ CHINOOK           ║
╟─────────────┼───────────────┼──────────┼───────────────────┼───────────────────┼─────────────────┼──────────────────────────┼───────────┼─────────┼────────┼───────────────┼────┼─────────────┼──────────────────────┼───────────────────╢
║ PUBLIC      │ TRACK         │ 42       │ 43                │ CHINOOK           │ default         │ ALBUMID                  │ 1         │ 20      │ PUBLIC │ TRACK         │ 42 │ 43          │ ALBUMID              │ CHINOOK           ║
╟─────────────┼───────────────┼──────────┼───────────────────┼───────────────────┼─────────────────┼──────────────────────────┼───────────┼─────────┼────────┼───────────────┼────┼─────────────┼──────────────────────┼───────────────────╢
║ PUBLIC      │ CUSTOMER      │ 26       │ 27                │ CHINOOK           │ default         │ CUSTOMERID               │ 1         │ 20      │ PUBLIC │ CUSTOMER      │ 26 │ 27          │ CUSTOMERID           │ CHINOOK           ║
╟─────────────┼───────────────┼──────────┼───────────────────┼───────────────────┼─────────────────┼──────────────────────────┼───────────┼─────────┼────────┼───────────────┼────┼─────────────┼──────────────────────┼───────────────────╢
║ PUBLIC      │ MEDIATYPE     │ 36       │ 37                │ CHINOOKREPLICATED │ default         │ MEDIATYPEID              │ 1         │ 21      │ PUBLIC │ MEDIATYPE     │ 36 │ 37          │ MEDIATYPEID          │ CHINOOKREPLICATED ║
╟─────────────┼───────────────┼──────────┼───────────────────┼───────────────────┼─────────────────┼──────────────────────────┼───────────┼─────────┼────────┼───────────────┼────┼─────────────┼──────────────────────┼───────────────────╢
║ PUBLIC      │ PLAYLIST      │ 38       │ 39                │ CHINOOK           │ default         │ PLAYLISTID               │ 1         │ 20      │ PUBLIC │ PLAYLIST      │ 38 │ 39          │ PLAYLISTID           │ CHINOOK           ║
╟─────────────┼───────────────┼──────────┼───────────────────┼───────────────────┼─────────────────┼──────────────────────────┼───────────┼─────────┼────────┼───────────────┼────┼─────────────┼──────────────────────┼───────────────────╢
║ PUBLIC      │ ARTIST        │ 24       │ 25                │ CHINOOK           │ default         │ ARTISTID                 │ 1         │ 20      │ PUBLIC │ ARTIST        │ 24 │ 25          │ ARTISTID             │ CHINOOK           ║
╟─────────────┼───────────────┼──────────┼───────────────────┼───────────────────┼─────────────────┼──────────────────────────┼───────────┼─────────┼────────┼───────────────┼────┼─────────────┼──────────────────────┼───────────────────╢
║ PUBLIC      │ INVOICELINE   │ 34       │ 35                │ CHINOOK           │ default         │ INVOICEID                │ 1         │ 20      │ PUBLIC │ INVOICELINE   │ 34 │ 35          │ INVOICEID            │ CHINOOK           ║
╟─────────────┼───────────────┼──────────┼───────────────────┼───────────────────┼─────────────────┼──────────────────────────┼───────────┼─────────┼────────┼───────────────┼────┼─────────────┼──────────────────────┼───────────────────╢
║ PUBLIC      │ EMPLOYEE      │ 28       │ 29                │ CHINOOK           │ default         │ EMPLOYEEID               │ 1         │ 20      │ PUBLIC │ EMPLOYEE      │ 28 │ 29          │ EMPLOYEEID           │ CHINOOK           ║
╟─────────────┼───────────────┼──────────┼───────────────────┼───────────────────┼─────────────────┼──────────────────────────┼───────────┼─────────┼────────┼───────────────┼────┼─────────────┼──────────────────────┼───────────────────╢
║ PUBLIC      │ GENRE         │ 30       │ 31                │ CHINOOKREPLICATED │ default         │ GENREID                  │ 1         │ 21      │ PUBLIC │ GENRE         │ 30 │ 31          │ GENREID              │ CHINOOKREPLICATED ║
╟─────────────┼───────────────┼──────────┼───────────────────┼───────────────────┼─────────────────┼──────────────────────────┼───────────┼─────────┼────────┼───────────────┼────┼─────────────┼──────────────────────┼───────────────────╢
║ PUBLIC      │ INVOICE       │ 32       │ 33                │ CHINOOK           │ default         │ CUSTOMERID               │ 1         │ 20      │ PUBLIC │ INVOICE       │ 32 │ 33          │ CUSTOMERID           │ CHINOOK           ║
╚═════════════╧═══════════════╧══════════╧═══════════════════╧═══════════════════╧═════════════════╧══════════════════════════╧═══════════╧═════════╧════════╧═══════════════╧════╧═════════════╧══════════════════════╧═══════════════════╝

sql-cli> exit
> connect http://node2:10300
> exit;
> connect http://node2:10300
> sql
> SELECT COUNT(*) FROM Track;
Unmatched arguments from index 1: 'connect', 'http://node2:10300', 'exit;', 'connect', 'http://node2:10300', 'sql', 'SELECT', 'COUNT(*)', 'FROM', 'Track'

USAGE
 exit [OPTIONS]

DESCRIPTION
Exit

OPTIONS * - required option
  -h, --help      Show help for the specified command
  -v, --verbose   Show additional information: logs, REST calls. This flag is useful for debugging. Specify multiple options to increase verbosity for REST calls. Single option shows request and response, second option (-vv) shows
                    headers, third one (-vvv) shows body
sql-cli> SELECT
>     CAST(EXTRACT(YEAR FROM i.InvoiceDate) AS VARCHAR) || '-' ||
>     CASE
>         WHEN EXTRACT(MONTH FROM i.InvoiceDate) < 10
>         THEN '0' || CAST(EXTRACT(MONTH FROM i.InvoiceDate) AS VARCHAR)
>         ELSE CAST(EXTRACT(MONTH FROM i.InvoiceDate) AS VARCHAR)
>     END AS YearMonth,
>     COUNT(DISTINCT i.InvoiceId) AS InvoiceCount,
>     COUNT(DISTINCT i.CustomerId) AS CustomerCount,
>     SUM(i.Total) AS MonthlyRevenue,
>     AVG(i.Total) AS AverageOrderValue
> FROM
>     Invoice i
> GROUP BY
>     EXTRACT(YEAR FROM i.InvoiceDate), EXTRACT(MONTH FROM i.InvoiceDate)
> ORDER BY
>     YearMonth DESC;
╔═══════════╤══════════════╤═══════════════╤════════════════╤════════════════════╗
║ YEARMONTH │ INVOICECOUNT │ CUSTOMERCOUNT │ MONTHLYREVENUE │ AVERAGEORDERVALUE  ║
╠═══════════╪══════════════╪═══════════════╪════════════════╪════════════════════╣
║ 2024-12   │ 7            │ 7             │ 38.62          │ 5.5171428571428571 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2024-11   │ 7            │ 7             │ 49.62          │ 7.0885714285714285 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2024-10   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2024-09   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2024-08   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2024-07   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2024-06   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2024-05   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2024-04   │ 5            │ 5             │ 33.66          │ 6.7320000000000000 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2024-03   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2024-02   │ 5            │ 5             │ 27.72          │ 5.5440000000000000 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2024-01   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2023-12   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2023-11   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2023-10   │ 7            │ 7             │ 42.62          │ 6.0885714285714285 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2023-09   │ 6            │ 6             │ 46.71          │ 7.7850000000000000 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2023-08   │ 7            │ 7             │ 47.62          │ 6.8028571428571428 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2023-07   │ 7            │ 7             │ 39.62          │ 5.6600000000000000 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2023-06   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2023-05   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2023-04   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2023-03   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2023-02   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2023-01   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2022-12   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2022-11   │ 6            │ 6             │ 23.76          │ 3.9600000000000000 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2022-10   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2022-09   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2022-08   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2022-07   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2022-06   │ 7            │ 7             │ 50.62          │ 7.2314285714285714 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2022-05   │ 7            │ 7             │ 42.62          │ 6.0885714285714285 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2022-04   │ 7            │ 7             │ 51.62          │ 7.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2022-03   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2022-02   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2022-01   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2021-12   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2021-11   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2021-10   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2021-09   │ 6            │ 6             │ 36.63          │ 6.1050000000000000 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2021-08   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2021-07   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2021-06   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2021-05   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2021-04   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2021-03   │ 7            │ 7             │ 44.62          │ 6.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2021-02   │ 7            │ 7             │ 46.62          │ 6.6600000000000000 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2021-01   │ 7            │ 7             │ 52.62          │ 7.5171428571428571 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2020-12   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2020-11   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2020-10   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2020-09   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2020-08   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2020-07   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2020-06   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2020-05   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2020-04   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2020-03   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2020-02   │ 7            │ 7             │ 37.62          │ 5.3742857142857142 ║
╟───────────┼──────────────┼───────────────┼────────────────┼────────────────────╢
║ 2020-01   │ 6            │ 6             │ 35.64          │ 5.9400000000000000 ║
╚═══════════╧══════════════╧═══════════════╧════════════════╧════════════════════╝

