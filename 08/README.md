# Modul 8 — Arsitektur Microservices untuk Sistem Terdistribusi

Praktikum Sistem Terdistribusi dan Terdesentralisasi
Program Studi Informatika, Universitas Teknologi Digital Indonesia

| | |
|---|---|
| **Nama** | USAT JALUNG |
| **NIM** | 255410017 |
| **Kelas** | IF-1 |
| **Pembuat modul** | Dr. Bambang Purnomosidi D. P. |
| **Perangkat** | MacBook (macOS), Terminal zsh, browser Safari |
| **Tanggal pengerjaan** | 20 November 2026 |

README ini terdiri atas **dua bagian yang dipisah** dan tidak digabung:

| Bagian | Isi | Log sumber | Gambar output |
|---|---|---|---|
| **A. Praktik contoh modul** | Instalasi, tabel `sdm`, service `GET /sdm/` | `setup-fastapi-sqlmodel-uvicorn.log` | `Hasil curl dari tes Safari.png`, `Hasil curl dari tes Terminal.png` |
| **B. Tugas** | Tabel `buku`, isi 5 data, service `GET /buku/` | `tugas-buku-sqlite-fastapi-log.txt` | `TUGAS-Hasil curl dari tes Safari.png`, `TUGAS-Hasil curl dari tes Terminal.png` |

---

## Daftar Isi

