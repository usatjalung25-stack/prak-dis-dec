# GraphQL Book: Server & Client Python

Proyek belajar GraphQL sederhana yang terdiri dari:

- **Server GraphQL** (`run.py`) yang menyediakan data buku
- **Client Python** (`client.py`) yang mengambil daftar buku dari server

| Item | Nilai |
|------|-------|
| Endpoint | `http://127.0.0.1:8000/graphql` |
| Server | Uvicorn, port `8000` |
| GraphiQL (uji coba lewat browser) | Buka alamat endpoint yang sama |

---

## Daftar Isi

1. [Struktur Proyek](#struktur-proyek)
2. [Prasyarat](#prasyarat)
3. [Cara Menjalankan](#cara-menjalankan)
4. [Schema Type `Book`](#schema-type-book)
5. [Error yang Muncul dan Cara Mengatasinya](#error-yang-muncul-dan-cara-mengatasinya)
6. [Kode Client yang Sudah Diperbaiki](#kode-client-yang-sudah-diperbaiki)
7. [Dokumentasi Screenshot](#dokumentasi-screenshot)
8. [Troubleshooting](#troubleshooting)
9. [Pelajaran](#pelajaran)

---

## Struktur Proyek

```
.
├── run.py          # Server GraphQL
├── client.py       # Client Python
├── README.md
├── daftar-screenshot.png   # Gambar daftar file screenshot
└── GraphQL Client-0X.png   # Screenshot hasil percobaan
```

---

## Prasyarat

- Python 3
- Pustaka `requests` (untuk client)
- Dependensi server sesuai isi `run.py` (termasuk Uvicorn)

Cek versi Python:

```bash
python3 --version
```

---

## Cara Menjalankan

### 1. Install dependensi client

```bash
pip install requests
```

### 2. Jalankan server (Terminal 1)

```bash
cd ~
python3 run.py
```

Jika berhasil, muncul:

```
Server berhasil dijalankan!
Buka browser di: http://127.0.0.1:8000/graphql
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

Biarkan terminal ini tetap terbuka selama server dipakai.

### 3. Jalankan client (Terminal 2)

```bash
python3 client.py
```

### 4. Hentikan server

Tekan `CTRL+C` di Terminal 1.

---

## Schema Type `Book`

Hasil pengecekan schema (introspection) menunjukkan type `Book` hanya punya **dua field**:

| Field    | Keterangan   |
|----------|--------------|
| `title`  | Judul buku   |
| `author` | Penulis buku |

Cek lewat GraphiQL:

```graphql
{
  __type(name: "Book") {
    fields {
      name
    }
  }
}
```

Atau lewat terminal:

```bash
curl -s -X POST http://127.0.0.1:8000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __type(name: \"Book\") { fields { name } } }"}' | python3 -m json.tool
```

Hasil:

```json
{
  "data": {
    "__type": {
      "fields": [
        { "name": "title" },
        { "name": "author" }
      ]
    }
  }
}
```

---

## Error yang Muncul dan Cara Mengatasinya

### Gejala

Query awal meminta field `isbn`:

```graphql
{
  books {
    isbn
    title
    author
  }
}
```

Respons server:

```json
{
  "data": null,
  "errors": [
    {
      "message": "Cannot query field 'isbn' on type 'Book'.",
      "locations": [{ "line": 3, "column": 5 }]
    }
  ]
}
```

Log di terminal server menampilkan error yang sama:

```
Cannot query field 'isbn' on type 'Book'.

GraphQL request:3:5
2 |   books {
3 |     isbn
  |     ^
4 |     title
```

### Penyebab

Field `isbn` **tidak ada** di type `Book` pada schema server. Di GraphQL, client hanya boleh meminta field yang sudah didefinisikan di schema. Jika ada satu field yang tidak dikenal, **seluruh query ditolak** dan `data` menjadi `null`.

> Catatan: HTTP status tetap `200 OK` walaupun query salah. Error GraphQL dikirim di dalam body JSON pada key `errors`.

### Solusi 1: Hapus `isbn` dari query (tercepat)

```graphql
{
  books {
    title
    author
  }
}
```

Lewat curl:

```bash
curl -s -X POST http://127.0.0.1:8000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ books { title author } }"}' | python3 -m json.tool
```

### Solusi 2: Tambahkan field `isbn` di server

Jika data ISBN memang dibutuhkan, tambahkan field `isbn` pada definisi type `Book` di `run.py` (beserta datanya), lalu **restart server**:

1. Hentikan server dengan `CTRL+C`
2. Jalankan lagi: `python3 run.py`

Tanpa restart, server masih memakai schema lama dan error yang sama akan tetap muncul.

---

## Kode Client yang Sudah Diperbaiki

File `client.py`:

```python
import json
import requests

URL = "http://127.0.0.1:8000/graphql"

# Hanya field yang ada di schema: title dan author
query = """
{
    books {
        title
        author
    }
}
"""

print("Mengirim query ke server GraphQL...")
try:
    response = requests.post(URL, json={"query": query}, timeout=5)
    response.raise_for_status()

    result = response.json()

    # GraphQL membalas HTTP 200 meski query salah,
    # jadi key "errors" harus dicek sendiri.
    if "errors" in result:
        print("\nServer menolak query:")
        for err in result["errors"]:
            print(" -", err["message"])
    else:
        print("\nBerhasil. Berikut adalah data dari server:")
        print(json.dumps(result, indent=2))

except requests.exceptions.ConnectionError:
    print("\nGagal terhubung ke server.")
    print("Pastikan server sudah dijalankan dengan 'python3 run.py'")
except Exception as e:
    print(f"\nTerjadi kesalahan: {e}")
```

---

## Dokumentasi Screenshot

Berikut daftar file screenshot yang ada di repository:

![Daftar file screenshot](daftar-screenshot.png)

> Sesuaikan keterangan di bawah dengan isi gambar masing-masing.

**1. Server berhasil dijalankan**

![GraphQL Client 01](GraphQL%20Client%20-01.png)

**2. Client mengirim query**

![GraphQL Client 02](GraphQL%20Client-02.png)

**3. Error / pengecekan schema**

![GraphQL Client 03](GraphQL%20Client-03.png)

**4. Hasil akhir setelah diperbaiki**

![GraphQL Client 04](GraphQL%20Client-04.png)

---

## Troubleshooting

| Masalah | Penyebab | Solusi |
|---------|----------|--------|
| `Cannot query field 'isbn' on type 'Book'` | Field tidak ada di schema | Hapus field dari query, atau tambahkan di server lalu restart |
| `"data": null` padahal HTTP 200 | Query tidak valid | Baca isi `errors` pada respons |
| `Gagal terhubung ke server` | Server belum jalan | Jalankan `python3 run.py` di terminal lain |
| Perubahan schema tidak terlihat | Server belum di-restart | `CTRL+C`, lalu `python3 run.py` lagi |
| `ModuleNotFoundError: No module named 'requests'` | Dependensi belum terpasang | `pip install requests` |
| `Address already in use` (port 8000) | Port dipakai proses lain | Hentikan proses lama (`CTRL+C`) atau ganti port di `run.py` |

---

## Pelajaran

1. Schema adalah kontrak antara server dan client.
2. Gunakan introspection (`__type`) untuk melihat field yang tersedia sebelum menulis query.
3. Di GraphQL, HTTP 200 tidak menjamin berhasil; selalu cek `errors`.
4. Restart server setiap kali schema diubah.
