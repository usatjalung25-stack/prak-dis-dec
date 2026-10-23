# Modul 4 - Konsistensi dan Replikasi pada Sistem Terdistribusi

Praktikum Sistem Terdistribusi dan Terdesentralisasi
Prodi Informatika - Universitas Teknologi Digital Indonesia

| | |
|---|---|
| Nama | USAT JALUNG |
| NIM |255410017 |
| Kelas | INFORMATIKA - 1 |
| Tanggal pengerjaan | 23 Oktober 2026 |
| Lingkungan | macOS (Apple Silicon) + Colima (Docker runtime) |
| Docker / Compose | Docker 29.9.2 / Docker Compose 5.6.1 |

## Sumber Praktikum

| | |
|---|---|
| Modul | *Modul 4 - Konsistensi dan Replikasi pada Sistem Terdistribusi* (22 halaman), Praktikum Sistem Terdistribusi dan Terdesentralisasi |
| Penulis modul | Dr. Bambang Purnomosidi D. P. (Prodi Informatika, Universitas Teknologi Digital Indonesia) |
| GitHub penulis | https://github.com/bpdp (profil: *Bambang Purnomosidi D. P.*, 30 repositori publik) |
| Materi 4.1 | Berdasarkan artikel Eremeykin, *How to Setup Single Primary PostgreSQL Replication with Docker Compose* (Medium) |
| Materi 4.2 | Berdasarkan dokumentasi resmi Apache Ignite 3 (versi 3.1.0) |
| Repositori praktikum ini | https://github.com/usatjalung25-stack/prak-dis-dec (folder `04/`) |

Dokumen ini memuat: (a) seluruh kode dan penjelasan, (b) output hasil praktikum sendiri, (c) **output pembanding dari modul** (Lampiran B), (d) **kode asli modul** dibandingkan dengan versi yang dipakai (Lampiran C), (e) **skrip bantu** untuk mengulang percobaan (Lampiran D), dan (f) daftar referensi.

---

## Daftar Isi

