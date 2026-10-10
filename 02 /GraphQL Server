# Praktik 2.1 – Menggunakan Strawberry untuk GraphQL Server

Modul 2 – Praktikum Sistem Terdistribusi dan Tersentralisasi
Program Studi Informatika – Universitas Teknologi Digital Indonesia

Repositori ini berisi langkah-langkah menjalankan **GraphQL server** menggunakan **Strawberry GraphQL** (Python), lengkap dengan contoh output, penjelasan, dan solusi jika terjadi error.

---

## Daftar Isi

1. [Tujuan](#1-tujuan)
2. [Prasyarat](#2-prasyarat)
3. [Langkah 1 – Instalasi Paket](#3-langkah-1--instalasi-paket)
4. [Langkah 2 – Membuat `schema.py`](#4-langkah-2--membuat-schemapy)
5. [Langkah 3 – Menjalankan Server](#5-langkah-3--menjalankan-server)
6. [Langkah 4 – Membuka GraphiQL di Browser](#6-langkah-4--membuka-graphiql-di-browser)
7. [Langkah 5 – Menulis dan Menjalankan Query](#7-langkah-5--menulis-dan-menjalankan-query)
8. [Pembahasan Output](#8-pembahasan-output)
9. [Menghentikan Server](#9-menghentikan-server)
10. [Troubleshooting (Cara Mengatasi Error)](#10-troubleshooting-cara-mengatasi-error)
11. [Struktur Repositori](#11-struktur-repositori)

---

## 1. Tujuan

- Memahami cara kerja GraphQL sebagai alternatif REST API.
- Mampu membuat schema sederhana dengan Strawberry.
- Mampu menjalankan server GraphQL dan mengujinya melalui antarmuka **GraphiQL**.
- Mampu membaca log server dan menangani error umum.

## 2. Prasyarat

| Kebutuhan | Keterangan |
|---|---|
| Python | Versi 3.10+ (modul menganjurkan versi terbaru; praktik ini diuji pada Python 3.13) |
| pip atau uv | Pengelola paket Python |
| Browser | Chrome / Firefox / Safari |
| Terminal | Terminal macOS / Linux, atau PowerShell / CMD di Windows |

Cek versi Python:

```bash
python3 --version
```

Contoh output:

```
Python 3.13.x
```

> **Disarankan:** gunakan *virtual environment* agar paket tidak bercampur dengan sistem.
>
> ```bash
> python3 -m venv .venv
> source .venv/bin/activate        # macOS / Linux
> # .venv\Scripts\activate         # Windows
> ```

---

## 3. Langkah 1 – Instalasi Paket

### Cara A – Sesuai modul (menggunakan `uv`)

```bash
uv pip install "strawberry-graphql[cli]"
```

Opsi `[cli]` ikut memasang dependensi tambahan (`libcst`, `typer`, `rich`, `pygments`, dll.) yang dibutuhkan perintah `strawberry dev`.

### Cara B – Menggunakan `pip` + FastAPI (yang dipakai pada praktik ini)

```bash
python3 -m pip install strawberry-graphql fastapi uvicorn
```

Contoh output (dipersingkat):

```
Collecting strawberry-graphql
...
Installing collected packages: ...
Successfully installed fastapi-0.143.0 strawberry-graphql-0.332.0 uvicorn-0.54.0 ...
```

### Penjelasan paket

| Paket | Fungsi |
|---|---|
| `strawberry-graphql` | Library utama untuk mendefinisikan schema GraphQL dengan Python type hints |
| `fastapi` | Framework web yang menjadi "rumah" bagi endpoint GraphQL (Cara B) |
| `uvicorn` | ASGI server yang menjalankan aplikasi |
| `typer`, `rich`, `click` | Dependensi CLI Strawberry |
| `libcst` | Dibutuhkan oleh `strawberry dev` / `schema_codegen` |

> **Catatan peringatan PATH.** Saat instalasi mungkin muncul:
> ```
> WARNING: The script uvicorn is installed in '/Library/Frameworks/Python.framework/Versions/3.13/bin' which is not on PATH.
> ```
> Ini hanya peringatan, **bukan error**. Selama server dijalankan dengan `python3 ...` atau `python3 -m ...`, program tetap bisa berjalan. Solusi permanen ada di [bagian Troubleshooting](#error-4--warning-script-is-not-on-path).

---

## 4. Langkah 2 – Membuat `schema.py`

Buat file `schema.py` di folder kerja:

```python
import typing
import strawberry


@strawberry.type
class Book:
    title: str
    author: str


def get_books() -> typing.List[Book]:
    return [
        Book(title="The Great Gatsby", author="F. Scott Fitzgerald"),
    ]


@strawberry.type
class Query:
    books: typing.List[Book] = strawberry.field(resolver=get_books)


schema = strawberry.Schema(query=Query)
```

### Penjelasan kode

- `@strawberry.type class Book` – mendefinisikan **tipe data** `Book` dengan field `title` dan `author`.
- `get_books()` – *resolver*, yaitu fungsi yang mengembalikan data ketika field `books` diminta.
- `class Query` – pintu masuk semua query GraphQL. Field `books` mengembalikan daftar `Book`.
- `schema = strawberry.Schema(query=Query)` – objek schema yang dibaca oleh server (nama variabel `schema` harus sama dengan yang dipanggil di `run.py`).

---

## 5. Langkah 3 – Menjalankan Server

Ada dua cara menjalankan server. Pilih salah satu.

### Cara A – Strawberry CLI (sesuai modul)

```bash
strawberry dev schema
```

> Jika `strawberry` tidak dikenali, gunakan `python3 -m strawberry dev schema`.
> Jika muncul `ModuleNotFoundError: No module named 'libcst'`, lihat [Error 1](#error-1--modulenotfounderror-no-module-named-libcst).

Contoh output yang benar:

```
Running strawberry on http://0.0.0.0:8000/graphql 🍓
```

### Cara B – Script `run.py` (FastAPI + Uvicorn)

Buat file `run.py` dengan perintah berikut (atau salin isinya secara manual):

```bash
cat << 'EOF' > run.py
import uvicorn
from fastapi import FastAPI
from strawberry.fastapi import GraphQLRouter
import schema

app = FastAPI()
graphql_app = GraphQLRouter(schema.schema)
app.include_router(graphql_app, prefix="/graphql")

if __name__ == "__main__":
    print("✅ Server berhasil dijalankan!")
    print("🌐 Buka browser di: http://127.0.0.1:8000/graphql")
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF
```

Jalankan:

```bash
python3 run.py
```

Contoh output:

```
✅ Server berhasil dijalankan!
🌐 Buka browser di: http://127.0.0.1:8000/graphql
INFO:     Started server process [14570]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

### Penjelasan output server

| Baris log | Arti |
|---|---|
| `Started server process [14570]` | Proses server dimulai dengan PID 14570 |
| `Waiting for application startup.` | Aplikasi sedang inisialisasi |
| `Application startup complete.` | Aplikasi siap menerima request |
| `Uvicorn running on http://0.0.0.0:8000` | Server aktif di semua interface jaringan, port 8000 |

> **Terminal tidak boleh ditutup** selama server dipakai. Terminal akan "menggantung" karena server berjalan terus (ini normal).

---

## 6. Langkah 4 – Membuka GraphiQL di Browser

Buka salah satu alamat berikut di browser:

- http://127.0.0.1:8000/graphql
- http://localhost:8000/graphql

> Alamat `0.0.0.0` hanya berarti "dengar di semua interface". Di browser gunakan `127.0.0.1` atau `localhost`.

Tampilan **GraphiQL**: sisi kiri adalah editor query, sisi kanan adalah hasil (response).

![Tampilan GraphiQL](GraphiQL-01.png)

Log server saat halaman dibuka:

```
INFO:     127.0.0.1:50686 - "GET /graphql HTTP/1.1" 200 OK
INFO:     127.0.0.1:50686 - "POST /graphql HTTP/1.1" 200 OK
INFO:     127.0.0.1:50686 - "GET /favicon.ico HTTP/1.1" 404 Not Found
```

**Pembahasan:**

- `GET /graphql ... 200 OK` → halaman GraphiQL berhasil dimuat.
- `POST /graphql ... 200 OK` → GraphiQL mengirim query (misalnya *introspection*) ke server.
- `GET /favicon.ico ... 404 Not Found` → **normal dan aman diabaikan**. Browser otomatis meminta ikon tab, sedangkan server memang tidak menyediakannya.

---

## 7. Langkah 5 – Menulis dan Menjalankan Query

Pada panel kiri GraphiQL, tulis query berikut:

```graphql
{
  books {
    title
    author
  }
}
```

Klik tombol **Run (▶)**.

![Menulis query di GraphiQL](GraphiQL-02.png)

### Output yang diharapkan (panel kanan)

```json
{
  "data": {
    "books": [
      {
        "title": "The Great Gatsby",
        "author": "F. Scott Fitzgerald"
      }
    ]
  }
}
```

![Hasil query di GraphiQL](GraphiQL-03.png)

### Log server saat query dijalankan

```
INFO:     127.0.0.1:50714 - "POST /graphql HTTP/1.1" 200 OK
```

### Contoh query lain

Hanya meminta judul (GraphQL hanya mengembalikan field yang diminta):

```graphql
{
  books {
    title
  }
}
```

Output:

```json
{
  "data": {
    "books": [
      { "title": "The Great Gatsby" }
    ]
  }
}
```

---

## 8. Pembahasan Output

### 8.1 Struktur response GraphQL

| Bagian | Penjelasan |
|---|---|
| `data` | Berisi hasil query yang sukses. Bentuknya **sama persis** dengan bentuk query. |
| `books` | Nama field pada `Query`; nilainya berupa array karena tipenya `List[Book]`. |
| `title`, `author` | Field yang diminta pada query. Field yang tidak diminta tidak akan dikirim. |
| `errors` | Muncul hanya jika terjadi kesalahan (misalnya field tidak ada). |

### 8.2 Keunggulan GraphQL dibanding REST (terlihat dari praktik ini)

- **Satu endpoint** (`/graphql`) untuk semua kebutuhan data.
- **Client menentukan data** yang diambil (tidak ada *over-fetching*): jika hanya `title` yang diminta, `author` tidak dikirim.
- **Self-documenting**: GraphiQL dapat menampilkan dokumentasi schema otomatis (tab *Docs* / *Explorer*).

### 8.3 Mengapa semua request berstatus `200 OK`?

Pada GraphQL, request yang **gagal secara logika query** (mis. sintaks salah) tetap dikembalikan dengan HTTP `200 OK`, sedangkan detail kesalahannya ada di key `errors` pada body JSON. Jadi, periksa isi response, bukan hanya status HTTP.

### 8.4 Penjelasan pesan `Syntax Error: Unexpected <EOF>`

Pada log praktik muncul:

```
Syntax Error: Unexpected <EOF>.

GraphQL request:26:2
25 | #   Auto Complete:  Ctrl-Space (or just start typing)
26 | #
   |  ^
27 |
INFO:     127.0.0.1:50699 - "POST /graphql HTTP/1.1" 200 OK
```

**Artinya:** server menerima query yang isinya hanya komentar (baris yang diawali `#`) atau kosong, sehingga parser GraphQL menemukan akhir teks (`EOF` = *End Of File*) sebelum menemukan perintah query yang valid.

**Penyebab umum:**

- GraphiQL mengirim isi editor yang masih berupa teks komentar bawaan (petunjuk penggunaan) atau kosong.
- Query belum selesai ditulis (kurung `{` belum ditutup).
- Klik **Run** sebelum mengetik query.

**Apakah berbahaya?** Tidak. Ini hanya pesan validasi dan server tetap berjalan normal. Hapus komentar bawaan atau tulis query yang lengkap, lalu jalankan lagi.

---

## 9. Menghentikan Server

Tekan **`Ctrl + C`** pada terminal tempat server berjalan.

Contoh output:

```
^CINFO:     Shutting down
INFO:     Waiting for application shutdown.
INFO:     Application shutdown complete.
INFO:     Finished server process [14570]
```

---

## 10. Troubleshooting (Cara Mengatasi Error)

### Error 1 – `ModuleNotFoundError: No module named 'libcst'`

**Gejala:**

```
ModuleNotFoundError: No module named 'libcst'
...
strawberry.exceptions.missing_dependencies.MissingOptionalDependenciesError
```

**Penyebab:** Strawberry dipasang tanpa *extras* CLI, sehingga `libcst` tidak ikut terpasang. Perintah `strawberry dev` membutuhkannya.

**Solusi (pilih salah satu):**

```bash
# 1. Pasang Strawberry beserta extras CLI (disarankan)
python3 -m pip install "strawberry-graphql[cli]"

# 2. Atau pasang libcst saja
python3 -m pip install libcst

# 3. Atau lewati CLI dan jalankan lewat run.py (Cara B)
python3 run.py
```

---

### Error 2 – `ModuleNotFoundError: No module named 'schema'` / `'strawberry'` / `'fastapi'`

**Penyebab:**

- `run.py` tidak berada satu folder dengan `schema.py`.
- Paket belum terpasang, atau terpasang pada Python yang berbeda dengan yang dipakai menjalankan script.

**Solusi:**

```bash
ls                                   # pastikan run.py dan schema.py ada di folder yang sama
python3 -m pip install strawberry-graphql fastapi uvicorn
python3 -m pip list | grep -i -E "strawberry|fastapi|uvicorn"
```

Selalu gunakan pasangan `python3 -m pip` dan `python3` agar versi Python-nya konsisten. Jika memakai virtual environment, pastikan sudah diaktifkan (`source .venv/bin/activate`).

---

### Error 3 – `Address already in use` / `[Errno 48]`

**Gejala:**

```
ERROR:    [Errno 48] error while attempting to bind on address ('0.0.0.0', 8000): address already in use
```

**Penyebab:** Port 8000 sedang dipakai proses lain (biasanya server sebelumnya yang belum dihentikan).

**Solusi:**

```bash
# macOS / Linux: cari proses di port 8000
lsof -i :8000
# hentikan prosesnya (ganti PID sesuai hasil di atas)
kill -9 <PID>
```

Atau jalankan di port lain dengan mengubah `port=8000` menjadi `port=8001` pada `run.py`, lalu buka `http://127.0.0.1:8001/graphql`.

---

### Error 4 – `WARNING: The script ... is not on PATH`

**Gejala:**

```
WARNING: The script uvicorn is installed in '/Library/Frameworks/Python.framework/Versions/3.13/bin' which is not on PATH.
```

**Penyebab:** Folder tempat pip meletakkan perintah (`uvicorn`, `strawberry`, `fastapi`, dll.) belum masuk ke `PATH`.

**Solusi:**

- Cara cepat: jalankan lewat modul Python, misalnya `python3 -m strawberry dev schema` atau `python3 run.py`.
- Cara permanen (macOS, shell zsh):

```bash
echo 'export PATH="/Library/Frameworks/Python.framework/Versions/3.13/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Setelah itu perintah `strawberry dev schema` bisa dipanggil langsung.

---

### Error 5 – `command not found: strawberry`

**Penyebab:** Paket belum terpasang, virtual environment belum aktif, atau `PATH` belum diatur (lihat Error 4).

**Solusi:**

```bash
python3 -m pip install "strawberry-graphql[cli]"
python3 -m strawberry dev schema
```

---

### Error 6 – Halaman browser tidak bisa dibuka (`This site can't be reached`)

**Penyebab & solusi:**

| Penyebab | Solusi |
|---|---|
| Server belum jalan / sudah berhenti | Jalankan ulang `python3 run.py` dan pastikan ada log `Application startup complete.` |
| Memakai alamat `0.0.0.0` di browser | Ganti dengan `http://127.0.0.1:8000/graphql` atau `http://localhost:8000/graphql` |
| Lupa `/graphql` di akhir URL | Gunakan alamat lengkap `http://127.0.0.1:8000/graphql` |
| Port berbeda | Samakan port di URL dengan port di `run.py` |
| Firewall memblokir | Izinkan Python pada pengaturan firewall |

---

### Error 7 – `Syntax Error: Unexpected <EOF>` (di log server)

**Solusi:** Hapus komentar bawaan di editor GraphiQL dan tulis query lengkap:

```graphql
{
  books {
    title
    author
  }
}
```

Pastikan jumlah kurung `{` dan `}` seimbang. Penjelasan lengkap ada di [bagian 8.4](#84-penjelasan-pesan-syntax-error-unexpected-eof).

---

### Error 8 – `Cannot query field "xxx" on type "Query"`

**Gejala (muncul di panel kanan GraphiQL):**

```json
{
  "errors": [
    {
      "message": "Cannot query field 'book' on type 'Query'. Did you mean 'books'?"
    }
  ]
}
```

**Penyebab:** Nama field pada query tidak ada di schema (salah ketik, atau huruf besar/kecil berbeda; GraphQL bersifat *case-sensitive*).

**Solusi:** Gunakan nama field persis seperti di `schema.py` (`books`, `title`, `author`), atau lihat daftar field yang tersedia pada tab **Docs** di GraphiQL.

---

### Error 9 – Perubahan di `schema.py` tidak muncul

**Penyebab:** Server dijalankan tanpa *auto-reload*.

**Solusi:** Hentikan server (`Ctrl + C`), lalu jalankan ulang. Untuk *auto-reload* dengan Strawberry CLI gunakan `strawberry dev schema` (yang sudah memantau perubahan file). Pada `run.py` gunakan:

```python
uvicorn.run("run:app", host="0.0.0.0", port=8000, reload=True)
```

---

## 11. Struktur Repositori

```
.
├── README.md
├── schema.py          # Definisi schema GraphQL (Book, Query)
├── run.py             # Script menjalankan server (FastAPI + Uvicorn)
├── GraphiQL-01.png    # Tangkapan layar: tampilan awal GraphiQL
├── GraphiQL-02.png    # Tangkapan layar: query di editor
└── GraphiQL-03.png    # Tangkapan layar: hasil query
```

---

## Ringkasan Perintah Cepat

```bash
python3 -m pip install strawberry-graphql fastapi uvicorn   # 1. instal
# 2. buat schema.py dan run.py (lihat bagian 4 dan 5)
python3 run.py                                              # 3. jalankan server
# 4. buka http://127.0.0.1:8000/graphql, jalankan query books { title author }
# 5. Ctrl + C untuk menghentikan server
```