1. [Tentang modul dan pembuatnya](#1-tentang-modul-dan-pembuatnya)
2. [Isi folder 08](#2-isi-folder-08)
3. [Teknologi dan versi yang terpakai](#3-teknologi-dan-versi-yang-terpakai)
4. [Pola dan arsitektur](#4-pola-dan-arsitektur)
5. [Bagian A — Praktik contoh modul (tabel `sdm`)](#5-bagian-a--praktik-contoh-modul-tabel-sdm)
6. [Bagian B — Tugas (tabel `buku`)](#6-bagian-b--tugas-tabel-buku)
7. [Perbandingan Safari, curl, dan PDF](#7-perbandingan-safari-curl-dan-pdf)
8. [Kesimpulan](#8-kesimpulan)
9. [Troubleshooting](#9-troubleshooting)
10. [Referensi](#10-referensi)

---

## 1. Tentang modul dan pembuatnya

**Pembuat modul:** Dr. Bambang Purnomosidi D. P., Prodi Informatika, Universitas Teknologi Digital Indonesia.

**Isi modul (Pengantar):** Microservices adalah arsitektur yang banyak dipakai pada sistem terdistribusi. Software terdiri atas *frontend* (UI/UX, titik interaksi pengguna) yang meminta layanan dari *backend* berupa *service*. Service dapat dibuat dengan REST API, GraphQL, atau gRPC. Praktik mata kuliah ini memakai **REST API** dengan pustaka **FastAPI** dan **SQLModel** (ORM Python).

**Struktur modul:**

| Bab modul | Isi |
|---|---|
| 0. Pengantar | Konsep microservices |
| 1. Prasyarat | Install uv, Python 3.14, FastAPI + SQLModel, SQLite, buat database |
| 2. Source Code | `service.py` dengan model `Sdm` dan endpoint `GET /sdm/` |
| 3. Menjalankan Source Code | `uvicorn service:app --reload`, cek dengan browser atau curl |
| 4. Tugas | Empat butir tugas di bawah |

**Tugas pada modul:**

1. Buat satu tabel baru menggunakan SQLite, berbeda dari contoh. Tabel punya 1 primary key dan setidaknya berisi data bertipe INT, CHAR, VARCHAR, BOOLEAN, dan FLOAT.
2. Isikan 5 data menggunakan script Python.
3. Buat RESTful API endpoint untuk menampilkan semua data yang telah diisikan.
4. Tampilkan hasil RESTful API endpoint tersebut menggunakan curl.

---

## 2. Isi folder 08

```
08/
├── README.md                                   <- dokumen ini
├── setup-fastapi-sqlmodel-uvicorn.log          <- log terminal Bagian A
├── tugas-buku-sqlite-fastapi-log.txt           <- log terminal Bagian B
├── image/
│   ├── Hasil curl dari tes Safari.png          <- output akhir A, Safari
│   ├── Hasil curl dari tes Terminal.png        <- output akhir A, curl
│   ├── TUGAS-Hasil curl dari tes Safari.png    <- output akhir B, Safari
│   ├── TUGAS-Hasil curl dari tes Terminal.png  <- output akhir B, curl
│   └── PDF/
│       ├── localhost-8000-sdm.pdf              <- Safari ke PDF, endpoint /sdm/
│       └── localhost-8000-buku.pdf             <- Safari ke PDF, endpoint /buku/
└── kode/                                       <- kode lengkap (log memotong heredoc)
    ├── contoh/
    │   ├── departemen-sdm.sql
    │   └── service.py
    └── tugas/
        ├── schema.sql
        ├── seed.py
        └── service.py
```

| File | Keterangan |
|---|---|
| `setup-fastapi-sqlmodel-uvicorn.log` | Rekaman Terminal: cek SQLite, siapkan Python dan venv, install paket, buat tabel `sdm`, jalankan service. |
| `tugas-buku-sqlite-fastapi-log.txt` | Rekaman Terminal tugas: buat `schema.sql`, `seed.py`, cek SQLite, jalankan service `buku`. |
| 4 file PNG | Tangkapan layar hasil akhir dari Safari dan Terminal untuk Bagian A dan B. |
| 2 file PDF | Halaman endpoint yang diekspor dari Safari (A4, 1 halaman). |
| `kode/` | Isi file kode secara utuh. Pada log, perintah `cat > ... <<'EOF'` yang panjang terpotong oleh prompt lanjutan `>....`, jadi kode lengkapnya diletakkan di sini. |

---

## 3. Teknologi dan versi yang terpakai

Versi diambil dari log instalasi pada MacBook (`uv pip install`), bukan dari angka contoh di modul.

| Komponen | Versi | Fungsi |
|---|---|---|
| macOS + zsh | (Terminal `ttys000`) | Sistem operasi dan shell |
| SQLite | 3.54.1 (2026-10-16) | Database file |
| Python (CPython) | 3.14.10 (dipin ke `3.14`) | Bahasa pemrograman |
| uv | terpasang | Pengelola Python, venv, dan paket |
| FastAPI | 0.165.0 | Framework REST API |
| SQLModel | 0.0.50 | ORM, gabungan SQLAlchemy dan Pydantic |
| SQLAlchemy | 2.1.9 | Mesin ORM di bawah SQLModel |
| Pydantic | 2.14.4 | Validasi dan serialisasi data |
| Starlette | 1.10.0 | Dasar web FastAPI |
| Uvicorn | 0.54.0 | Server ASGI |
| httpx / jinja2 / watchfiles | 0.28.1 / 3.1.6 / 1.3.0 | Ikut terpasang lewat `fastapi[standard]` (`watchfiles` dipakai `--reload`) |
| curl | bawaan macOS | Klien HTTP untuk uji endpoint |
| Safari | bawaan macOS | Klien browser, juga untuk ekspor PDF |

Total paket yang terpasang: **61**.

---

## 4. Pola dan arsitektur

| Pola / konsep | Penerapan |
|---|---|
| **Microservices** | Tiap service punya satu fungsi dan satu database sendiri: `departemen-sdm.db` untuk service SDM, `perpustakaan.db` untuk service buku. |
| **Client–Server** | Safari dan curl adalah klien, FastAPI di Uvicorn adalah server (`127.0.0.1:8000`). |
| **REST API** | Sumber daya diakses lewat URL (`/sdm/`, `/buku/`), metode HTTP `GET`, respons JSON, status `200 OK`. |
| **ORM** | Kelas Python `Sdm` dan `Buku` dipetakan ke tabel SQLite oleh SQLModel. Query ditulis dengan `select(...)`. |
| **Dependency Injection** | `Depends(get_session)` memasok sesi database ke endpoint. |
| **Session per request** | `get_session` memakai `with ... yield`, jadi sesi dibuka saat request dan ditutup otomatis sesudahnya. |
| **Response model** | `response_model=List[...]` membuat FastAPI memvalidasi dan membentuk respons sebagai daftar objek. |
| **Pemisahan tanggung jawab (Bagian B)** | Skema (`schema.sql`), pengisian data (`seed.py`), dan API (`service.py`) dipisah ke file masing-masing. |
| **Hot reload** | `--reload` membuat Uvicorn memantau file dan memuat ulang server otomatis (proses *reloader* dan proses *server* terpisah). |

---

## 5. Bagian A — Praktik contoh modul (tabel `sdm`)

Sumber log: [`setup-fastapi-sqlmodel-uvicorn.log`](setup-fastapi-sqlmodel-uvicorn.log)

### 5.1 Langkah persiapan dan penjelasan tiap perintah

| No | Perintah | Output di log | Penjelasan |
|---|---|---|---|
| 1 | `sqlite3 --version` | `3.54.1 2026-10-16 ... (64-bit)` | Memastikan SQLite sudah ada. Di macOS SQLite bawaan sistem, jadi tidak perlu install. |
| 2 | `mkdir -p ~/modul8 && cd ~/modul8` | (tidak ada) | Membuat folder kerja dan masuk ke dalamnya. `-p` tidak error bila folder sudah ada. |
| 3 | `uv python install 3.14` | `Python 3.14 is already installed` | Memasang Python 3.14 lewat uv. Sudah terpasang, jadi tidak diunduh ulang. |
| 4 | `uv python pin 3.14` | ``Pinned `.python-version` to `3.14` `` | Menulis file `.python-version` supaya folder ini selalu memakai Python 3.14. |
| 5 | `uv venv` | `Using CPython 3.14.10` lalu `Creating virtual environment at: .venv` | Membuat virtual environment di folder `.venv`. |
| | (pertanyaan interaktif) | `A virtual environment already exists at .venv. Do you want to replace it?` → `yes` | `.venv` sudah ada dari percobaan sebelumnya, dijawab *yes* sehingga dibuat ulang bersih. |
| 6 | `source .venv/bin/activate` | prompt menjadi `(modul8)` | Mengaktifkan venv. Awalan `(modul8)` pada prompt menandakan venv aktif. |
| 7 | `uv pip install "fastapi[standard]" sqlmodel` | `Resolved 61 packages in 71ms`, `Installed 61 in 193ms` | Memasang FastAPI (paket `standard`) dan SQLModel beserta dependensinya. Tanda kutip wajib di zsh agar `[standard]` tidak dibaca sebagai pola glob. |

Paket penting dari daftar `+ ...` pada log:

| Paket | Versi | Peran |
|---|---|---|
| `fastapi` | 0.165.0 | Framework API |
| `sqlmodel` | 0.0.50 | ORM |
| `sqlalchemy` | 2.1.9 | Mesin ORM |
| `pydantic` / `pydantic-core` | 2.14.4 / 2.50.5 | Validasi data |
| `starlette` | 1.10.0 | Dasar web |
| `uvicorn` | 0.54.0 | Server |
| `uvloop`, `httptools`, `websockets` | 0.23.0, 0.9.0, 17.4 | Pemercepat dan protokol Uvicorn |
| `watchfiles` | 1.3.0 | Pemantau file untuk `--reload` |
| `httpx`, `jinja2`, `python-multipart` | 0.28.1, 3.1.6, 0.0.34 | Ikut dari `fastapi[standard]` |
| `typer`, `rich`, `click` | 0.29.2, 15.0.0, 8.5.1 | CLI `fastapi` dan tampilan terminal |

### 5.2 Membuat database dan tabel `sdm`

```bash
mkdir -p ~/modul8/contoh && cd ~/modul8/contoh
sqlite3 departemen-sdm.db <<'EOF'
CREATE TABLE sdm (id INTEGER PRIMARY KEY, npp CHAR(6), nama VARCHAR(50));
INSERT INTO sdm (npp, nama) VALUES ('112233', 'Karyawan 1');
INSERT INTO sdm (npp, nama) VALUES ('223344', 'Karyawan 2');
INSERT INTO sdm (npp, nama) VALUES ('334455', 'Karyawan 3');
SELECT * FROM sdm;
EOF
```

**Penjelasan kode SQL:**

| Baris | Arti |
|---|---|
| `sqlite3 departemen-sdm.db <<'EOF' ... EOF` | Membuka (atau membuat) database `departemen-sdm.db`, lalu menjalankan semua baris di antara `EOF` sebagai perintah SQL. Tanda kutip pada `'EOF'` mencegah shell mengubah isinya. |
| `CREATE TABLE sdm (...)` | Membuat tabel `sdm`. |
| `id INTEGER PRIMARY KEY` | Kolom `id` bilangan bulat, primary key, terisi otomatis. |
| `npp CHAR(6)` | Nomor pokok pegawai, teks tetap 6 karakter. |
| `nama VARCHAR(50)` | Nama pegawai, teks sampai 50 karakter. |
| `INSERT INTO sdm (npp, nama) VALUES (...)` | Menambah satu baris. `id` tidak diisi karena otomatis. |
| `SELECT * FROM sdm;` | Menampilkan semua baris. |

**Output dan pembahasan (dua percobaan pada log):**

*Percobaan pertama* menghasilkan galat, tetapi 6 baris muncul:

```
Parse error near line 1: table sdm already exists
  CREATE TABLE sdm (id INTEGER PRIMARY KEY, npp CHAR(6), nama VARCHAR(50));
               ^--- error here
╭────┬──────────┬────────────╮
│ id │   npp    │    nama    │
╞════╪══════════╪════════════╡
│  1 │ '112233' │ Karyawan 1 │
│  2 │ '223344' │ Karyawan 2 │
│  3 │ '334455' │ Karyawan 3 │
│  4 │ '112233' │ Karyawan 1 │
│  5 │ '223344' │ Karyawan 2 │
│  6 │ '334455' │ Karyawan 3 │
╰────┴──────────┴────────────╯
```

Penyebabnya: file `departemen-sdm.db` sudah ada dari percobaan sebelumnya, jadi `CREATE TABLE` gagal (`table sdm already exists`). Pada mode skrip, sqlite3 tetap melanjutkan ke baris berikutnya, sehingga tiga `INSERT` terjalankan lagi dan data tercatat dobel (id 4 sampai 6 adalah duplikat id 1 sampai 3).

*Percobaan kedua* (perbaikan): file lama dihapus lebih dulu, lalu perintah diulang.

```bash
rm departemen-sdm.db && sqlite3 departemen-sdm.db <<'EOF'
...
EOF
```

```
╭────┬──────────┬────────────╮
│ id │   npp    │    nama    │
╞════╪══════════╪════════════╡
│  1 │ '112233' │ Karyawan 1 │
│  2 │ '223344' │ Karyawan 2 │
│  3 │ '334455' │ Karyawan 3 │
╰────┴──────────┴────────────╯
```

Sekarang tepat 3 baris, sesuai modul. Tampilan tabel berbingkai dan tanda kutip tunggal pada `npp` adalah format keluaran bawaan SQLite versi baru (3.54.1), tidak berarti kutipnya ikut tersimpan di data.

### 5.3 Source code `service.py`

```python
from typing import List, Optional
from fastapi import Depends, FastAPI, HTTPException
from sqlmodel import Field, Session, SQLModel, create_engine, select


class Sdm(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    npp: str
    nama: str


engine = create_engine("sqlite:///departemen-sdm.db")


def get_session():
    with Session(engine) as session:
        yield session


app = FastAPI()


@app.get("/sdm/", response_model=List[Sdm])
def read_sdm(session: Session = Depends(get_session)):
    # SQLModel select statement
    statement = select(Sdm)
    results = session.exec(statement).all()
    return results
```

(Pada log, file dibuat dengan `cat > service.py <<'EOF' ... EOF`. Baris awalnya terpotong oleh prompt lanjutan `>....` pada tampilan terminal. File utuhnya ada di [`kode/contoh/service.py`](kode/contoh/service.py).)

**Penjelasan kode baris per bagian:**

| Bagian kode | Penjelasan |
|---|---|
| `from typing import List, Optional` | `List` dipakai untuk tipe respons berupa daftar. `Optional` diimpor sesuai modul tetapi tidak terpakai. |
| `from fastapi import Depends, FastAPI, HTTPException` | `FastAPI` membuat aplikasi, `Depends` untuk dependency injection. `HTTPException` diimpor sesuai modul tetapi tidak terpakai pada contoh ini. |
| `from sqlmodel import Field, Session, SQLModel, create_engine, select` | `Field` mengatur kolom, `Session` sesi database, `SQLModel` kelas dasar model, `create_engine` membuat koneksi, `select` membuat query. |
| `class Sdm(SQLModel, table=True)` | Model sekaligus tabel. `table=True` berarti kelas ini dipetakan ke tabel database (nama tabel otomatis `sdm`). |
| `id: int \| None = Field(default=None, primary_key=True)` | Kolom primary key. Boleh `None` saat objek baru dibuat karena nilainya diisi database. |
| `npp: str`, `nama: str` | Dua kolom teks. |
| `engine = create_engine("sqlite:///departemen-sdm.db")` | Koneksi ke file SQLite. Tiga garis miring berarti path relatif terhadap folder tempat service dijalankan, jadi service harus dijalankan dari folder yang berisi `departemen-sdm.db`. |
| `def get_session(): with Session(engine) as session: yield session` | Fungsi dependency. Sesi dibuka, diserahkan ke endpoint lewat `yield`, lalu ditutup otomatis saat request selesai. |
| `app = FastAPI()` | Membuat objek aplikasi yang dijalankan Uvicorn. |
| `@app.get("/sdm/", response_model=List[Sdm])` | Mendaftarkan endpoint `GET /sdm/`. Respons divalidasi sebagai daftar objek `Sdm`. |
| `def read_sdm(session: Session = Depends(get_session))` | FastAPI memanggil `get_session` dan menaruh hasilnya di parameter `session`. |
| `statement = select(Sdm)` | Membuat query setara `SELECT * FROM sdm`. |
| `results = session.exec(statement).all()` | Menjalankan query dan mengambil semua baris. |
| `return results` | FastAPI mengubah hasil menjadi JSON. |

### 5.4 Menjalankan service dan membaca log Uvicorn

```bash
uvicorn service:app --reload
```

`service:app` berarti file `service.py`, objek `app`. `--reload` memuat ulang server otomatis saat file berubah.

Log **run pertama**:

```
INFO:     Will watch for changes in these directories: ['/Users/danel/modul8/contoh']
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [41208] using WatchFiles
INFO:     Started server process [41210]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     127.0.0.1:51755 - "GET /sdm/ HTTP/1.1" 200 OK
INFO:     127.0.0.1:51764 - "GET /sdm/ HTTP/1.1" 200 OK
^CINFO:     Shutting down
INFO:     Waiting for application shutdown.
INFO:     Application shutdown complete.
INFO:     Finished server process [41210]
INFO:     Stopping reloader process [41208]
```

Log **run kedua** (dijalankan ulang untuk tes Safari):

```
INFO:     Started reloader process [45014] using WatchFiles
INFO:     Started server process [45016]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     127.0.0.1:51887 - "GET /sdm/ HTTP/1.1" 200 OK
INFO:     127.0.0.1:51887 - "GET /favicon.ico HTTP/1.1" 404 Not Found
```

| Baris log | Arti |
|---|---|
| `Will watch for changes in these directories: [...]` | Mode `--reload` aktif dan memantau folder `contoh`. |
| `Uvicorn running on http://127.0.0.1:8000` | Server siap di alamat lokal, port 8000. `localhost` dan `127.0.0.1` sama saja. |
| `Started reloader process [41208] using WatchFiles` | Proses pemantau file (induk). Angka dalam kurung adalah PID. |
| `Started server process [41210]` | Proses server yang benar-benar melayani request (anak). |
| `Application startup complete.` | Aplikasi FastAPI siap menerima request. |
| `127.0.0.1:51755 - "GET /sdm/ HTTP/1.1" 200 OK` | Ada klien (angka 51755 adalah port acak milik klien) meminta `GET /sdm/` dan dijawab status 200 (berhasil). |
| `"GET /favicon.ico HTTP/1.1" 404 Not Found` | Safari otomatis meminta ikon tab. Service tidak punya rute itu, jadi 404. Ini wajar dan tidak mengganggu hasil. |
| `^C` lalu `Shutting down` ... `Stopping reloader process` | `Ctrl+C` menghentikan server dengan rapi, proses server lalu reloader berhenti berurutan. |

Pada run pertama ada **dua** `GET /sdm/` (satu dari Safari, satu dari curl). Pada run kedua ada satu `GET /sdm/` dari Safari ditambah permintaan favicon.

### 5.5 Output akhir

**Safari** (`http://localhost:8000/sdm/`):

![Hasil curl dari tes Safari](image/Hasil%20curl%20dari%20tes%20Safari.png)

Isi yang tampil:

```
[{"npp":"112233","nama":"Karyawan 1","id":1},
{"npp":"223344","nama":"Karyawan 2","id":2},
{"npp":"334455","nama":"Karyawan 3","id":3}]
```

**Terminal** (`curl http://localhost:8000/sdm/`):

![Hasil curl dari tes Terminal](image/Hasil%20curl%20dari%20tes%20Terminal.png)

Isi yang tampil:

```
[{"id":1,"npp":"112233","nama":"Karyawan 1"},{"id":2,"npp":"223344","nama":"Karyawan 2"},{"id":3,"npp":"334455","nama":"Karyawan 3"}]
```

**PDF dari Safari:** [`image/PDF/localhost-8000-sdm.pdf`](image/PDF/localhost-8000-sdm.pdf) (halaman endpoint `/sdm/` diekspor dari Safari, A4, 1 halaman).

### 5.6 Pembahasan output Bagian A

- Endpoint mengembalikan **3 objek JSON** sesuai 3 baris pada tabel `sdm`.
- Tiap objek memuat `id`, `npp`, `nama`, yaitu kolom-kolom model `Sdm`.
- `npp` tampil sebagai string (`"112233"`, dengan tanda kutip) karena bertipe `str`, jadi angka nol di depan tidak akan hilang.
- Urutan field pada dua gambar berbeda (Safari: `npp, nama, id`; curl: `id, npp, nama`) karena kedua tangkapan layar berasal dari dua kali menjalankan service. Isinya sama, dan JSON tidak mengikat urutan field.
- Safari menampilkan JSON mentah tanpa format karena tidak memformat JSON otomatis. Teks pada gambar Safari terlipat ke beberapa baris hanya karena lebar jendela.
- Pada Terminal, tanda `%` di ujung output curl dari zsh menandakan respons tidak diakhiri baris baru.
- Gambar Terminal memperlihatkan baris perintah `curl http://localhost:8000/sdm/` dua kali, tetapi hasil JSON hanya muncul satu kali di bawahnya. Isi data tidak terpengaruh.
- Hasil Safari dan curl sama, membuktikan service dapat diakses klien apa pun lewat HTTP.

---

## 6. Bagian B — Tugas (tabel `buku`)

Sumber log: [`tugas-buku-sqlite-fastapi-log.txt`](tugas-buku-sqlite-fastapi-log.txt)

Tema: **perpustakaan**. Tabel `buku` berbeda dari tabel `sdm` pada contoh.

### 6.1 Persiapan folder

```bash
cd ~/modul8
source .venv/bin/activate
mkdir -p tugas-buku && cd tugas-buku
```

Venv yang sama dari Bagian A dipakai lagi, jadi tidak perlu install ulang. Prompt `(modul8)` menandakan venv aktif. Semua file tugas diletakkan di folder terpisah `tugas-buku`, tidak bercampur dengan folder `contoh`.

### 6.2 Tugas 1 — Tabel baru (`schema.sql`)

```bash
cat > schema.sql <<'EOF'
-- Skema database perpustakaan
DROP TABLE IF EXISTS buku;

CREATE TABLE buku (
    id            INTEGER       PRIMARY KEY,
    kode          CHAR(6)       NOT NULL UNIQUE,
    judul         VARCHAR(100)  NOT NULL,
    tahun_terbit  INT           NOT NULL,
    harga_sewa    FLOAT         NOT NULL,
    tersedia      BOOLEAN       NOT NULL DEFAULT 1
);
EOF
```

| Kolom | Tipe | Memenuhi syarat | Keterangan |
|---|---|---|---|
| `id` | `INTEGER` | **Primary key** | Terisi otomatis oleh SQLite. |
| `kode` | `CHAR(6)` | **CHAR** | Kode buku tepat 6 karakter. `UNIQUE` melarang kode ganda. |
| `judul` | `VARCHAR(100)` | **VARCHAR** | Judul sampai 100 karakter. |
| `tahun_terbit` | `INT` | **INT** | Tahun terbit. |
| `harga_sewa` | `FLOAT` | **FLOAT** | Biaya sewa berupa bilangan desimal. |
| `tersedia` | `BOOLEAN` | **BOOLEAN** | Status ketersediaan. SQLite menyimpannya sebagai `1` atau `0`. |

Penjelasan tambahan:

- `-- ...` adalah komentar SQL.
- `DROP TABLE IF EXISTS buku;` menghapus tabel lama bila ada. Ini menghindari galat `table already exists` seperti yang terjadi pada Bagian A, dan membuat skrip aman dijalankan berulang.
- `NOT NULL` melarang kolom kosong.
- `DEFAULT 1` membuat buku dianggap tersedia bila nilainya tidak diisi.
- Kolom sejajar (rata) di file agar SQL mudah dibaca.

### 6.3 Tugas 2 — Isi 5 data dengan script Python (`seed.py`)

```python
import sqlite3

DB_FILE = "perpustakaan.db"
SCHEMA_FILE = "schema.sql"

INSERT_SQL = """
    INSERT INTO buku (
        kode,
        judul,
        tahun_terbit,
        harga_sewa,
        tersedia
    )
    VALUES (?, ?, ?, ?, ?)
"""

DATA = [
    ("BK0001", "Pemrograman Python Dasar", 2021, 5000.00, True),
    ("BK0002", "Sistem Terdistribusi",     2019, 7500.50, True),
    ("BK0003", "Basis Data Lanjut",        2020, 6000.00, False),
    ("BK0004", "Jaringan Komputer",        2018, 5500.75, True),
    ("BK0005", "Kecerdasan Buatan",        2023, 8000.25, False),
]

conn = sqlite3.connect(DB_FILE)

# 1. Buat tabel dari schema.sql
with open(SCHEMA_FILE, encoding="utf-8") as f:
    conn.executescript(f.read())

# 2. Isi 5 data
conn.executemany(INSERT_SQL, DATA)
conn.commit()

# 3. Tampilkan hasil
print(f"{'id':<3} {'kode':<7} {'judul':<26} {'tahun':<6} {'harga':>9}  tersedia")
print("-" * 62)
for id_, kode, judul, tahun, harga, ada in conn.execute("SELECT * FROM buku"):
    print(f"{id_:<3} {kode:<7} {judul:<26} {tahun:<6} {harga:>9.2f}  {bool(ada)}")

conn.close()
print(f"\n{len(DATA)} data berhasil dimasukkan ke {DB_FILE}")
```

(Pada log, bagian awal file ini terpotong oleh prompt lanjutan `>....`. File utuhnya ada di [`kode/tugas/seed.py`](kode/tugas/seed.py).)

**Penjelasan kode:**

| Bagian | Penjelasan |
|---|---|
| `import sqlite3` | Modul SQLite bawaan Python, tidak perlu di-install. |
| `DB_FILE`, `SCHEMA_FILE` | Konstanta nama file database dan file skema. |
| `INSERT_SQL = """..."""` | Query `INSERT` dengan lima tanda `?` sebagai placeholder. Placeholder mengisi nilai dengan aman (mencegah SQL injection) dan menangani tipe data otomatis. `id` tidak disebut karena otomatis. |
| `DATA = [...]` | Daftar 5 tuple, satu tuple per buku, urutan isinya sama dengan urutan kolom pada `INSERT_SQL`. |
| `sqlite3.connect(DB_FILE)` | Membuka (atau membuat) file `perpustakaan.db`. |
| `conn.executescript(f.read())` | Menjalankan seluruh isi `schema.sql`, yaitu menghapus tabel lama lalu membuat tabel baru. |
| `conn.executemany(INSERT_SQL, DATA)` | Menjalankan `INSERT` sekali untuk tiap tuple, jadi 5 baris masuk sekaligus. |
| `conn.commit()` | Menyimpan perubahan permanen. Tanpa ini data tidak tersimpan. |
| `conn.execute("SELECT * FROM buku")` | Membaca kembali isi tabel untuk verifikasi. |
| `f"{id_:<3} ... {harga:>9.2f}"` | Format cetak: `:<26` rata kiri lebar 26, `:>9.2f` rata kanan, 9 karakter, 2 angka desimal. |
| `bool(ada)` | Mengubah `1`/`0` dari SQLite menjadi `True`/`False` agar mudah dibaca. |
| `conn.close()` | Menutup koneksi. |

**Menjalankan dan output (dari log):**

```bash
python seed.py
```

```
id  kode    judul                      tahun      harga  tersedia
--------------------------------------------------------------
1   BK0001  Pemrograman Python Dasar   2021     5000.00  True
2   BK0002  Sistem Terdistribusi       2019     7500.50  True
3   BK0003  Basis Data Lanjut          2020     6000.00  False
4   BK0004  Jaringan Komputer          2018     5500.75  True
5   BK0005  Kecerdasan Buatan          2023     8000.25  False

5 data berhasil dimasukkan ke perpustakaan.db
```

**Pengecekan dengan sqlite3 (dari log):**

```bash
sqlite3 perpustakaan.db ".schema buku"
```

```
CREATE TABLE buku (
    id            INTEGER       PRIMARY KEY,
    kode          CHAR(6)       NOT NULL UNIQUE,
    judul         VARCHAR(100)  NOT NULL,
    tahun_terbit  INT           NOT NULL,
    harga_sewa    FLOAT         NOT NULL,
    tersedia      BOOLEAN       NOT NULL DEFAULT 1
);
```

```bash
sqlite3 -header -column perpustakaan.db "SELECT * FROM buku;"
```

```
id   kode            judul            tahun_terbit  harga_sewa  tersedia
--  ------  ------------------------  ------------  ----------  --------
 1  BK0001  Pemrograman Python Dasar          2021      5000.0         1
 2  BK0002  Sistem Terdistribusi              2019      7500.5         1
 3  BK0003  Basis Data Lanjut                 2020      6000.0         0
 4  BK0004  Jaringan Komputer                 2018     5500.75         1
 5  BK0005  Kecerdasan Buatan                 2023     8000.25         0
```

**Pembahasan:**

- Lima baris masuk dengan `id` 1 sampai 5, dan `seed.py` tidak menimbulkan galat atau data ganda (berbeda dengan Bagian A) karena `DROP TABLE IF EXISTS` selalu membersihkan tabel lebih dulu.
- `.schema buku` menunjukkan DDL tersimpan persis seperti di `schema.sql`, jadi kelima tipe (INTEGER, CHAR, VARCHAR, INT, FLOAT, BOOLEAN) tercatat.
- Kolom `tersedia` tersimpan sebagai `1`/`0` di SQLite, tetapi Python mencetaknya `True`/`False` setelah `bool(...)`.
- Nilai FLOAT seperti `7500.50` tampil `7500.5` pada sqlite3 karena sqlite3 tidak menampilkan nol di belakang. Nilainya sama.
- Pada mode `-column`, angka rata kanan dan teks rata kiri.

### 6.4 Tugas 3 — RESTful API endpoint (`service.py`)

```python
from typing import List

from fastapi import Depends, FastAPI
from sqlmodel import Field, Session, SQLModel, create_engine, select


class Buku(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    kode: str
    judul: str
    tahun_terbit: int
    harga_sewa: float
    tersedia: bool


engine = create_engine("sqlite:///perpustakaan.db")


def get_session():
    with Session(engine) as session:
        yield session


app = FastAPI()


@app.get("/buku/", response_model=List[Buku])
def read_buku(session: Session = Depends(get_session)):
    statement = select(Buku)
    results = session.exec(statement).all()
    return results
```

(File utuh: [`kode/tugas/service.py`](kode/tugas/service.py). Pada log, bagian atasnya terpotong oleh prompt lanjutan.)

**Penjelasan kode:**

| Bagian | Penjelasan |
|---|---|
| `from typing import List` | Untuk tipe respons berupa daftar. Impor yang tidak terpakai (`Optional`, `HTTPException`) pada contoh modul dibuang. |
| `class Buku(SQLModel, table=True)` | Model sekaligus tabel. Nama kelas `Buku` otomatis menjadi nama tabel `buku`, cocok dengan tabel di `schema.sql`. |
| `id: int \| None = Field(default=None, primary_key=True)` | Primary key, pola yang sama dengan contoh modul. |
| `kode: str`, `judul: str` | Dipetakan ke kolom teks (`CHAR`/`VARCHAR` di SQLite). |
| `tahun_terbit: int` | Dipetakan ke `INT`. |
| `harga_sewa: float` | Dipetakan ke `FLOAT`. |
| `tersedia: bool` | Dipetakan ke `BOOLEAN`, diubah dari `1`/`0` menjadi `true`/`false` pada JSON. |
| `create_engine("sqlite:///perpustakaan.db")` | Koneksi ke database hasil `seed.py`. Nama file harus sama dengan `DB_FILE` di `seed.py`. |
| `get_session()` | Dependency penyedia sesi, dibuka dan ditutup per request. |
| `@app.get("/buku/", response_model=List[Buku])` | Endpoint `GET /buku/` yang mengembalikan daftar `Buku`. |
| `select(Buku)` + `session.exec(...).all()` | Mengambil semua baris tabel `buku`, setara `SELECT * FROM buku`. |

**Menjalankan dan log Uvicorn (dari log):**

```bash
uvicorn service:app --reload
```

```
INFO:     Will watch for changes in these directories: ['/Users/danel/modul8/tugas-buku']
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [48409] using WatchFiles
INFO:     Started server process [48411]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     127.0.0.1:51967 - "GET /buku/ HTTP/1.1" 200 OK
INFO:     127.0.0.1:51969 - "GET /buku/ HTTP/1.1" 200 OK
INFO:     127.0.0.1:51973 - "GET /buku/ HTTP/1.1" 200 OK
INFO:     Waiting for application shutdown.
INFO:     Application shutdown complete.
INFO:     Finished server process [48411]
INFO:     Stopping reloader process [48409]
```

**Pembahasan log:**

- Folder yang dipantau adalah `tugas-buku`, jadi service dijalankan dari folder yang tepat (berisi `perpustakaan.db`).
- Ada **tiga** request `GET /buku/` berstatus `200 OK`. Ketiganya sesuai tiga pengujian: Safari, `curl`, dan `curl ... | python3 -m json.tool`.
- Tidak ada baris `404` untuk `favicon.ico` pada log ini, semua permintaan yang tercatat berstatus `200 OK`.
- Server berhenti dengan rapi lewat `Ctrl+C` (urutan `Waiting for application shutdown` sampai `Stopping reloader process`).

### 6.5 Tugas 4 — Tampilkan hasil dengan curl dan Safari

Perintah yang dijalankan pada Terminal baru:

```bash
curl http://localhost:8000/buku/
curl -s http://localhost:8000/buku/ | python3 -m json.tool
```

`-s` (silent) menyembunyikan tabel progress curl. `python3 -m json.tool` memformat JSON sehingga rapi dan mudah dibaca.

### 6.6 Output akhir

**Safari** (`http://localhost:8000/buku/`):

![TUGAS Hasil curl dari tes Safari](image/TUGAS-Hasil%20curl%20dari%20tes%20Safari.png)

**Terminal** (`curl` biasa, lalu `curl -s ... | python3 -m json.tool`):

![TUGAS Hasil curl dari tes Terminal](image/TUGAS-Hasil%20curl%20dari%20tes%20Terminal.png)

Isi respons JSON (versi rapi dari `json.tool`):

```json
[
    {
        "id": 1,
        "tahun_terbit": 2021,
        "harga_sewa": 5000.0,
        "kode": "BK0001",
        "judul": "Pemrograman Python Dasar",
        "tersedia": true
    },
    {
        "id": 2,
        "tahun_terbit": 2019,
        "harga_sewa": 7500.5,
        "kode": "BK0002",
        "judul": "Sistem Terdistribusi",
        "tersedia": true
    },
    {
        "id": 3,
        "tahun_terbit": 2020,
        "harga_sewa": 6000.0,
        "kode": "BK0003",
        "judul": "Basis Data Lanjut",
        "tersedia": false
    },
    {
        "id": 4,
        "tahun_terbit": 2018,
        "harga_sewa": 5500.75,
        "kode": "BK0004",
        "judul": "Jaringan Komputer",
        "tersedia": true
    },
    {
        "id": 5,
        "tahun_terbit": 2023,
        "harga_sewa": 8000.25,
        "kode": "BK0005",
        "judul": "Kecerdasan Buatan",
        "tersedia": false
    }
]
```

**PDF dari Safari:** [`image/PDF/localhost-8000-buku.pdf`](image/PDF/localhost-8000-buku.pdf) (halaman endpoint `/buku/` diekspor dari Safari, A4, 1 halaman).

### 6.7 Pembahasan output Bagian B

- Endpoint mengembalikan **5 objek JSON**, sama dengan jumlah baris yang diisi `seed.py`.
- Tiap objek memiliki **6 field** sesuai kolom tabel: `id`, `tahun_terbit`, `harga_sewa`, `kode`, `judul`, `tersedia`.
- `tersedia` tampil `true`/`false` (boolean JSON), bukan `1`/`0` seperti di SQLite, karena FastAPI mengikuti tipe `bool` pada model `Buku`. Buku 1, 2, dan 4 tersedia, buku 3 dan 5 tidak.
- `harga_sewa` tampil `5000.0`, `7500.5`, `5500.75`: bilangan desimal (float), nol di belakang yang tidak berarti tidak ditulis.
- `kode` dan `judul` tampil sebagai string, `tahun_terbit` sebagai bilangan bulat.
- Gambar Terminal memperlihatkan dua perintah. Perintah pertama (`curl` biasa) menghasilkan satu baris JSON yang terlipat mengikuti lebar jendela. Perintah kedua (`| python3 -m json.tool`) menghasilkan JSON yang rapi dengan indentasi 4 spasi.
- Isi Safari dan curl identik, hanya tampilannya yang berbeda.

---

## 7. Perbandingan Safari, curl, dan PDF

| Aspek | Safari | curl (Terminal) | PDF dari Safari |
|---|---|---|---|
| Cara akses | Ketik URL di bilah alamat | `curl http://localhost:8000/...` | File > Export as PDF |
| Format tampilan | JSON mentah satu blok, mengikuti lebar jendela | Satu baris, atau rapi dengan `json.tool` | Teks JSON pada halaman A4 dengan judul URL dan tanggal |
| Permintaan tambahan | Meminta `/favicon.ico` (404 pada run kedua Bagian A) | Tidak ada | Tidak ada |
| Cocok untuk | Cek cepat secara visual | Pengujian dan otomasi (headless) | Bukti laporan |

Semua klien memanggil endpoint yang sama dan menerima data yang sama, yang merupakan inti arsitektur microservices: service tidak peduli siapa kliennya.

---

## 8. Kesimpulan

1. Microservices memisahkan *frontend* dari *backend* berupa service yang diakses lewat HTTP.
2. FastAPI dan SQLModel memungkinkan REST API ringkas: satu kelas model, satu fungsi sesi, satu fungsi endpoint.
3. Pada Bagian A, galat `table sdm already exists` membuat data dobel. Solusinya menghapus database lama sebelum membuat ulang. Pelajaran ini diterapkan di Bagian B lewat `DROP TABLE IF EXISTS`.
4. Tabel `buku` memenuhi syarat tugas: 1 primary key serta kolom INT, CHAR, VARCHAR, BOOLEAN, dan FLOAT.
5. Lima data diisi dengan script Python, ditampilkan lewat `GET /buku/`, dan terverifikasi dengan Safari, curl, dan PDF.
6. Memisahkan skema SQL, pengisian data, dan service membuat kode rapi dan mudah diulang.

---

## 9. Troubleshooting

| Masalah | Penyebab | Solusi |
|---|---|---|
| `table sdm already exists` dan data dobel | File `.db` sudah ada dari percobaan sebelumnya | `rm departemen-sdm.db` lalu buat ulang, atau pakai `DROP TABLE IF EXISTS` |
| `zsh: no matches found: fastapi[standard]` | zsh membaca `[...]` sebagai glob | Pakai tanda kutip: `"fastapi[standard]"` |
| `Address already in use` | Port 8000 dipakai proses lain | `Ctrl+C` pada server lama, atau `uvicorn service:app --reload --port 8001` |
| `no such table: buku` | `seed.py` belum dijalankan, atau service dijalankan dari folder lain | Jalankan `python seed.py` di folder yang sama dengan `service.py` |
| `ModuleNotFoundError: fastapi` | Venv belum aktif | `source .venv/bin/activate` |
| `GET /favicon.ico 404` | Safari meminta ikon tab | Abaikan, tidak memengaruhi hasil |
| Safari menampilkan JSON satu blok | Safari tidak memformat JSON | Normal. Untuk rapi gunakan `python3 -m json.tool` di Terminal |

---

## 10. Referensi

- Modul 8, *Arsitektur Microservices untuk Sistem Terdistribusi*. Praktikum Sistem Terdistribusi dan Terdesentralisasi, Dr. Bambang Purnomosidi D. P., Universitas Teknologi Digital Indonesia.
- Panduan praktis uv: https://github.com/NEO-X-School/notes/blob/main/uv/00.md
- FastAPI: https://fastapi.tiangolo.com
- SQLModel: https://sqlmodel.tiangolo.com
- SQLite: https://sqlite.org
- Uvicorn: https://www.uvicorn.org