1. [Tujuan Praktikum](#1-tujuan-praktikum)
2. [Konsep Singkat](#2-konsep-singkat)
3. [Instalasi Prasyarat](#3-instalasi-prasyarat)
4. [Bagian 4.1 - Streaming Replication PostgreSQL 18](#4-bagian-41---streaming-replication-postgresql-18)
5. [Bagian 4.2 - Replikasi Master-Master Apache Ignite 3](#5-bagian-42---replikasi-master-master-apache-ignite-3)
6. [Perbandingan Kedua Model Replikasi](#6-perbandingan-kedua-model-replikasi)
7. [Rangkuman Error dan Solusinya](#7-rangkuman-error-dan-solusinya)
8. [Perintah Lanjutan dan Berguna](#8-perintah-lanjutan-dan-berguna)
9. [Kesimpulan](#9-kesimpulan)
10. [Struktur Repositori](#10-struktur-repositori)
11. [Lampiran A - Log Terminal Lengkap](#11-lampiran-a---log-terminal-lengkap)
12. [Lampiran B - Output Pembanding dari Modul](#12-lampiran-b---output-pembanding-dari-modul)
13. [Lampiran C - Kode Asli Modul vs Versi Praktikum](#13-lampiran-c---kode-asli-modul-vs-versi-praktikum)
14. [Lampiran D - Skrip Bantu dan Cara Pakai](#14-lampiran-d---skrip-bantu-dan-cara-pakai)
15. [Referensi dan Sumber](#15-referensi-dan-sumber)

---

## 1. Tujuan Praktikum

1. Mengonfigurasi *streaming replication* satu primary dan satu replica pada PostgreSQL 18.3 memakai Docker Compose.
2. Membuktikan bahwa data di primary otomatis tereplikasi ke replica, dan bahwa replica bersifat *read-only*.
3. Mensimulasikan *High Availability* (failover) dengan mematikan primary lalu mempromosikan replica menggunakan `pg_promote()`.
4. Mengonfigurasi cluster 3 node Apache Ignite 3.1.0 dan membuktikan replikasi Master-Master (semua node dapat diakses untuk baca/tulis).
5. Mendokumentasikan seluruh proses, error yang muncul, dan solusinya.

---

## 2. Konsep Singkat

### Replikasi Primary-Replica (PostgreSQL)

Satu node menjadi **primary** (menerima baca dan tulis). Node lain menjadi **replica/standby** yang menerima aliran **WAL (Write-Ahead Log)** dari primary dan memutarnya ulang (*replay*), sehingga datanya selalu sama dengan primary. Replica hanya melayani operasi baca.

```mermaid
flowchart LR
    C1[Client Write/Read] -->|port 5432| P[(postgres_primary<br/>read-write)]
    P -- "WAL stream (async)<br/>slot: replication_slot" --> R[(postgres_replica<br/>read-only standby)]
    C2[Client Read] -->|port 5433| R
```

Pada praktikum ini replikasi bersifat **asynchronous** (`sync_state = async`): primary tidak menunggu replica mengonfirmasi sebelum commit selesai. Konsekuensinya, ada jeda singkat (*replication lag*) sehingga data baru di primary bisa belum langsung terlihat di replica.

### Replikasi Master-Master (Apache Ignite 3)

Semua node di cluster dapat melayani baca dan tulis. Data dipartisi dan direplikasi antar node berdasarkan konfigurasi **zone** (`replicas`, `partitions`). Pada schema Chinook:

| Zone | Replicas | Dipakai oleh |
|---|---|---|
| `Chinook` | 2 | Artist, Album, Track, Employee, Customer, Invoice, InvoiceLine, Playlist, PlaylistTrack |
| `ChinookReplicated` | 3 (di semua node) | Genre, MediaType (tabel referensi kecil) |

---

## 3. Instalasi Prasyarat

Pilih sesuai sistem operasi. Pengerjaan ini memakai **macOS + Colima**.

### 3.1 Linux (Ubuntu/Debian)

```bash
# Hapus paket lama (jika ada)
sudo apt remove -y docker docker-engine docker.io containerd runc

# Dependensi dan GPG key resmi Docker
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Tambah repositori
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Pasang Docker Engine + Compose plugin
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Aktifkan daemon (systemd)
sudo systemctl enable --now docker

# (Opsional) jalankan docker tanpa sudo, lalu logout/login
sudo usermod -aG docker $USER
```

Untuk sistem dengan **dinit** (seperti di modul):

```bash
sudo dinitctl start dockerd
```

### 3.2 macOS (yang dipakai pada praktikum ini)

Docker Desktop bisa dipakai. Praktikum ini memakai **Colima** (ringan, gratis) sebagai runtime.

```bash
# Instal Homebrew bila belum ada
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instal Colima, Docker CLI, dan Compose
brew install colima docker docker-compose

# Jalankan VM Docker
colima start
```

Keluaran yang diharapkan:

```text
INFO[0001] starting colima
INFO[0001] runtime: docker
INFO[0002] starting ... context=vm
INFO[0031] provisioning ... context=docker
INFO[0037] starting ... context=docker
INFO[0040] done
```

> **Penting - memori VM:** compose Ignite memberi tiap node `JVM_MAX_MEM: "4g"` (3 node = sampai 12 GB). Bila Colima memakai ukuran bawaan (sekitar 2 GB RAM), node bisa mati karena kehabisan memori (`OOMKilled`, container `Exited (137)`). Untuk bagian 4.2 jalankan Colima dengan sumber daya lebih besar:
>
> ```bash
> colima stop
> colima start --cpu 4 --memory 12 --disk 60
> colima status
> ```
>
> Bila RAM laptop terbatas, turunkan `JVM_MAX_MEM` dan `JVM_MIN_MEM` di `docker-compose.yml` ke `1g` atau `2g` untuk percobaan ini.

### 3.3 Windows

1. Aktifkan WSL2: `wsl --install`
2. Pasang **Docker Desktop** dan aktifkan opsi *Use the WSL 2 based engine*.
3. Jalankan seluruh perintah praktikum dari terminal WSL (Ubuntu).

### 3.4 Verifikasi Instalasi

```bash
docker --version && docker compose version
```

Hasil pada praktikum ini:

```text
Docker version 29.9.2, build a82e528901
Docker Compose version 5.6.1
```

> **Catatan `docker-compose` vs `docker compose`:** modul memakai `docker-compose` (v1, perintah terpisah dan sudah usang). Versi modern memakai **`docker compose`** (spasi, sebagai plugin Docker). Pada README ini semua perintah memakai `docker compose`.

---

## 4. Bagian 4.1 - Streaming Replication PostgreSQL 18

### 4.1 Struktur Direktori

```bash
mkdir -p ~/streaming-replication && cd ~/streaming-replication
```

```text
streaming-replication/
├── 00_init.sql
├── docker-compose.yaml
└── env.sh

1 directory, 3 files
```

| File | Fungsi |
|---|---|
| `00_init.sql` | Dijalankan otomatis saat primary pertama kali diinisialisasi: membuat user `replicator` dan *replication slot*. |
| `docker-compose.yaml` | Mendefinisikan dua layanan: `postgres_primary` dan `postgres_replica`. |
| `env.sh` | Kumpulan alias shell agar perintah lebih singkat (opsional). |

### 4.2 `00_init.sql`

```sql
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator_password';
SELECT pg_create_physical_replication_slot('replication_slot');
```

Pembahasan:

- `CREATE USER replicator WITH REPLICATION ...` membuat role khusus replikasi. Atribut `REPLICATION` diperlukan agar role boleh membuka koneksi replikasi. Password disimpan terenkripsi.
- `pg_create_physical_replication_slot('replication_slot')` membuat **slot replikasi fisik**. Slot membuat primary menahan file WAL yang belum dikonsumsi replica, sehingga replica tidak ketinggalan walau sempat terputus.
- File di `/docker-entrypoint-initdb.d/` hanya dieksekusi **sekali**, ketika direktori data masih kosong.

### 4.3 `docker-compose.yaml`

```yaml
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
```

#### Pembahasan blok per blok

**Template bersama (`x-postgres-common` + anchor `&postgres-common`)**

| Baris | Penjelasan |
|---|---|
| `image: postgres:18.3-alpine3.23` | PostgreSQL 18.3 di atas Alpine Linux (ukuran kecil). |
| `user: postgres` | Proses dijalankan sebagai user `postgres` (bukan root), sesuai kebutuhan `pg_basebackup` dan `postgres`. |
| `restart: always` | Container otomatis hidup kembali bila berhenti. |
| `healthcheck` | `pg_isready` dijalankan tiap 10 detik. Status `healthy` muncul bila server siap menerima koneksi. |
| `<<: *postgres-common` | Menyalin konfigurasi bersama ke tiap service (prinsip DRY). |

**Primary**

| Konfigurasi | Penjelasan |
|---|---|
| `POSTGRES_USER/DB/PASSWORD` | Membuat superuser `zuser`, database `zdb`, password `zpass`. |
| `POSTGRES_HOST_AUTH_METHOD` | Mengisi `pg_hba.conf`: koneksi umum memakai `scram-sha-256`, dan satu baris tambahan mengizinkan user `replicator` untuk koneksi `replication` dari alamat mana pun (`0.0.0.0/0`, metode `md5`). Cukup untuk lab; **jangan** dipakai apa adanya di produksi. |
| `POSTGRES_INITDB_ARGS: --auth-host=scram-sha-256` | Metode autentikasi default untuk koneksi TCP saat `initdb`. |
| `wal_level=replica` | Level detail WAL yang cukup untuk replikasi fisik. |
| `hot_standby=on` | Mengizinkan replica menerima query baca selama recovery. |
| `max_wal_senders=10` | Jumlah maksimum proses pengirim WAL (satu per replica yang terhubung). |
| `max_replication_slots=10` | Jumlah maksimum slot replikasi. |
| `hot_standby_feedback=on` | Replica memberi tahu primary baris mana yang masih dipakai query baca, mengurangi konflik query saat *vacuum*. |
| `volumes` | Memasang `00_init.sql` ke direktori init agar dieksekusi saat inisialisasi. |

**Replica**

| Konfigurasi | Penjelasan |
|---|---|
| `PGUSER`, `PGPASSWORD` | Kredensial yang dipakai `pg_basebackup` untuk terhubung ke primary. |
| `PGDATA=/var/lib/postgresql/18/docker` | Pada PostgreSQL 18 image resmi, direktori data berpindah dari `/var/lib/postgresql/data` ke `/var/lib/postgresql/18/docker`. |
| `pg_basebackup ... -R --slot=... -X stream` | Menyalin seluruh data primary ke replica. `-R` membuat `standby.signal` dan mengisi `primary_conninfo` otomatis. `--slot` memakai slot yang sudah dibuat. `-X stream` ikut mengalirkan WAL selama proses backup. |
| `until ... do sleep 5; done` | Mengulang percobaan sampai primary siap. |
| `if [ ! -s "$$PGDATA/PG_VERSION" ]` | Backup hanya dijalankan bila direktori data masih kosong. Ini membuat replica aman di-*restart* tanpa error "directory not empty". |
| `$$PGDATA` | Tanda `$$` adalah *escape* Compose agar variabel di-resolve di dalam container, bukan oleh Compose di host. |
| `chmod 0700` | PostgreSQL menolak start bila izin direktori data terlalu longgar. |
| `exec postgres` | Mengganti proses bash dengan postgres agar sinyal (stop/restart) diterima langsung. |
| `depends_on ... service_healthy` | Replica baru dijalankan setelah primary berstatus `healthy`. |

#### Perbedaan dengan versi di modul

| Modul | Versi yang dipakai di sini | Alasan |
|---|---|---|
| `depends_on: - postgres_primary` | `condition: service_healthy` | Mencegah replica mulai sebelum primary siap, sehingga tidak ada error `connection refused` pada log. |
| `bash -c "...pg_basebackup..."` selalu dijalankan | Dicek dulu dengan `PG_VERSION` | Aman saat container di-restart. |
| `command: bash -c "..."` (string) | `command` dalam bentuk list | Menghindari masalah *quoting* multi-baris. |
| `$PGDATA` literal | `$$PGDATA` | Mencegah Compose mengganti variabel di host. |
| (tidak ada) | `name: streaming-replication` | Nama project tetap, sehingga nama container konsisten tidak bergantung nama direktori. |

### 4.4 `env.sh`

```bash
alias dcu="docker compose up -d --wait"
alias dcd="docker compose down -v"
alias dps="docker ps"
alias der="docker compose exec postgres_replica bash"
alias dep="docker compose exec postgres_primary bash"
alias dlr="docker compose logs postgres_replica"
alias dlp="docker compose logs postgres_primary"
```

| Alias | Fungsi |
|---|---|
| `dcu` | Menyalakan semua service di latar belakang dan menunggu sampai `healthy` (`--wait`). |
| `dcd` | Mematikan dan menghapus container, network, **serta volume** (`-v`) agar percobaan berikutnya mulai dari kondisi bersih. |
| `dps` | Daftar container yang berjalan. |
| `der` / `dep` | Masuk shell di replica / primary. |
| `dlr` / `dlp` | Log replica / primary. |

Berbeda dengan modul, alias memakai `docker compose exec <service>` sehingga **tidak bergantung pada nama container** dan tidak memakai `sudo` (tidak perlu di macOS/Colima).

Muat alias ke shell yang sedang aktif:

```bash
source env.sh
```

### 4.5 Membuat File (satu perintah)

```bash
cat > 00_init.sql <<'EOF'
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator_password';
SELECT pg_create_physical_replication_slot('replication_slot');
EOF
```

(Lakukan hal yang sama untuk `docker-compose.yaml` dan `env.sh` dengan isi di atas, atau salin dari repositori ini.)

### 4.6 Menjalankan Cluster

```bash
source env.sh
dcu
```

Keluaran:

```text
[+] up 3/3
 ✔ Network streaming-replication_default           Created  0.1s
 ✔ Container streaming-replication-postgres_primary-1  Healthy  12.3s
 ✔ Container streaming-replication-postgres_replica-1  Healthy  22.1s
```

Periksa status container:

```bash
dps
```

```text
CONTAINER ID   IMAGE                      COMMAND                  CREATED          STATUS                    PORTS                                         NAMES
ff48a47b7fdd   postgres:18.3-alpine3.23   "docker-entrypoint.s…"   29 seconds ago   Up 18 seconds (healthy)   0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp   streaming-replication-postgres_replica-1
f1253648b62a   postgres:18.3-alpine3.23   "docker-entrypoint.s…"   30 seconds ago   Up 29 seconds (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp   streaming-replication-postgres_primary-1
```

Kedua container berstatus **`healthy`**, artinya ada 2 instance PostgreSQL 18.3: primary (port 5432) dan replica (port 5433).

Log replica:

```bash
dlr
```

```text
postgres_replica-1  | Backup done, starting replica...
postgres_replica-1  | LOG:  starting PostgreSQL 18.3 on x86_64-pc-linux-musl, compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit
postgres_replica-1  | LOG:  listening on IPv4 address "0.0.0.0", port 5432
postgres_replica-1  | LOG:  listening on IPv6 address "::", port 5432
postgres_replica-1  | LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
postgres_replica-1  | LOG:  database system was interrupted; last known up at 2026-10-23 06:19:05 UTC
postgres_replica-1  | LOG:  starting backup recovery with redo LSN 0/2000028, checkpoint LSN 0/2000080, on timeline ID 1
postgres_replica-1  | LOG:  entering standby mode
postgres_replica-1  | LOG:  redo starts at 0/2000028
postgres_replica-1  | LOG:  completed backup recovery with redo LSN 0/2000028 and end LSN 0/2000120
postgres_replica-1  | LOG:  consistent recovery state reached at 0/2000120
postgres_replica-1  | LOG:  database system is ready to accept read-only connections
postgres_replica-1  | LOG:  started streaming WAL from primary at 0/3000000 on timeline 1
```

Cara membaca log: `entering standby mode` menandakan node berjalan sebagai standby; `ready to accept read-only connections` berarti replica sudah bisa melayani query baca; `started streaming WAL from primary` berarti aliran WAL dari primary sudah aktif. Pesan "database system was interrupted" adalah normal setelah `pg_basebackup`.

### 4.7 Pengujian Replikasi

#### a. Status replikasi di primary - `pg_stat_replication`

```bash
docker compose exec postgres_primary psql -U zuser -d zdb -x -c "SELECT * FROM pg_stat_replication;"
```

```text
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
```

Analisis:

- `state = streaming`: replica sedang menerima aliran WAL secara aktif.
- `usename = replicator`, `application_name = walreceiver`: koneksi berasal dari proses WAL receiver replica.
- `client_addr = 172.19.0.3`: IP container replica di network Docker.
- `sent_lsn = write_lsn = flush_lsn = replay_lsn`: replica sudah menulis, mem-flush, dan me-replay WAL sampai posisi yang sama dengan yang dikirim primary, jadi tidak ada ketertinggalan (lag kosong karena tidak ada aktivitas tulis).
- `sync_state = async`: replikasi asinkron.

#### b. Slot replikasi - `pg_replication_slots`

```bash
docker compose exec postgres_primary psql -U zuser -d zdb -x -c "SELECT * FROM pg_replication_slots;"
```

```text
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
```

Analisis: `slot_type = physical` dan `active = t` dengan `active_pid = 67` (sama dengan `pid` pada `pg_stat_replication`), jadi slot sedang dipakai replica. `wal_status = reserved` berarti WAL yang dibutuhkan masih disimpan primary.

#### c. Memastikan node kedua adalah replica

```bash
docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT pg_is_in_recovery();"
```

```text
 pg_is_in_recovery
-------------------
 t
(1 row)
```

Nilai `t` (true) berarti server berada dalam mode recovery/standby: hanya mereplikasi dan melayani baca.

#### d. Sebelum membuat tabel (primary dan replica)

```bash
docker compose exec postgres_primary psql -U zuser -d zdb -c "\dt"
docker compose exec postgres_replica psql -U zuser -d zdb -c "\dt"
```

```text
Did not find any tables.
Did not find any tables.
```

#### e. Manipulasi data di primary

```bash
docker compose exec postgres_primary psql -U zuser -d zdb -c "CREATE TABLE testrep (first INT, second VARCHAR(15));"
docker compose exec postgres_primary psql -U zuser -d zdb -c "INSERT INTO testrep (first, second) VALUES (21, 'Test pertama');"
docker compose exec postgres_primary psql -U zuser -d zdb -c "INSERT INTO testrep (first, second) VALUES (23, 'Test ke dua');"
docker compose exec postgres_primary psql -U zuser -d zdb -c "SELECT * FROM testrep;"
```

```text
CREATE TABLE
INSERT 0 1
INSERT 0 1
 first |    second
-------+--------------
    21 | Test pertama
    23 | Test ke dua
(2 rows)
```

#### f. Cek hasil di replica

```bash
sleep 2
docker compose exec postgres_replica psql -U zuser -d zdb -c "\dt"
docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT * FROM testrep;"
```

```text
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
```

Tabel dan data yang dibuat di primary muncul otomatis di replica, jadi **replikasi berhasil**. Jeda `sleep 2` dipakai karena replikasi asinkron.

#### g. Membuktikan replica read-only

```bash
docker compose exec postgres_replica psql -U zuser -d zdb -c "INSERT INTO testrep VALUES (99, 'gagal');"
```

```text
ERROR:  cannot execute INSERT in a read-only transaction
```

Replica menolak operasi tulis, sesuai peran standby.

### 4.8 High Availability - Failover dengan `pg_promote()`

Skenario: primary mati, replica dipromosikan menjadi primary baru.

**Langkah 1 - Matikan primary** (jalankan **di host**, bukan di dalam container):

```bash
docker compose stop postgres_primary
```

```text
[+] stop 1/1
 ✔ Container streaming-replication-postgres_primary-1 Stopped  0.3s
```

**Langkah 2 - Cek status replica sebelum promosi:**

```bash
docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT pg_is_in_recovery();"
```

```text
 pg_is_in_recovery
-------------------
 t
```

**Langkah 3 - Promosikan replica:**

```bash
docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT pg_promote();"
```

```text
 pg_promote
------------
 t
```

**Langkah 4 - Verifikasi:**

```bash
docker compose exec postgres_replica psql -U zuser -d zdb -c "SELECT pg_is_in_recovery();"
```

```text
 pg_is_in_recovery
-------------------
 f
```

`f` (false) berarti node ini tidak lagi standby, tetapi sudah menjadi primary.

**Langkah 5 - Uji tulis di primary baru:**

```bash
docker compose exec postgres_replica psql -U zuser -d zdb -c "INSERT INTO testrep VALUES (25, 'Setelah promote');"
```

```text
INSERT 0 1
```

Operasi tulis yang sebelumnya ditolak kini berhasil. Failover sukses.

**Langkah 6 - Bersihkan:**

```bash
dcd
```

```text
[+] down 3/3
 ✔ Container streaming-replication-postgres_replica-1 Removed  0.3s
 ✔ Container streaming-replication-postgres_primary-1 Removed  0.1s
 ✔ Network streaming-replication_default              Removed  0.1s
```

```bash
dps
```

```text
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES
```

> **Catatan penting tentang failover manual:** setelah promosi, primary lama **tidak boleh** langsung dihidupkan lagi sebagai primary karena datanya berpisah (*split-brain*). Primary lama harus dibangun ulang sebagai replica dari primary baru (misalnya dengan `pg_basebackup` atau `pg_rewind`). Pada produksi, failover biasanya diotomasi dengan Patroni, repmgr, atau pg_auto_failover.

---

## 5. Bagian 4.2 - Replikasi Master-Master Apache Ignite 3

### 5.1 Menyiapkan File

```bash
mkdir -p ~/ignite3 && cd ~/ignite3

curl -fLO https://ignite.apache.org/docs/ignite3/latest/quick-start/sql-files/docker-compose.yml
curl -fLO https://ignite.apache.org/docs/ignite3/latest/quick-start/sql-files/sql.zip

mkdir -p sql sql_tmp
unzip -o sql.zip -d sql_tmp
find sql_tmp -name '*.sql' -not -path '*__MACOSX*' -not -name '._*' -exec cp {} sql/ \;
rm -rf sql_tmp
ls sql
```

Hasil:

```text
current_catalog.sql  docker-compose.yml  ee_and_cust.sql  invoices.sql  media_and_genre.sql  schema.sql  tracks.sql
```

Penjelasan perintah:

| Perintah | Fungsi |
|---|---|
| `curl -fLO` | `-f` gagal bila HTTP error, `-L` ikut redirect, `-O` simpan dengan nama file asli. |
| `unzip -o ... -d sql_tmp` | Ekstrak ke direktori sementara dan timpa tanpa bertanya. |
| `find ... -not -path '*__MACOSX*' -not -name '._*'` | Membuang file sampah metadata macOS dari arsip zip. |
| `cp ... sql/` | Menyalin hanya file `.sql` ke satu direktori datar `sql/`. |

> **Catatan:** pada modul, `unzip sql.zip` langsung menghasilkan direktori `sql/`. Pada arsip yang diunduh kali ini file berada di `sql/` di dalam arsip, sehingga dipakai direktori sementara agar struktur akhir tetap rata dan mudah di-*mount*.

#### `docker-compose.yml` Ignite

File ini diunduh dari Apache Ignite pada langkah di atas. Isinya sama dengan contoh pada panduan resmi *How to Start an Ignite 3 Cluster in Docker* [R14]. Bila hasil unduhan Anda sedikit berbeda, pakai hasil unduhan.

```yaml
name: ignite3

x-ignite-def: &ignite-def
  image: apacheignite/ignite:3.1.0
  environment:
    JVM_MAX_MEM: "4g"
    JVM_MIN_MEM: "4g"
  configs:
    - source: node_config
      target: /opt/ignite/etc/ignite-config.conf
      mode: 0644

services:
  node1:
    <<: *ignite-def
    command: --node-name node1
    ports:
      - "10300:10300"
      - "10800:10800"
  node2:
    <<: *ignite-def
    command: --node-name node2
    ports:
      - "10301:10300"
      - "10801:10800"
  node3:
    <<: *ignite-def
    command: --node-name node3
    ports:
      - "10302:10300"
      - "10802:10800"

configs:
  node_config:
    content: |
      ignite {
        network {
          port: 3344
          nodeFinder.netClusterNodes = ["node1:3344", "node2:3344", "node3:3344"]
        }
      }
```

Pembahasan:

| Bagian | Penjelasan |
|---|---|
| `name: ignite3` | Nama project Compose, sehingga container bernama `ignite3-node1-1`, dan network `ignite3_default`. |
| `x-ignite-def: &ignite-def` | Template bersama untuk ketiga node (DRY). |
| `image: apacheignite/ignite:3.1.0` | Image Apache Ignite 3.1.0. |
| `JVM_MAX_MEM`/`JVM_MIN_MEM: "4g"` | Heap JVM tiap node 4 GB. Perhatikan total memori VM (lihat catatan Colima di bagian 3.2). |
| `configs` + `node_config` | Membuat berkas konfigurasi node `/opt/ignite/etc/ignite-config.conf` dari isi inline. |
| `command: --node-name nodeN` | Memberi nama node (`node1`, `node2`, `node3`) yang nanti dipakai pada `--metastorage-group`. |
| `ports` | Memetakan REST API (10300) dan port client (10800) tiap node ke port host berbeda. |
| `network.port: 3344` | Port komunikasi antar-node (internal, tidak dipublikasikan ke host). |
| `nodeFinder.netClusterNodes` | Daftar alamat node untuk saling menemukan memakai nama service Compose. |

Pemetaan port (terbukti dari output `docker ps` di bawah):

| Node | REST API (admin/CLI) | Port aplikasi/client |
|---|---|---|
| node1 | 10300 | 10800 |
| node2 | 10301 | 10801 |
| node3 | 10302 | 10802 |

Untuk node2 dan node3, port internal container tetap 10300 dan 10800, tetapi dipetakan ke port host berbeda agar tidak bentrok.

### 5.2 File `schema.sql` (cadangan)

Bila `schema.sql` tidak ada atau kosong, berkas ini dapat dibuat manual:

```bash
[ -f sql/schema.sql ] || cat > sql/schema.sql <<'EOF'
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
```

Pembahasan konsep:

- `CREATE ZONE ... WITH replicas=N`: menentukan berapa salinan tiap partisi data. `Chinook` memakai 2 replika, `ChinookReplicated` memakai 3 (ada di semua node) dengan 25 partisi.
- `COLOCATE BY (...)`: menempatkan baris yang berelasi (misalnya `Album` dengan `Artist` berdasarkan `ArtistId`) pada node yang sama sehingga operasi *join* tidak perlu lintas jaringan.
- Tabel referensi kecil (`Genre`, `MediaType`) dibuat di zone dengan replika di semua node agar pembacaan selalu lokal.
- Pada praktikum, `schema.sql` asli dari Apache Ignite menghasilkan **20 baris** `Updated 0 rows.` (DDL tidak mengubah baris data). Versi cadangan di atas hanya berisi 19 pernyataan (2 zone + 11 tabel + 6 indeks), jadi isi file asli sedikit berbeda; gunakan file asli dari `sql.zip` bila ada.

### 5.3 `env.sh` untuk Ignite

```bash
cat > env.sh <<'EOF'
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dps="docker ps"

ignite_net() { docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' "$(docker compose ps -q node1)"; }

dcli() { docker run --rm -it --network="$(ignite_net)" -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 apacheignite/ignite:3.1.0 cli; }

dclm() { docker run --rm -it --network="$(ignite_net)" -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 -v "$PWD/sql:/opt/ignite/sql" apacheignite/ignite:3.1.0 cli; }
EOF

source env.sh
```

Perbedaan dengan modul dan alasannya:

| Modul | Versi di sini | Alasan |
|---|---|---|
| `--network=host` | `--network="$(ignite_net)"` | Di macOS/Windows, Docker berjalan di dalam VM sehingga `--network=host` merujuk ke jaringan VM, **bukan** ke host. CLI container tidak bisa menjangkau `localhost:10300`. Dengan bergabung ke network Compose, CLI dapat memakai nama service (`node1`, `node2`, `node3`). |
| alias `dclm`/`dcli` | fungsi shell | Nama network dicari dinamis lewat `docker inspect`, sehingga tidak perlu ditulis manual. |
| `-v ./sql:/opt/ignite/sql` | `-v "$PWD/sql:/opt/ignite/sql"` | Path absolut lebih andal untuk bind mount. |
| `sudo` | tanpa `sudo` | Tidak diperlukan pada Colima/Docker Desktop. |
| image `3.0.0` (pada beberapa bagian teks modul) | `3.1.0` | Modul mencampur 3.0.0 dan 3.1.0; yang digunakan adalah 3.1.0 sesuai judul bagian dan output CLI. |


> **Dukungan dari sumber resmi:** panduan resmi Apache Ignite memakai `--network=host` pada contoh Linux, sedangkan README repositori `apache/ignite-3` memakai `--net ignite3_default` lalu `connect http://node1:10300` untuk menjalankan CLI di dalam Docker. Pendekatan pada README ini mengikuti cara kedua karena lebih sesuai untuk macOS/Windows (lihat [R14] dan [R16]).

### 5.4 Menjalankan Cluster

```bash
dcu
sleep 10
dps
```

```text
[+] up 3/3
 ✔ Container ignite3-node3-1 Running  0.0s
 ✔ Container ignite3-node1-1 Running  0.0s
 ✔ Container ignite3-node2-1 Running  0.0s

CONTAINER ID   IMAGE                       COMMAND                  CREATED         STATUS         PORTS                                                                                    NAMES
146ea7478453   apacheignite/ignite:3.1.0   "docker-entrypoint.s…"   6 minutes ago   Up 4 minutes   0.0.0.0:10300->10300/tcp, [::]:10300->10300/tcp, 3344/tcp, 0.0.0.0:10800->10800/tcp, [::]:10800->10800/tcp   ignite3-node1-1
507990733c5b   apacheignite/ignite:3.1.0   "docker-entrypoint.s…"   6 minutes ago   Up 4 minutes   3344/tcp, 0.0.0.0:10301->10300/tcp, [::]:10301->10300/tcp, 0.0.0.0:10801->10800/tcp, [::]:10801->10800/tcp   ignite3-node2-1
5c33ba87703c   apacheignite/ignite:3.1.0   "docker-entrypoint.s…"   6 minutes ago   Up 4 minutes   3344/tcp, 0.0.0.0:10302->10300/tcp, [::]:10302->10300/tcp, 0.0.0.0:10802->10800/tcp, [::]:10802->10800/tcp   ignite3-node3-1
```

Mengetahui IP tiap node:

```bash
for n in node1 node2 node3; do
  echo -n "$n: "
  docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$(docker compose ps -q $n)"
done
```

```text
node1: 172.19.0.2
node2: 172.19.0.3
node3: 172.19.0.4
```

(Perintah modul memakai `<CONTAINER ID>` manual; di sini dipakai `docker compose ps -q <service>` agar otomatis.)

### 5.5 Inisialisasi Cluster

Masuk ke CLI **dengan mount SQL**:

```bash
dclm
```

Pada prompt pertama, jawab **`n`** bila CLI menawarkan koneksi ke `http://localhost:10300` (karena `localhost` di dalam container CLI bukan node Ignite), lalu hubungkan manual ke nama service:

```text
You appear to have not connected to any node yet. Do you want to connect to the default node http://localhost:10300? [Y/n] n

[disconnected]> connect http://node1:10300
Connected to http://node1:10300
The cluster is not initialized. Run cluster init command to initialize it.

[node1]> cluster init --name=ignite3 --metastorage-group=node1,node2,node3
Cluster was initialized successfully
```

Tunggu beberapa detik, lalu cek status:

```text
[node1]> cluster status
[name: ignite3, nodes: 3, status: active, cmgNodes: [node1, node2, node3], msNodes: [node1, node2, node3]]
```

Penjelasan:

- `--name=ignite3`: nama cluster.
- `--metastorage-group=node1,node2,node3`: node yang menyimpan metadata cluster (Meta Storage). Karena `--cluster-management-group` tidak diisi, node yang sama juga menjadi *Cluster Management Group* (`cmgNodes`). Memakai 3 node membuat metadata tetap tersedia walau 1 node mati (kuorum 2 dari 3).
- `status: active, nodes: 3`: seluruh node bergabung ke cluster.

Bila keluar CLI (Ctrl-D) lalu masuk lagi, **tidak perlu** inisialisasi ulang; cukup `connect http://node1:10300`.

### 5.6 Menjalankan File SQL

Di dalam CLI (yang sudah terhubung ke node1):

```text
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
(20 baris; DDL tidak mengubah baris data)

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
```

Urutan eksekusi penting: `schema.sql` harus pertama (membuat zone, tabel, indeks), baru file data.

Cek tabel yang terbentuk:

```text
[node1]> sql
sql-cli> SELECT * FROM system.tables WHERE schema = 'PUBLIC';
```

Keluaran lengkap:

```text
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
```

Ringkasan kolom utama:

| TABLE_NAME | TABLE_ID | ZONE_NAME | TABLE_COLOCATION_COLUMNS |
|---|---|---|---|
| ALBUM | 22 | CHINOOK | ARTISTID |
| ARTIST | 24 | CHINOOK | ARTISTID |
| CUSTOMER | 26 | CHINOOK | CUSTOMERID |
| EMPLOYEE | 28 | CHINOOK | EMPLOYEEID |
| GENRE | 30 | CHINOOKREPLICATED | GENREID |
| INVOICE | 32 | CHINOOK | CUSTOMERID |
| INVOICELINE | 34 | CHINOOK | INVOICEID |
| MEDIATYPE | 36 | CHINOOKREPLICATED | MEDIATYPEID |
| PLAYLIST | 38 | CHINOOK | PLAYLISTID |
| PLAYLISTTRACK | 40 | CHINOOK | PLAYLISTID, TRACKID |
| TRACK | 42 | CHINOOK | ALBUMID |

Terbentuk **11 tabel** di schema `PUBLIC`; hanya `GENRE` dan `MEDIATYPE` yang berada di zone `CHINOOKREPLICATED`.

### 5.7 Query Analytics

```sql
-- Monthly sales summary for the last 12 months
SELECT
    CAST(EXTRACT(YEAR FROM i.InvoiceDate) AS VARCHAR) || '-' ||
    CASE
        WHEN EXTRACT(MONTH FROM i.InvoiceDate) < 10
        THEN '0' || CAST(EXTRACT(MONTH FROM i.InvoiceDate) AS VARCHAR)
        ELSE CAST(EXTRACT(MONTH FROM i.InvoiceDate) AS VARCHAR)
    END AS YearMonth,
    COUNT(DISTINCT i.InvoiceId) AS InvoiceCount,
    COUNT(DISTINCT i.CustomerId) AS CustomerCount,
    SUM(i.Total) AS MonthlyRevenue,
    AVG(i.Total) AS AverageOrderValue
FROM
    Invoice i
GROUP BY
    EXTRACT(YEAR FROM i.InvoiceDate), EXTRACT(MONTH FROM i.InvoiceDate)
ORDER BY
    YearMonth DESC;
```

Penjelasan: query mengelompokkan faktur per tahun-bulan, membentuk label `YYYY-MM` (bulan di bawah 10 diberi awalan `0`), menghitung jumlah faktur dan pelanggan unik, total pendapatan, serta rata-rata nilai pesanan, lalu mengurutkan dari bulan terbaru.

> Meskipun komentarnya "last 12 months", query tidak memiliki klausa `WHERE`, jadi seluruh data (Jan 2020 - Des 2024, **60 bulan**) ikut ditampilkan.

Keluaran lengkap (60 baris, Des 2024 sampai Jan 2020):

```text
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
```

### 5.8 Membuktikan Replikasi Master-Master

Data dimasukkan **hanya melalui node1**. Untuk membuktikan data juga ada di node lain, hubungkan CLI ke node2 dan node3 lalu jalankan query yang sama.

```text
[node1]> connect http://node2:10300
You are already connected to the http://node1:10300, do you want to connect to the http://node2:10300? [Y/n] Y
Connected to http://node2:10300

[node2]> sql
sql-cli> SELECT COUNT(*) FROM Track;
sql-cli> SELECT * FROM system.tables WHERE schema = 'PUBLIC';
sql-cli> -- jalankan query analytics di atas
```

```text
[node2]> connect http://node3:10300
You are already connected to the http://node2:10300, do you want to connect to the http://node3:10300? [Y/n] Y
Connected to http://node3:10300

[node3]> sql
sql-cli> -- jalankan query analytics di atas
```

Hasil query analytics di node2 dan node3 **identik** dengan hasil di node1 (misalnya `2024-12 | 7 | 7 | 38.62 | 5.5171428571428571`). Ini membuktikan semua node melayani data yang sama.

> Dari host (tanpa container CLI), node bisa diakses lewat port yang dipetakan: `http://localhost:10300`, `http://localhost:10301`, dan `http://localhost:10302` (REST/CLI), serta `10800-10802` untuk koneksi aplikasi/driver.

**Uji tulis di node lain (membuktikan sifat Master-Master):**

```text
[node3]> sql
sql-cli> INSERT INTO Artist (ArtistId, Name) VALUES (99999, 'Artis Uji Node3');
sql-cli> exit

[node3]> connect http://node1:10300
[node1]> sql
sql-cli> SELECT * FROM Artist WHERE ArtistId = 99999;
```

Baris yang ditulis lewat node3 akan terbaca dari node1.

### 5.9 Mematikan Cluster

```bash
dcd
```

```text
[+] down 4/4
 ✔ Container ignite3-node2-1     Removed
 ✔ Container ignite3-node1-1     Removed
 ✔ Container ignite3-node3-1     Removed
 ✔ Network ignite3_default       Removed
```

---

## 6. Perbandingan Kedua Model Replikasi

| Aspek | PostgreSQL Streaming Replication | Apache Ignite 3 |
|---|---|---|
| Model | Single-primary (primary-replica) | Multi-node, semua node dapat baca/tulis |
| Penulisan | Hanya di primary | Dapat lewat node mana pun |
| Replica | Read-only (`pg_is_in_recovery() = t`) | Semua node aktif |
| Unit replikasi | Seluruh cluster database (WAL fisik) | Partisi data per zone (`replicas`, `partitions`) |
| Konsistensi | Asinkron (ada kemungkinan lag) | Konsensus Raft per partisi (konsistensi kuat) |
| Failover | Manual (`pg_promote()`) atau via tool eksternal | Otomatis oleh cluster selama kuorum terpenuhi |
| Risiko utama | Data terakhir bisa hilang saat failover asinkron; split-brain bila primary lama kembali | Butuh mayoritas node tersedia (kuorum) |
| Cocok untuk | OLTP klasik, pemisahan beban baca | Data terdistribusi, throughput tinggi, komputasi in-memory |

---

## 7. Rangkuman Error dan Solusinya

Berikut error nyata yang terjadi selama pengerjaan beserta penyebab dan perbaikannya.

### 7.1 `zsh: command not found: dcu` / `dps`

```text
danel@1111QD-rs ~ % dcu
zsh: command not found: dcu
```

**Penyebab:** alias di `env.sh` belum dimuat ke shell, atau dijalankan dari terminal baru/direktori lain. Alias hanya berlaku di sesi shell tempat `source` dijalankan.

**Solusi:**

```bash
cd ~/streaming-replication
source env.sh
```

Agar permanen, tambahkan baris `source ~/streaming-replication/env.sh` ke `~/.zshrc` (atau `~/.bashrc`).

### 7.2 `failed to connect to the docker API at unix:///Users/.../.colima/default/docker.sock`

```text
failed to connect to the docker API at unix:///Users/danel/.colima/default/docker.sock; check if the path is correct and if the daemon is running: dial unix ... connect: no such file or directory
```

**Penyebab:** VM Colima belum berjalan atau belum siap, sehingga socket Docker belum ada. (Terminal baru dibuka sebelum `colima start` selesai.)

**Solusi:**

```bash
colima status          # cek status
colima start           # jalankan bila mati
docker context ls      # pastikan context 'colima' aktif
docker ps              # tes koneksi
```

Setelah `colima start` selesai dan `docker ps` berhasil, ulangi `dcu`.

### 7.3 `/opt/homebrew/bin/brew: no such file or directory` saat membuka terminal

```text
/Users/danel/.zshrc:27: no such file or directory: /opt/homebrew/bin/brew
/Users/danel/.zshrc:28: no such file or directory: /opt/homebrew/bin/brew
```

**Penyebab:** `~/.zshrc` memanggil `brew shellenv`, tetapi Homebrew tidak terpasang di `/opt/homebrew`.

**Solusi (pilih salah satu):**

```bash
# a) Pasang Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# b) Atau hapus/komentari baris 27-28 di ~/.zshrc
nano ~/.zshrc
```

Pesan ini tidak menghalangi Docker, tetapi mengotori setiap sesi terminal.

### 7.4 `bash: docker: command not found` di dalam container

```text
danel@1111QD-rs streaming-replication % dep
f1253648b62a:/$ docker compose stop postgres_primary
bash: docker: command not found
```

**Penyebab:** alias `dep` membuka shell **di dalam container primary**. Perintah `docker compose ...` hanya ada di host, bukan di dalam container.

**Solusi:** keluar dari container dengan `exit`, lalu jalankan perintah `docker compose` dari terminal host. Atau jalankan langsung tanpa masuk shell:

```bash
docker compose exec postgres_primary psql -U zuser -d zdb -c "SELECT 1;"
```

### 7.5 Replica gagal `pg_basebackup` (connection refused) saat primary belum siap

```text
pg_basebackup: error: connection to server at "postgres_primary" (172.18.0.2), port 5432 failed: Connection refused
	Is the server running on that host and accepting TCP/IP connections?
pg_basebackup failed. Retrying in 5 seconds ...
```

**Penyebab:** replica start lebih cepat dari primary (versi modul memakai `depends_on` sederhana yang hanya menunggu container *dibuat*, bukan *siap*).

**Solusi:**

- Loop `until ... sleep 5` mengulang otomatis sampai berhasil (sudah ada di compose).
- `depends_on` dengan `condition: service_healthy` menunggu primary benar-benar `healthy`.
- Bila terus gagal, periksa `docker compose logs postgres_primary` dan pastikan `00_init.sql` terpasang dan user `replicator` ada.

### 7.6 Replica error saat di-restart (`directory ... exists but is not empty`)

**Penyebab:** `pg_basebackup` dijalankan lagi pada direktori data yang sudah terisi.

**Solusi:** dicegah dengan pengecekan `if [ ! -s "$$PGDATA/PG_VERSION" ]`. Untuk mengulang dari nol sepenuhnya:

```bash
docker compose down -v
docker compose up -d --wait
```

### 7.7 `FATAL: data directory has invalid permissions`

**Penyebab:** direktori data harus berizin `0700`.

**Solusi:** `chmod 0700 "$$PGDATA"` sebelum `exec postgres` (sudah ada di compose).

### 7.8 `ERROR: cannot execute INSERT in a read-only transaction`

```text
ERROR:  cannot execute INSERT in a read-only transaction
```

**Ini bukan bug**, melainkan perilaku yang diharapkan: replica read-only. Tulis data di primary (port 5432), atau promosikan replica dengan `pg_promote()` bila primary mati.

### 7.9 Ignite: `Unmatched arguments from index 2: 'cluster', 'init', ...`

```text
[disconnected]> connect http://node1:10300
> cluster init --name=ignite3 --metastorage-group=node1,node2,node3
> cluster status
Unmatched arguments from index 2: 'cluster', 'init', '--name=ignite3', ...
```

**Penyebab:** beberapa baris perintah ditempel sekaligus. CLI menganggap baris-baris berikutnya sebagai **argumen tambahan** dari `connect`.

**Solusi:** jalankan **satu perintah per baris**, tunggu hasil, baru perintah berikutnya.

### 7.10 Ignite: `Missing required option: '--name=<clusterName>'`

```text
[node1]> cluster init --cluster-name=ignite3_cluster --meta-storage-node=node1 --meta-storage-node=node2 --meta-storage-node=node3
Missing required option: '--name=<clusterName>'
```

**Penyebab:** nama opsi salah. Pada Ignite 3.1.0 yang benar adalah `--name` dan `--metastorage-group`, bukan `--cluster-name` / `--meta-storage-node`.

**Solusi:**

```text
cluster init --name=ignite3 --metastorage-group=node1,node2,node3
```

Gunakan `cluster init --help` untuk melihat opsi yang sesuai versi.

### 7.11 Ignite: `cluster status` menampilkan `[nodes: N/A, status: not initialized]` tepat setelah init

```text
[node1]> cluster init --name=ignite3 --metastorage-group=node1,node2,node3
Cluster was initialized successfully
[node1]> cluster status
[nodes: N/A, status: not initialized]
```

**Penyebab:** inisialisasi berjalan asinkron; status belum diperbarui saat dicek terlalu cepat.

**Solusi:** tunggu beberapa detik lalu ulangi `cluster status` sampai muncul `status: active`. **Jangan** menjalankan `cluster init` berulang kali dengan opsi lain.

### 7.12 Ignite CLI tidak bisa terhubung ke `localhost:10300` (macOS/Windows)

**Penyebab:** `--network=host` pada Docker berbasis VM tidak berbagi jaringan dengan host, jadi `localhost` di dalam container CLI bukan node Ignite.

**Solusi:** jawab `n` pada tawaran koneksi default, bergabung ke network Compose (lihat `env.sh`), dan hubungkan memakai nama service:

```text
connect http://node1:10300
```

### 7.13 Ignite: salah menimpa perintah `exit` dan `connect`

```text
sql-cli> exit
> connect http://node2:10300
> exit;
...
Unmatched arguments from index 1: 'connect', 'http://node2:10300', ...
```

**Penyebab:** `exit` pada mode SQL hanya keluar dari mode SQL, dan perintah yang ditempel berderet ikut terbaca sebagai argumen `exit`.

**Solusi:** keluar mode SQL dengan `exit`, tunggu kembali ke prompt `[nodeX]>`, lalu ketik `connect ...` sebagai perintah terpisah.

### 7.14 `sql.zip` berisi file sampah macOS (`__MACOSX`, `._*.sql`)

**Penyebab:** arsip dibuat di macOS dan menyertakan metadata.

**Solusi:** filter saat menyalin, seperti pada perintah `find ... -not -path '*__MACOSX*' -not -name '._*'`.

### 7.15 Port sudah dipakai (`address already in use`)

**Solusi:**

```bash
lsof -i :5432          # lihat proses yang memakai port
```

Matikan PostgreSQL lokal yang berjalan, atau ubah pemetaan port di compose (misalnya `5434:5432`).

---

## 8. Perintah Lanjutan dan Berguna

### Docker / Compose

```bash
docker compose ps                         # status service
docker compose logs -f postgres_primary   # log real-time
docker compose restart postgres_replica   # restart satu service
docker compose config                     # validasi dan tampilkan compose final
docker compose down -v                    # hapus container + volume (reset total)
docker stats                              # pemakaian CPU/RAM
docker system prune -f                    # bersihkan resource tak terpakai
```

### PostgreSQL - Pemantauan Replikasi

```sql
-- Di primary: daftar replica dan lag
SELECT application_name, state, sync_state,
       sent_lsn, replay_lsn,
       pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
FROM pg_stat_replication;

-- Di primary: slot dan WAL yang ditahan
SELECT slot_name, active, restart_lsn, wal_status FROM pg_replication_slots;

-- Di replica: status penerimaan WAL
SELECT status, receive_start_lsn, written_lsn, flushed_lsn, sender_host, slot_name FROM pg_stat_wal_receiver;

-- Di replica: posisi replay dan waktu transaksi terakhir
SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn(), pg_last_xact_replay_timestamp();

-- Peran node saat ini
SELECT pg_is_in_recovery();
```

### Uji Lag Replikasi

```bash
# Tulis banyak baris di primary
docker compose exec postgres_primary psql -U zuser -d zdb -c \
 "INSERT INTO testrep SELECT g, 'baris-' || g FROM generate_series(1000, 101000) g;"

# Bandingkan jumlah baris di kedua node
docker compose exec postgres_primary psql -U zuser -d zdb -tc "SELECT count(*) FROM testrep;"
docker compose exec postgres_replica psql -U zuser -d zdb -tc "SELECT count(*) FROM testrep;"
```

### Terhubung dari Host dengan `psql`

```bash
psql "postgresql://zuser:zpass@localhost:5432/zdb"   # primary
psql "postgresql://zuser:zpass@localhost:5433/zdb"   # replica
```

### Mengubah Replikasi Menjadi Sinkron (opsional)

Di primary, tambahkan parameter `-c synchronous_standby_names='walreceiver'` pada `command`, lalu cek `sync_state` pada `pg_stat_replication` (akan menjadi `sync`). Konsekuensinya: commit di primary menunggu konfirmasi replica, sehingga konsistensi lebih kuat tetapi latensi tulis naik, dan primary akan **tertahan** bila replica mati.

### Membangun Ulang Primary Lama sebagai Replica

```bash
# Contoh konsep: primary lama menjadi replica dari primary baru
pg_basebackup --pgdata=/var/lib/postgresql/18/docker -R \
  --host=<primary_baru> --port=5432 -X stream
```

### Apache Ignite - Perintah CLI Berguna

```text
cluster status                 # status cluster
cluster topology physical      # daftar node fisik
cluster topology logical       # daftar node logis
node status                    # status node yang terhubung
sql "SELECT COUNT(*) FROM Track"        # query satu baris
sql --file=/opt/ignite/sql/file.sql     # jalankan file
connect http://node2:10300              # pindah node
help                                    # daftar perintah
```

```sql
-- Zone dan konfigurasinya
SELECT * FROM system.zones;

-- Distribusi partisi (jika tersedia pada versi ini)
SELECT * FROM system.zone_partition_states;
```

> Nama tabel/view `system.*` dapat berbeda antar versi. Gunakan `SELECT * FROM system.tables` dan dokumentasi Ignite 3.1.0 sebagai acuan.

### Uji Ketahanan Ignite (Fault Tolerance)

```bash
docker compose stop node3          # matikan satu node
```

Lalu dari CLI terhubung ke node1/node2, jalankan `SELECT COUNT(*) FROM Track;` dan `cluster status`. Cluster tetap melayani karena kuorum (2 dari 3) masih ada. Hidupkan kembali dengan:

```bash
docker compose start node3
```

---

## 9. Kesimpulan

1. **Streaming replication PostgreSQL 18.3** berhasil dikonfigurasi dengan Docker Compose. Tabel `testrep` dan datanya di primary tereplikasi ke replica, yang dibuktikan oleh `pg_stat_replication` (`state = streaming`, `sync_state = async`), `pg_replication_slots` (slot fisik aktif), dan `pg_is_in_recovery() = t` pada replica.
2. Replica bersifat **read-only** (penulisan ditolak dengan `cannot execute INSERT in a read-only transaction`), sehingga cocok untuk menyebar beban baca.
3. **Failover manual** berhasil: setelah primary dihentikan, `pg_promote()` mengubah replica menjadi primary (`pg_is_in_recovery()` berubah dari `t` ke `f`) dan operasi tulis kembali berfungsi.
4. **Cluster Apache Ignite 3.1.0** dengan 3 node berhasil diinisialisasi (`status: active, nodes: 3`). Data diisi lewat node1 dan dapat dibaca dari node lain, sehingga model **Master-Master** terbukti.
5. Beberapa penyesuaian diperlukan agar modul berjalan di macOS/Colima: memakai `docker compose` (v2), tidak memakai `sudo`, bergabung ke network Compose alih-alih `--network=host`, dan menambahkan *healthcheck-based dependency* serta pengecekan `PG_VERSION` pada replica.

---

## 10. Struktur Repositori

Struktur repositori `prak-dis-dec` setelah semua berkas ditambahkan:

```text
prak-dis-dec/
├── README.md                          <- indeks repositori + cara unggah
├── .gitignore
└── 04/
    ├── README.md                      <- dokumen ini
    ├── 01-Docker terinstal            <- bukti instalasi Docker (milik Anda)
    ├── 02-Streaming Replication Menggunakan PostgreSQL.sql   <- log sesi terminal asli (milik Anda)
    ├── streaming-replication/
    │   ├── 00_init.sql
    │   ├── docker-compose.yaml        <- versi yang dipakai (compose v2, healthcheck)
    │   ├── docker-compose.module.yaml <- versi asli modul
    │   ├── env.sh                     <- alias versi yang dipakai
    │   ├── env.module.sh              <- alias asli modul (sudo, docker-compose)
    │   └── scripts/
    │       ├── 00-up.sh
    │       ├── 01-status.sh
    │       ├── 02-test-replication.sh
    │       ├── 03-failover.sh
    │       ├── 04-lag-test.sh
    │       ├── 99-cleanup.sh
    │       └── run-all.sh             <- jalankan semua + simpan log
    ├── ignite3/
    │   ├── docker-compose.yml
    │   ├── env.sh
    │   ├── env.module.sh
    │   ├── sql/                       <- isi diunduh dengan scripts/get-sql.sh
    │   │   └── README.md
    │   └── scripts/
    │       ├── get-sql.sh
    │       ├── 01-up.sh
    │       ├── cli-commands.txt
    │       └── 99-cleanup.sh
    └── outputs/
        ├── modul/                     <- output pembanding dari modul
        │   ├── postgres-modul-output.txt
        │   └── ignite-modul-output.txt
        └── praktikum/                 <- output hasil praktikum sendiri
            └── README.md
```

> Pada repositori Anda saat ini, berkas PostgreSQL berada di `04/utdi/modul4/streaming-replication`. Boleh dipertahankan; yang penting jalur relatif di dalam setiap folder (`scripts/`, `env.sh`, `docker-compose.yaml`) tetap sama.

---

## 11. Lampiran A - Log Terminal Lengkap

Berikut isi log sesi terminal asli (berkas `02-Streaming Replication Menggunakan PostgreSQL.sql` di repositori), sebanyak tiga sesi. Baris kosong dihilangkan dan indentasi YAML dirapikan agar terbaca; isi perintah dan keluarannya tidak diubah.

### A.1 Sesi 1 - Menyalakan Colima (alias belum dimuat)

```text
Last login: Fri Oct 23 13:15:09 on ttys000
/Users/danel/.zshrc:27: no such file or directory: /opt/homebrew/bin/brew
/Users/danel/.zshrc:28: no such file or directory: /opt/homebrew/bin/brew
danel@1111QD-rs ~ % colima start
INFO[0001] starting colima
INFO[0001] runtime: docker
INFO[0002] starting ... context=vm
INFO[0031] provisioning ... context=docker
INFO[0037] starting ... context=docker
INFO[0040] done
danel@1111QD-rs ~ % dcu
zsh: command not found: dcu
danel@1111QD-rs ~ % dps
zsh: command not found: dps
```

### A.2 Sesi 2 - PostgreSQL Streaming Replication

```text
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
 ✔ Network streaming-replication_default              Created 0.1s
 ✔ Container streaming-replication-postgres_primary-1 Healthy 12.3s
 ✔ Container streaming-replication-postgres_replica-1 Healthy 22.1s
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
 ✔ Container streaming-replication-postgres_primary-1 Stopped 0.3s
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
 ✔ Container streaming-replication-postgres_replica-1 Removed 0.3s
 ✔ Container streaming-replication-postgres_primary-1 Removed 0.1s
 ✔ Network streaming-replication_default              Removed 0.1s
danel@1111QD-rs streaming-replication % dps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

### A.3 Sesi 3 - Apache Ignite 3.1.0

```text
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
current_catalog.sql  ee_and_cust.sql  invoices.sql  media_and_genre.sql  schema.sql  tracks.sql

danel@1111QD-rs ignite3 % (perintah yang sama dijalankan ulang)
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
100  1553  100  1553    0     0  16312      0 --:--:-- --:--:-- --:--:-- 16177
100  134k  100  134k    0     0   890k      0 --:--:-- --:--:-- --:--:--  893k
Archive:  sql.zip
   creating: /Users/danel/ignite3/sql_tmp/sql
  inflating: sql_tmp/sql/current_catalog.sql
  inflating: sql_tmp/sql/ee_and_cust.sql
  inflating: sql_tmp/sql/invoices.sql
  inflating: sql_tmp/sql/media_and_genre.sql
  inflating: sql_tmp/sql/schema.sql
  inflating: sql_tmp/sql/tracks.sql
current_catalog.sql  docker-compose.yml  ee_and_cust.sql  invoices.sql  media_and_genre.sql  schema.sql  tracks.sql

danel@1111QD-rs ignite3 % [ -f sql/schema.sql ] || cat > sql/schema.sql <<'EOF'
(isi schema.sql cadangan, lihat bagian 5.2)
EOF
danel@1111QD-rs ignite3 % cat > env.sh <<'EOF'
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dps="docker ps"
ignite_net() { docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' "$(docker compose ps -q node1)"; }
dcli() { docker run --rm -it --network="$(ignite_net)" -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 apacheignite/ignite:3.1.0 cli; }
dclm() { docker run --rm -it --network="$(ignite_net)" -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 -v "$PWD/sql:/opt/ignite/sql" apacheignite/ignite:3.1.0 cli; }
EOF
danel@1111QD-rs ignite3 % source env.sh
danel@1111QD-rs ignite3 % dcu
sleep 10
dps
[+] up 3/3
 ✔ Container ignite3-node3-1 Running 0.0s
 ✔ Container ignite3-node1-1 Running 0.0s
 ✔ Container ignite3-node2-1 Running 0.0s
CONTAINER ID   IMAGE                       COMMAND                  CREATED         STATUS         PORTS                                                                                      NAMES
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

 #                    ___                     __
 ###                 /   |  ____  ____ _ _____/ /_  ___
 #  #####           / /| | / __ \/ __ `// ___/ __ \/ _ \
 ###  ######       / ___ |/ /_/ / /_/ // /__/ / / /  __/
 #####  #######   /_/  |_/ .___/\__,_/ \___/_/ /_/\___/
 #######  ######        /_/
 ########  ####        ____            _ __          _____
 #  ########  ##       /  _/___ _____  (_) /____     |__  /
 ####  #######  #      / // __ `/ __ \/ / __/ _ \     /_ <
 #####  #####       _/ // /_/ / / / / / /_/  __/   ___/ /
 ####  ##           /___/\__, /_/ /_/_/\__/\___/   /____/
 ##                      /____/

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
* <nodeUrl>  URL of a node that will be used as a communication endpoint. It can be any node URL. If not set, then the default URL from the profile settings will be used

OPTIONS * - required option
* -u, --username=<username>
        Username to connect to cluster
* -p, --password=<password>
        Password to connect to cluster
  -h, --help         Show help for the specified command
  -v, --verbose      Show additional information: logs, REST calls. This flag is useful for debugging. Specify multiple options to increase verbosity for REST calls. Single option shows request and response, second option (-vv) shows headers, third one (-vvv) shows body

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
* --name=<clusterName>  Human-readable name of the cluster
  --metastorage-group=<node name>[,<node name>...]
        Metastorage group nodes (use comma-separated list of node names '--metastorage-group node1, node2' to specify more than one node) that will host the Meta Storage. If the --cluster-management-group option is omitted, the same nodes will also host the Cluster Management Group.
  --cluster-management-group=<node name>[,<node name>...]
        Names of nodes (use comma-separated list of node names '--cluster-management-group node1, node2' to specify more than one node) that will host the Cluster Management Group. If omitted, then --metastorage-group values will also supply the nodes for the Cluster Management Group.
  --config=<config>  Cluster configuration that will be applied during the cluster initialization
  --config-files=<file path>[,<file path>...]
        Path to cluster configuration files (use comma-separated list of paths '--config-files path1, path2' to specify more than one file)
  --url=<clusterUrl> URL of cluster endpoint. It can be any node URL.If not set, then the default URL from the profile settings will be used
  -h, --help         Show help for the specified command
  -v, --verbose      Show additional information: logs, REST calls. This flag is useful for debugging. Specify multiple options to increase verbosity for REST calls. Single option shows request and response, second option (-vv) shows headers, third one (-vvv) shows body

[node1]> cluster status
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
(keluaran tabel system.tables: lihat bagian 5.6)
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
  -h, --help         Show help for the specified command
  -v, --verbose      Show additional information: logs, REST calls. This flag is useful for debugging. Specify multiple options to increase verbosity for REST calls. Single option shows request and response, second option (-vv) shows headers, third one (-vvv) shows body

sql-cli> SELECT
> CAST(EXTRACT(YEAR FROM i.InvoiceDate) AS VARCHAR) || '-' ||
> CASE
>   WHEN EXTRACT(MONTH FROM i.InvoiceDate) < 10
>   THEN '0' || CAST(EXTRACT(MONTH FROM i.InvoiceDate) AS VARCHAR)
>   ELSE CAST(EXTRACT(MONTH FROM i.InvoiceDate) AS VARCHAR)
> END AS YearMonth,
> COUNT(DISTINCT i.InvoiceId) AS InvoiceCount,
> COUNT(DISTINCT i.CustomerId) AS CustomerCount,
> SUM(i.Total) AS MonthlyRevenue,
> AVG(i.Total) AS AverageOrderValue
> FROM
> Invoice i
> GROUP BY
> EXTRACT(YEAR FROM i.InvoiceDate), EXTRACT(MONTH FROM i.InvoiceDate)
> ORDER BY
> YearMonth DESC;
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
```

> Pada log asli, tabel `system.tables` (A.3) ditampilkan lengkap dengan 15 kolom; versi lengkapnya ada pada bagian 5.6. Catatan: dalam log, baris `exit` / `connect http://node2:10300` yang ditempel berderet tertelan sebagai argumen perintah `exit` (lihat error 7.13), sehingga query analytics terakhir tercatat tanpa penanda node yang jelas. Ulangi langkah 5.8 satu per satu untuk node2 dan node3 bila ingin bukti per node.

---

## 12. Lampiran B - Output Pembanding dari Modul

Bagian ini memuat output yang ditampilkan **pada modul** (dijalankan oleh penulis modul di Linux). Gunakan sebagai pembanding terhadap hasil praktikum Anda. Nilai seperti ID container, IP, PID, dan LSN akan berbeda pada setiap eksekusi; yang harus sama adalah **pola dan statusnya** (`healthy`, `streaming`, `async`, `t`/`f`, `Updated N rows`, `status: active`).

Berkas yang sama tersimpan di repositori: `04/outputs/modul/postgres-modul-output.txt` dan `04/outputs/modul/ignite-modul-output.txt`.

### 12.1 Output Modul - PostgreSQL (4.1)

```text
# OUTPUT DARI MODUL 4 - Bagian 4.1 (PostgreSQL Streaming Replication)
# Sumber: modul-04.pdf (Dr. Bambang Purnomosidi D. P.), dijalankan di Linux (host NEO-X),
# direktori kerja "src", sehingga nama container berawalan "src-".
# Transkripsi dari tangkapan layar modul; bagian yang terpotong di tangkapan layar ditandai (terpotong).

############ Halaman 4 - ls -la, dcu ############
$ ls -la
total 12
drwxr-xr-x 2 bpdp bpdp   66 Apr 12 16:31 .
drwxr-xr-x 3 bpdp bpdp  112 Apr 12 16:25 ..
-rw-r--r-- 1 bpdp bpdp  146 Oct 25 15:14 00_init.sql
-rw-r--r-- 1 bpdp bpdp 1424 Apr 12 16:31 docker-compose.yaml
-rw-r--r-- 1 bpdp bpdp  330 Oct 25 21:19 env.sh
$ dcu
bash: dcu: command not found
$ source env.sh
$ dcu
[sudo] password for bpdp:
[+] up 15/15
 v Image postgres:18.3-alpine3.23   Pulled
 v Network src_default              Created
 v Container src-postgres_primary-1 Started
 v Container src-postgres_replica-1 Started

############ Halaman 4 - dps ############
$ dps
[sudo] password for bpdp:
CONTAINER ID   IMAGE                      COMMAND                  CREATED         STATUS                   PORTS                                         NAMES
225df898488e   postgres:18.3-alpine3.23   "docker-entrypoint.s..."   4 minutes ago   Up 4 minutes (healthy)   0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp   src-postgres_replica-1
492a2b3bc3db   postgres:18.3-alpine3.23   "docker-entrypoint.s..."   4 minutes ago   Up 4 minutes (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp   src-postgres_primary-1

############ Halaman 5 - dlr (log replica) ############
$ dlr
pg_basebackup: error: connection to server at "postgres_primary" (172.18.0.2), port 5432 failed: Conne... (terpotong)
        Is the server running on that host and accepting TCP/IP connections?
pg_basebackup failed. Retrying in 5 seconds ...
Backup done, starting replica...
2026-04-12 09:39:53.916 UTC [1] LOG:  starting PostgreSQL 18.3 on x86_64-pc-linux-musl, compiled by gc... (terpotong)
2026-04-12 09:39:53.916 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2026-04-12 09:39:53.916 UTC [1] LOG:  listening on IPv6 address "::", port 5432
2026-04-12 09:39:53.920 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2026-04-12 09:39:53.926 UTC [17] LOG:  database system was interrupted; last known up at 2026-04-12 09... (terpotong)
2026-04-12 09:39:54.512 UTC [17] LOG:  starting backup recovery with redo LSN 0/2000028, checkpoint LS... (terpotong)
2026-04-12 09:39:54.512 UTC [17] LOG:  entering standby mode
2026-04-12 09:39:54.521 UTC [17] LOG:  redo starts at 0/2000028
2026-04-12 09:39:54.523 UTC [17] LOG:  completed backup recovery with redo LSN 0/2000028 and end LSN 0... (terpotong)
2026-04-12 09:39:54.524 UTC [17] LOG:  consistent recovery state reached at 0/2000120
2026-04-12 09:39:54.524 UTC [1] LOG:  database system is ready to accept read-only connections
2026-04-12 09:39:54.558 UTC [18] LOG:  started streaming WAL from primary at 0/3000000 on timeline 1
2026-04-12 09:45:09.048 UTC [15] LOG:  restartpoint starting: time
2026-04-12 09:45:13.336 UTC [15] LOG:  restartpoint complete: wrote 42 buffers (0.3%), wrote 2 SLRU bu... (terpotong)
c=0.012 s, total=4.288 s; sync files=10, longest=0.006 s, average=0.002 s; distance=16701 kB, estimate... (terpotong)
2026-04-12 09:45:13.336 UTC [15] LOG:  recovery restart point at 0/304F530
2026-04-12 09:45:13.336 UTC [15] DETAIL:  Last completed transaction was at log time 2026-04-12 09:40:... (terpotong)

############ Halaman 6 - pg_stat_replication (primary) ############
$ dep
492a2b3bc3db:/$ psql -U zuser -d zdb
psql (18.3)
Type "help" for help.

zdb=# \x
Expanded display is on.
zdb=# SELECT * FROM pg_stat_replication;
-[ RECORD 1 ]----+------------------------------
pid              | 59
usesysid         | 16385
usename          | replicator
application_name | walreceiver
client_addr      | 172.18.0.3
client_hostname  |
client_port      | 41068
backend_start    | 2026-04-12 09:39:54.538716+00
backend_xmin     |
state            | streaming
sent_lsn         | 0/304F670
write_lsn        | 0/304F670
flush_lsn        | 0/304F670
replay_lsn       | 0/304F670
write_lag        |
flush_lag        |
replay_lag       |
sync_priority    | 0
sync_state       | async
reply_time       | 2026-04-12 10:01:05.746394+00

############ Halaman 7 - pg_replication_slots (primary) ############
zdb=# SELECT * FROM pg_replication_slots;
-[ RECORD 1 ]-------+-----------------
slot_name           | replication_slot
plugin              |
slot_type           | physical
datoid              |
database            |
temporary           | f
active              | t
active_pid          | 59
xmin                |
catalog_xmin        |
restart_lsn         | 0/304F670
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

############ Halaman 8 - status di replica ############
$ der
[sudo] password for bpdp:
225df898488e:/$ psql -U zuser -d zdb
psql (18.3)
Type "help" for help.

zdb=# SELECT pg_is_in_recovery();
 pg_is_in_recovery
-------------------
 t
(1 row)

############ Halaman 8-9 - sebelum pembuatan tabel ############
-- primary
zdb=# \dt
Did not find any tables.
-- replica
zdb=# \dt
Did not find any tables.

############ Halaman 9 - manipulasi data pada primary ############
zdb=# CREATE TABLE testrep (first INT, second VARCHAR(15));
CREATE TABLE
zdb=# SELECT * FROM testrep;
 first | second
-------+--------
(0 rows)

zdb=# INSERT INTO testrep (first, second) VALUES (21, 'Test pertama');
INSERT 0 1
zdb=# INSERT INTO testrep (first, second) VALUES (23, 'Test ke dua');
INSERT 0 1
zdb=# SELECT * FROM testrep;
 first |    second
-------+--------------
    21 | Test pertama
    23 | Test ke dua
(2 rows)

############ Halaman 10 - hasil di replica ############
zdb=# \dt
Did not find any tables.
zdb=# \dt
        List of tables
 Schema |  Name   | Type  | Owner
--------+---------+-------+-------
 public | testrep | table | zuser
(1 row)

zdb=# SELECT * FROM testrep;
 first |    second
-------+--------------
    21 | Test pertama
    23 | Test ke dua
(2 rows)

############ Halaman 11 - High Availability ############
$ sudo docker-compose stop postgres_primary
[+] stop 1/1
 v Container src-postgres_primary-1 Stopped

zdb=# SELECT pg_is_in_recovery();
 pg_is_in_recovery
-------------------
 t
(1 row)

zdb=# SELECT pg_promote();
 pg_promote
------------
 t
(1 row)

zdb=# SELECT pg_is_in_recovery();
 pg_is_in_recovery
-------------------
 f
(1 row)

############ Halaman 12 - mematikan semua ############
$ dcd
[sudo] password for bpdp:
[+] down 3/3
 v Container src-postgres_replica-1 Removed
 v Container src-postgres_primary-1 Removed
 v Network src_default              Removed
$ dps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

### 12.2 Output Modul - Apache Ignite (4.2)

```text
# OUTPUT DARI MODUL 4 - Bagian 4.2 (Replikasi Master-Master Apache Ignite 3.1.0)
# Sumber: modul-04.pdf (Dr. Bambang Purnomosidi D. P.), Linux (host NEO-X).
# Transkripsi dari tangkapan layar modul.

############ Halaman 13 - dcu ############
$ dcu
[+] up 4/4
 v Network ignite3_default   Created
 v Container ignite3-node3-1 Started
 v Container ignite3-node2-1 Started
 v Container ignite3-node1-1 Started

############ Halaman 13 - dps (setelah up) ############
$ dps
CONTAINER ID   IMAGE                       COMMAND                  CREATED            STATUS            PORTS                                                                                      NAMES
b919e7f7a5f1   apacheignite/ignite:3.1.0   "docker-entrypoint.s..."   35 seconds ago   Up 35 seconds   3344/tcp, 0.0.0.0:10302->10300/tcp, [::]:10302->10300/tcp, 0.0.0.0:10802->10800/tcp, [::]:10802->10800/tcp   ignite3-node3-1
89a4b38d084a   apacheignite/ignite:3.1.0   "docker-entrypoint.s..."   35 seconds ago   Up 35 seconds   3344/tcp, 0.0.0.0:10301->10300/tcp, [::]:10301->10300/tcp, 0.0.0.0:10801->10800/tcp, [::]:10801->10800/tcp   ignite3-node2-1
d42c1d0eb1e7   apacheignite/ignite:3.1.0   "docker-entrypoint.s..."   35 seconds ago   Up 35 seconds   0.0.0.0:10300->10300/tcp, [::]:10300->10300/tcp, 3344/tcp, 0.0.0.0:10800->10800/tcp, [::]:10800->10800/tcp   ignite3-node1-1

############ Halaman 14 - IP tiap node dan ping ############
$ sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' b919e7f7a5f1
172.18.0.4
$ sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 89a4b38d084a
172.18.0.3
$ sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' d42c1d0eb1e7
172.18.0.2

$ ping 172.18.0.2
PING 172.18.0.2 (172.18.0.2) 56(84) bytes of data.
64 bytes from 172.18.0.2: icmp_seq=1 ttl=64 time=0.106 ms
64 bytes from 172.18.0.2: icmp_seq=2 ttl=64 time=0.123 ms
^C
--- 172.18.0.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1005ms
rtt min/avg/max/mdev = 0.106/0.114/0.123/0.008 ms

$ ping 172.18.0.3
PING 172.18.0.3 (172.18.0.3) 56(84) bytes of data.
64 bytes from 172.18.0.3: icmp_seq=1 ttl=64 time=0.061 ms
64 bytes from 172.18.0.3: icmp_seq=2 ttl=64 time=0.206 ms
^C
--- 172.18.0.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1025ms
rtt min/avg/max/mdev = 0.061/0.133/0.206/0.072 ms

$ ping 172.18.0.4
PING 172.18.0.4 (172.18.0.4) 56(84) bytes of data.
64 bytes from 172.18.0.4: icmp_seq=1 ttl=64 time=0.139 ms
64 bytes from 172.18.0.4: icmp_seq=2 ttl=64 time=0.148 ms
^C
--- 172.18.0.4 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.139/0.143/0.148/0.004 ms

############ Halaman 15 - inisialisasi cluster ############
$ dcli
Apache Ignite CLI version 3.1.0

You appear to have not connected to any node yet. Do you want to connect to the default node http://localhost:10300? [Y/n] Y
Connected to http://localhost:10300
The cluster is not initialized. Run cluster init command to initialize it.
[node1]> cluster init --name=ignite3 --metastorage-group=node1,node2,node3
Cluster was initialized successfully
[node1]> cluster status
[name: ignite3, nodes: 3, status: active, cmgNodes: [node1, node2, node3], msNodes: [node1, node2, node3]]

# Masuk lagi ke CLI setelah Ctrl-D: tidak perlu init ulang
$ dcli
Apache Ignite CLI version 3.1.0

You appear to have not connected to any node yet. Do you want to connect to the default node http://localhost:10300? [Y/n] Y
Connected to http://localhost:10300
[node1]>

############ Halaman 17 - schema.sql ############
[node1]> sql --file=/opt/ignite/sql/schema.sql
Updated 0 rows.   (diulang 20 kali)

############ Halaman 18 - system.tables ############
[node1]> sql
sql-cli> SELECT * FROM system.tables WHERE schema = 'PUBLIC';
(11 baris: ALBUM, PLAYLISTTRACK, TRACK, CUSTOMER, MEDIATYPE, PLAYLIST, ARTIST, INVOICELINE, EMPLOYEE, GENRE, INVOICE)
(MEDIATYPE dan GENRE berada di zone CHINOOKREPLICATED, sisanya di CHINOOK)

############ Halaman 19 - memuat data ############
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

############ Halaman 20 - node2 (http://localhost:10301) ############
[node1]> connect http://localhost:10301
You are already connected to the http://localhost:10300, do you want to connect to the http://localhost:10301? [Y/n] Y
Connected to http://localhost:10301
[node2]> sql
sql-cli> SELECT * FROM system.tables WHERE schema = 'PUBLIC';
(hasil identik dengan node1: 11 tabel)

############ Halaman 21 - query analytics di node2 (12 baris pertama pada tangkapan layar) ############
 YEARMONTH | INVOICECOUNT | CUSTOMERCOUNT | MONTHLYREVENUE | AVERAGEORDERVALUE
 2024-12   | 7 | 7 | 38.62 | 5.5171428571428571
 2024-11   | 7 | 7 | 49.62 | 7.0885714285714285
 2024-10   | 7 | 7 | 37.62 | 5.3742857142857142
 2024-09   | 7 | 7 | 37.62 | 5.3742857142857142
 2024-08   | 7 | 7 | 37.62 | 5.3742857142857142
 2024-07   | 7 | 7 | 37.62 | 5.3742857142857142
 2024-06   | 7 | 7 | 37.62 | 5.3742857142857142
 2024-05   | 7 | 7 | 37.62 | 5.3742857142857142
 2024-04   | 5 | 5 | 33.66 | 6.7320000000000000
 2024-03   | 7 | 7 | 37.62 | 5.3742857142857142
 2024-02   | 5 | 5 | 27.72 | 5.5440000000000000
 2024-01   | 7 | 7 | 37.62 | 5.3742857142857142
 2023-12   | 7 | 7 | 37.62 | 5.3742857142857142

############ Halaman 22 - node3 (http://localhost:10302) ############
[node1]> connect http://localhost:10302
You are already connected to the http://localhost:10300, do you want to connect to the http://localhost:10302? [Y/n] Y
Connected to http://localhost:10302
[node3]> sql
sql-cli> (query analytics yang sama)
 2024-12 | 7 | 7 | 38.62 | 5.5171428571428571
 2024-11 | 7 | 7 | 49.62 | 7.0885714285714285
 2024-10 .. 2024-05 | 7 | 7 | 37.62 | 5.3742857142857142
 2024-04 | 5 | 5 | 33.66 | 6.7320000000000000
Node ini ternyata juga telah berisi data -> replikasi Master-Master terbukti.

############ Halaman 22 - mematikan semua node ############
$ dcd
[+] down 4/4
 v Container ignite3-node2-1 Removed
 v Container ignite3-node1-1 Removed
 v Container ignite3-node3-1 Removed
 v Network ignite3_default   Removed
```

### 12.3 Perbandingan Output Modul vs Praktikum Sendiri

| Aspek | Modul (Linux) | Praktikum ini (macOS + Colima) | Keterangan |
|---|---|---|---|
| Nama direktori kerja | `src` | `streaming-replication` / `ignite3` | Nama container mengikuti nama project |
| Nama container PostgreSQL | `src-postgres_primary-1`, `src-postgres_replica-1` | `streaming-replication-postgres_primary-1`, `...-replica-1` | Compose `name:` pada praktikum ini |
| Nama network | `src_default` | `streaming-replication_default` | |
| Status container | `Up 4 minutes (healthy)` | `Up 29 seconds (healthy)` | Sama-sama `healthy` |
| Subnet Docker (PostgreSQL) | `172.18.0.x` (replica `172.18.0.3`) | `172.19.0.x` (replica `172.19.0.3`) | Dipilih otomatis oleh Docker |
| `pg_stat_replication.pid` | 59 | 67 | Berbeda tiap eksekusi |
| `application_name` | `walreceiver` | `walreceiver` | Sama |
| `state` | `streaming` | `streaming` | Sama |
| `sync_state` | `async` | `async` | Sama |
| `sent_lsn` = `replay_lsn` | `0/304F670` | `0/3000060` | Posisi WAL berbeda, tetapi keempat nilai sama |
| `restart_lsn` slot | `0/304F670` | `0/301E030` | |
| Slot `active`/`slot_type` | `t` / `physical` | `t` / `physical` | Sama |
| `pg_is_in_recovery()` di replica | `t` | `t` | Sama |
| Hasil `pg_promote()` | `t` | `t` | Sama |
| `pg_is_in_recovery()` setelah promote | `f` | `f` | Sama |
| Sebelum tabel dibuat | `Did not find any tables.` | `Did not find any tables.` | Sama |
| Data `testrep` di replica | 2 baris (21, 23) | 2 baris (21, 23) | Sama |
| Penulisan di replica | (tidak ditunjukkan modul) | `ERROR: cannot execute INSERT in a read-only transaction` | Uji tambahan pada praktikum ini |
| Container Ignite | `ignite3-node1-1` ... `ignite3-node3-1` | sama | Sama |
| IP node Ignite | `172.18.0.2` - `172.18.0.4` | `172.19.0.2` - `172.19.0.4` | |
| Cara CLI terhubung | `--network=host`, `http://localhost:10300` | network Compose, `http://node1:10300` | Perbedaan karena macOS |
| `cluster status` | `nodes: 3, status: active` | `nodes: 3, status: active` | Sama |
| `schema.sql` | 20 baris `Updated 0 rows.` | 20 baris `Updated 0 rows.` | Sama |
| Jumlah baris data | 275, 347, 25, 5, 1000x3, 503, 8, 59, 412, ... 715 | identik | Sama persis |
| Query analytics | `2024-12 ... 38.62` | identik | Sama persis |

Kesimpulan perbandingan: semua hasil fungsional (status replikasi, peran node, data, hasil query) **identik** dengan modul. Perbedaan hanya pada nilai yang memang berubah tiap eksekusi (ID, IP, PID, LSN, waktu) dan pada nama container/network.

---

## 13. Lampiran C - Kode Asli Modul vs Versi Praktikum

Berikut kode **persis seperti pada modul**. Versi yang dipakai pada praktikum ini (bagian 4 dan 5) adalah modifikasi dari kode ini; alasannya dijelaskan pada tabel di bagian 4.3 dan 5.3. Berkas yang sama tersimpan di repositori sebagai `streaming-replication/docker-compose.module.yaml`, `streaming-replication/env.module.sh`, dan `ignite3/env.module.sh`.

### 13.1 `00_init.sql` (tidak diubah)

```sql
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator_password';
SELECT pg_create_physical_replication_slot('replication_slot');
```

### 13.2 `docker-compose.yaml` asli modul (PostgreSQL)

```yaml
# VERSI ASLI DARI MODUL 4 (bagian 4.1.2) - tidak diubah.
# Cocok untuk Linux dengan docker-compose (v1) dan nama direktori "src".
# Kelemahan: replica bisa start sebelum primary siap (muncul "connection refused"
# pada log, lalu retry), dan pg_basebackup dijalankan lagi saat container restart.
x-postgres-common:
  &postgres-common
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
    command: |
      bash -c "
        until pg_basebackup --pgdata=/var/lib/postgresql/18/docker -R --slot=replication_slot --host=postgres_primary --port=5432 -X stream; do
          echo 'pg_basebackup failed. Retrying in 5 seconds ...'
          sleep 5
        done
        echo 'Backup done, starting replica...'
        chmod 0700 /var/lib/postgresql/18/docker
        postgres
      "
    depends_on:
      - postgres_primary
```

### 13.3 `env.sh` asli modul (PostgreSQL)

```bash
# VERSI ASLI DARI MODUL 4 (bagian 4.1.2).
# Ganti <nama-direktori> dengan nama direktori tempat file disimpan.
# Pada contoh modul, direktorinya "src" sehingga nama container "src-postgres_*-1".
# Dipakai bersama docker-compose.module.yaml (jalankan: docker-compose -f docker-compose.module.yaml ...).
alias dcu="sudo docker-compose up -d"
alias dcd="sudo docker-compose down"
alias dps="sudo docker ps"
alias der="sudo docker exec -it <nama-direktori>-postgres_replica-1 bash"
alias dep="sudo docker exec -it <nama-direktori>-postgres_primary-1 bash"
alias dlr="sudo docker logs <nama-direktori>-postgres_replica-1"
alias dlp="sudo docker logs <nama-direktori>-postgres_primary-1"
```

Cara memakai versi asli (Linux, dengan `docker-compose` v1 dan direktori bernama `src`):

```bash
cd src
source env.sh
dcu          # sudo docker-compose up -d
dps
dlr          # log replica
dep          # shell di primary: psql -U zuser -d zdb
der          # shell di replica
dcd
```

Penjelasan alias menurut modul:

| Perintah | Fungsi |
|---|---|
| `docker-compose up` | Mengaktifkan beberapa container sekaligus berdasarkan `docker-compose.yaml` |
| `docker-compose down` | Menonaktifkan dan menghapus container tersebut |
| `docker ps` | Melihat daftar container yang berjalan |
| `docker exec -it` | Menjalankan proses (di sini `bash`) di container yang sedang berjalan |
| `docker logs` | Menampilkan log container yang sedang berjalan atau sudah berhenti |

### 13.4 `env.sh` asli modul (Apache Ignite)

```bash
# VERSI ASLI DARI MODUL 4 (bagian 4.2.2) - tidak diubah.
# Hanya bekerja di Linux (--network=host). Di macOS/Windows gunakan env.sh.
alias dcu="sudo docker-compose up -d"
alias dcd="sudo docker-compose down"
alias dps="sudo docker ps"
alias dclm="sudo docker run --rm -it --network=host -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 -v ./sql:/opt/ignite/sql apacheignite/ignite:3.1.0 cli"
alias dcli="sudo docker run --rm -it --network=host -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 apacheignite/ignite:3.1.0 cli"
```

Perintah CLI asli modul (bagian 4.2.4 dan 4.2.5):

```bash
# CLI tanpa mount
docker run --rm -it --network=host -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 apacheignite/ignite:3.1.0 cli

# CLI dengan mount ./sql
docker run --rm -it --network=host -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 -v ./sql:/opt/ignite/sql apacheignite/ignite:3.1.0 cli

# Inisialisasi cluster (di dalam CLI)
cluster init --name=ignite3 --metastorage-group=node1,node2,node3

# Alamat IP tiap node
sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <CONTAINER ID>
```

> Pada teks modul, beberapa perintah menyebut image `apacheignite/ignite:3.0.0` (bagian 4.2.3, 4.2.4, 4.2.5), sedangkan alias `env.sh` dan keluaran CLI menunjukkan **3.1.0**. Praktikum ini konsisten memakai **3.1.0**.

### 13.5 Ringkasan Perbedaan Kode

| Kode modul | Kode praktikum | Alasan |
|---|---|---|
| `docker-compose` (v1) | `docker compose` (v2) | v1 sudah usang; v2 adalah plugin Docker |
| `sudo ...` | tanpa `sudo` | Tidak diperlukan di Colima/Docker Desktop |
| `depends_on: - postgres_primary` | `condition: service_healthy` | Menunggu primary benar-benar siap |
| `bash -c "..."` berisi `pg_basebackup` selalu | dicek `PG_VERSION` dulu | Aman saat container di-restart |
| `postgres` di akhir skrip | `exec postgres` | Sinyal stop/restart diterima langsung |
| `$PGDATA` | `$$PGDATA` | Escape Compose agar variabel dibaca di dalam container |
| alias `der`/`dep` memakai `<nama-direktori>-...-1` | `docker compose exec <service>` | Tidak bergantung pada nama container |
| `--network=host` (Ignite) | `--network="$(ignite_net)"` | `host` tidak berlaku di macOS/Windows |
| `-v ./sql:...` | `-v "$PWD/sql:..."` | Path absolut lebih andal |

---

## 14. Lampiran D - Skrip Bantu dan Cara Pakai

Skrip berikut melengkapi modul agar seluruh percobaan bisa diulang otomatis dan hasilnya terdokumentasi. Semua skrip dijalankan dari folder masing-masing, memakai `docker compose` (v2), dan sudah diperiksa sintaksnya (`bash -n`). Berikut kegunaan tiap berkas.

### 14.1 PostgreSQL - `04/streaming-replication/scripts/`

| Skrip | Bagian modul | Fungsi |
|---|---|---|
| `00-up.sh` | 4.1.3 | `docker compose up -d --wait`, lalu `docker compose ps` |
| `01-status.sh` | 4.1.3 - 4.1.4 | Menampilkan `ps`, log replica, `pg_stat_replication`, `pg_replication_slots`, `pg_is_in_recovery()`, dan `pg_stat_wal_receiver` |
| `02-test-replication.sh` | 4.1.4 | Membuat tabel `testrep`, mengisi 2 baris di primary, membaca di replica, dan menguji bahwa replica menolak tulis |
| `03-failover.sh` | 4.1.5 | Stop primary, `pg_promote()` di replica, cek `pg_is_in_recovery()`, uji tulis di primary baru |
| `04-lag-test.sh` | tambahan | Menulis 100.000 baris di primary, mengukur `lag_bytes`, membandingkan jumlah baris di kedua node |
| `99-cleanup.sh` | 4.1.5 | `docker compose down -v` dan `docker ps` |
| `run-all.sh` | semua | Menjalankan 00, 01, 02, 03, 99 berurutan dan menyimpan log ke `04/outputs/praktikum/` |

Cara pakai:

```bash
cd 04/streaming-replication
chmod +x scripts/*.sh

# Langkah per langkah
bash scripts/00-up.sh
bash scripts/01-status.sh
bash scripts/02-test-replication.sh
bash scripts/04-lag-test.sh      # opsional
bash scripts/03-failover.sh
bash scripts/99-cleanup.sh

# Atau sekali jalan (log otomatis tersimpan)
bash scripts/run-all.sh
```

Keluaran yang diharapkan mengikuti Bagian 4.6 - 4.8 dan Lampiran B.

**Catatan `03-failover.sh`:** skrip ini mematikan primary. Jalankan setelah `02-test-replication.sh`, karena memakai tabel `testrep`.

### 14.2 Apache Ignite - `04/ignite3/scripts/`

| Berkas | Bagian modul | Fungsi |
|---|---|---|
| `get-sql.sh` | 4.2.2, 4.2.5 | Mengunduh `sql.zip`, meratakan ke `./sql`, membuang berkas sampah macOS |
| `01-up.sh` | 4.2.3 | Menyalakan 3 node, menampilkan `ps`, IP tiap node, cek 6 port dari host, dan ping IP |
| `cli-commands.txt` | 4.2.4 - 4.2.5 | Daftar perintah yang diketik **manual** di Ignite CLI (init, load SQL, verifikasi node2/node3, uji tulis dari node3) |
| `99-cleanup.sh` | 4.2.5 | `docker compose down` dan `docker ps` |

Cara pakai:

```bash
cd 04/ignite3
bash scripts/get-sql.sh          # unduh berkas SQL
bash scripts/01-up.sh            # nyalakan cluster
source env.sh
dclm                              # masuk CLI, ikuti scripts/cli-commands.txt
bash scripts/99-cleanup.sh
```

Perintah CLI Ignite dibuat sebagai berkas teks (bukan skrip otomatis), karena CLI bersifat interaktif, dan penempelan banyak baris sekaligus terbukti menimbulkan error (lihat bagian 7.9 dan 7.13). Isinya:

```text
# Perintah yang diketik MANUAL di Ignite CLI (satu per baris, tunggu hasil sebelum baris berikutnya)
# Masuk CLI:  source env.sh && dclm
# Jawab "n" pada tawaran koneksi ke localhost:10300, lalu:

connect http://node1:10300
cluster init --name=ignite3 --metastorage-group=node1,node2,node3
cluster status

# Jalankan file SQL berurutan (schema.sql dulu):
sql --file=/opt/ignite/sql/schema.sql
sql --file=/opt/ignite/sql/current_catalog.sql
sql --file=/opt/ignite/sql/media_and_genre.sql
sql --file=/opt/ignite/sql/tracks.sql
sql --file=/opt/ignite/sql/ee_and_cust.sql
sql --file=/opt/ignite/sql/invoices.sql

# Cek tabel dan jumlah data (masuk mode SQL dengan: sql)
sql
SELECT * FROM system.tables WHERE schema = 'PUBLIC';
SELECT COUNT(*) FROM Track;
SELECT COUNT(*) FROM Invoice;
exit

# Verifikasi replikasi: pindah ke node2 lalu node3 dan ulangi query
connect http://node2:10300
sql
SELECT COUNT(*) FROM Track;
exit
connect http://node3:10300
sql
SELECT COUNT(*) FROM Track;
exit

# Uji tulis dari node3, baca dari node1
connect http://node3:10300
sql
INSERT INTO Artist (ArtistId, Name) VALUES (99999, 'Artis Uji Node3');
exit
connect http://node1:10300
sql
SELECT * FROM Artist WHERE ArtistId = 99999;
exit
```

### 14.3 Cek Cepat REST API dan Port

Port yang sama dengan modul (bagian 4.2.3) dapat diperiksa dari host:

```bash
# Port REST 10300-10302 dan client 10800-10802 harus terbuka setelah "docker compose up -d"
for p in 10300 10301 10302 10800 10801 10802; do
  (exec 3<>/dev/tcp/127.0.0.1/$p) 2>/dev/null && echo "port $p: terbuka" || echo "port $p: TERTUTUP"
done
```

Skrip `01-up.sh` melakukan pengecekan ini otomatis.

> **Ping antar-IP (modul 4.2.3):** modul menunjukkan `ping 172.18.0.x` berhasil karena dijalankan di Linux, tempat network bridge Docker langsung terjangkau dari host. Pada macOS/Windows (Docker berjalan di dalam VM) IP container **tidak terjangkau** dari host sehingga ping dari host akan gagal. Itu wajar. Sebagai gantinya uji dari dalam network Compose, misalnya: `docker compose exec node1 ping -c 2 node2` (bila `ping` tersedia di image) atau cukup percayakan `cluster status` yang menunjukkan `nodes: 3`.

---

## 15. Referensi dan Sumber

Semua tautan diakses pada **23 Oktober 2026**. Kode `[R..]` dipakai pada tabel pemetaan sumber di bagian akhir.

### 15.1 Bahan Praktikum

- **[R1]** Purnomosidi D. P., B. (2026). *Modul 4 - Konsistensi dan Replikasi pada Sistem Terdistribusi* (Praktikum Sistem Terdistribusi dan Terdesentralisasi). Prodi Informatika, Universitas Teknologi Digital Indonesia. Berkas `modul-04.pdf`, 22 halaman.
- **[R2]** Eremeykin, P. *How to Setup Single Primary PostgreSQL Replication with Docker Compose*. Medium. https://medium.com/@eremeykin/how-to-setup-single-primary-postgresql-replication-with-docker-compose-98c48f233bbf (materi dasar bagian 4.1 pada modul).
- **[R3]** Repositori praktikum: https://github.com/usatjalung25-stack/prak-dis-dec (folder `04/`, termasuk log terminal `02-Streaming Replication Menggunakan PostgreSQL.sql`).
- **[R26]** Purnomosidi D. P., B. (bpdp). *Profil GitHub penulis modul* ("talk less, read more, and code in between"). https://github.com/bpdp
- **[R27]** Apache Software Foundation. *How to Start an Ignite 3 Cluster in Docker*, contoh `docker-compose.yml` 3 node (`JVM_MAX_MEM`, `configs`, `nodeFinder`) yang dipakai pada `04/ignite3/docker-compose.yml`. https://ignite.apache.org/docs/ignite3/latest/quick-start/start-cluster (sama dengan [R14]; dicantumkan terpisah karena dipakai untuk kode).

### 15.2 PostgreSQL

- **[R4]** PostgreSQL Global Development Group. *PostgreSQL 18 Documentation, Chapter 26.2: Log-Shipping Standby Servers* (streaming replication, `standby.signal`, `primary_conninfo`, replication slot, `pg_promote()`). https://www.postgresql.org/docs/18/warm-standby.html
- **[R5]** PostgreSQL Global Development Group. *PostgreSQL 18 Documentation: High Availability, Load Balancing, and Replication*. https://www.postgresql.org/docs/18/high-availability.html
- **[R6]** PostgreSQL Global Development Group. *PostgreSQL 18 Documentation: Hot Standby* (replica read-only, `hot_standby`, `hot_standby_feedback`). https://www.postgresql.org/docs/18/hot-standby.html
- **[R7]** PostgreSQL Global Development Group. *PostgreSQL 18 Documentation: pg_basebackup*. https://www.postgresql.org/docs/18/app-pgbasebackup.html
- **[R8]** PostgreSQL Global Development Group. *PostgreSQL 18 Documentation: The Cumulative Statistics System* (`pg_stat_replication`, `pg_stat_wal_receiver`). https://www.postgresql.org/docs/18/monitoring-stats.html
- **[R9]** PostgreSQL Global Development Group. *PostgreSQL 18 Documentation: System Administration Functions* (`pg_create_physical_replication_slot`, `pg_promote`, `pg_is_in_recovery`, `pg_wal_lsn_diff`). https://www.postgresql.org/docs/18/functions-admin.html
- **[R10]** PostgreSQL Global Development Group. *PostgreSQL 18 Documentation: The pg_hba.conf File*. https://www.postgresql.org/docs/18/auth-pg-hba-conf.html
- **[R11]** Docker Official Image `postgres` (variabel `POSTGRES_USER`, `POSTGRES_DB`, `POSTGRES_PASSWORD`, `POSTGRES_HOST_AUTH_METHOD`, `POSTGRES_INITDB_ARGS`, direktori `/docker-entrypoint-initdb.d`). Docker Hub. https://hub.docker.com/_/postgres

### 15.3 Apache Ignite 3

- **[R12]** Apache Software Foundation. *Apache Ignite 3 Documentation*. https://ignite.apache.org/docs/ignite3/latest/index
- **[R13]** Apache Software Foundation. *Apache Ignite 3 - Explore SQL (Quick Start)*, termasuk `docker-compose.yml` dan `sql.zip`. https://ignite.apache.org/docs/ignite3/latest/quick-start/explore-sql
  - https://ignite.apache.org/docs/ignite3/latest/quick-start/sql-files/docker-compose.yml
  - https://ignite.apache.org/docs/ignite3/latest/quick-start/sql-files/sql.zip
- **[R14]** Apache Software Foundation. *How to Start an Ignite 3 Cluster in Docker* (`cluster init --name=ignite3 --metastorage-group=node1,node2,node3`, `cluster status`, port 10300/10800). https://ignite.apache.org/docs/ignite3/latest/quick-start/start-cluster
- **[R15]** Apache Software Foundation. *Getting Started With Apache Ignite 3* (penjelasan `--metastorage-group`, anjuran 3, 5, atau 7 node, CLI dan mode SQL). https://ignite.apache.org/docs/ignite3/latest/quick-start/getting-started-guide
- **[R16]** Apache Ignite 3 source repository, README (menjalankan CLI di dalam Docker dengan `--net ignite3_default` dan `connect http://node1:10300`). https://github.com/apache/ignite-3
- **[R17]** Ongaro, D., & Ousterhout, J. (2014). *In Search of an Understandable Consensus Algorithm (Extended Version)*. USENIX Annual Technical Conference. https://raft.github.io/raft.pdf (dasar konsensus Raft yang dipakai Ignite 3 untuk replikasi partisi).

### 15.4 Docker, Compose, dan Lingkungan

- **[R18]** Docker Inc. *Install Docker Engine*. https://docs.docker.com/engine/install/ (catatan: modul menuliskan `https://.docs.docker.com/engine/install/` dengan titik berlebih; alamat yang benar adalah tanpa titik tersebut).
- **[R19]** Docker Inc. *Install Docker Engine on Ubuntu*. https://docs.docker.com/engine/install/ubuntu/
- **[R20]** Docker Inc. *Install Docker Compose*. https://docs.docker.com/compose/install/
- **[R21]** Docker Inc. *Compose file reference* (anchor/extension `x-`, `healthcheck`, `depends_on`, `command`, interpolasi `$$`). https://docs.docker.com/reference/compose-file/
- **[R22]** Docker Inc. *Control startup and shutdown order in Compose* (`depends_on` dengan `condition: service_healthy`). https://docs.docker.com/compose/how-tos/startup-order/
- **[R23]** Docker Inc. *Docker Desktop WSL 2 backend on Windows*. https://docs.docker.com/desktop/features/wsl/
- **[R24]** Abiosoft. *Colima: Container runtimes on macOS (and Linux) with minimal setup*. https://github.com/abiosoft/colima
- **[R25]** Homebrew. *The Missing Package Manager for macOS (or Linux)*. https://brew.sh

### 15.5 Pemetaan Sumber ke Bagian Dokumen

| Bagian README | Sumber utama |
|---|---|
| 1. Tujuan, struktur tugas | [R1] |
| 2. Konsep primary-replica, WAL, asinkron | [R4], [R5], [R6] |
| 2. Konsep Master-Master, zone, replika, kuorum | [R12], [R15], [R17] |
| 3. Instalasi Docker (Linux, macOS, Windows) | [R18], [R19], [R20], [R23], [R24], [R25] |
| 4.2 `00_init.sql` (user replikasi, slot) | [R4], [R9] |
| 4.3 `docker-compose.yaml` (variabel env, parameter server, `pg_basebackup`) | [R2], [R7], [R10], [R11], [R21], [R22] |
| 4.4 `env.sh` (alias `docker compose`) | [R20], [R21] |
| 4.7 Pengujian (`pg_stat_replication`, slot, `pg_is_in_recovery`) | [R8], [R9] |
| 4.8 Failover `pg_promote()` | [R4], [R9] |
| 5.1 sampai 5.3 File Ignite dan `env.sh` | [R13], [R16] |
| 5.5 Inisialisasi cluster | [R14], [R15] |
| 5.6 sampai 5.8 Eksekusi SQL dan verifikasi node | [R13], [R14] |
| 6. Perbandingan model replikasi | [R4], [R12], [R17] |
| 7. Error dan solusi | [R2], [R4], [R14], [R16], [R21], [R22] |
| 8. Perintah lanjutan | [R8], [R9], [R12], [R15] |
| 5.1 `docker-compose.yml` Ignite | [R14], [R27] |
| Lampiran A | [R3] (log terminal asli) |
| Lampiran B (output pembanding) | [R1], [R26] |
| Lampiran C (kode asli modul) | [R1], [R2], [R13] |
| Lampiran D (skrip bantu) | [R4], [R9], [R14], [R20] |

---

*Dokumen ini disusun untuk keperluan praktikum. Seluruh keluaran terminal berasal dari eksekusi nyata pada 23 Oktober 2026, sedangkan penjelasan konsep merujuk pada dokumentasi resmi di atas.*
