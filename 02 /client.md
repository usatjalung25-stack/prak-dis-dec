# GraphQL Book: Server & Client Python

Proyek belajar GraphQL sederhana: sebuah **server GraphQL** (dijalankan dengan `python3 run.py`) dan sebuah **client Python** (`client.py`) yang mengambil daftar buku dari server.

- Endpoint server: `http://127.0.0.1:8000/graphql`
- Server berjalan memakai Uvicorn di port `8000`
- Antarmuka uji coba (GraphiQL) bisa dibuka lewat browser di alamat endpoint yang sama

---

## Cara Menjalankan

**1. Install dependensi client**

```bash
pip install requests
```

**2. Jalankan server (Terminal 1)**

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

**3. Jalankan client (Terminal 2)**

```bash
python3 client.py
```

---

## Schema Type `Book`

Hasil pengecekan schema (introspection) menunjukkan type `Book` hanya punya **dua field**:

| Field    | Keterangan     |
|----------|----------------|
| `title`  | Judul buku     |
| `author` | Penulis buku   |

Cek sendiri di GraphiQL atau terminal:

```graphql
{
  __type(name: "Book") {
    fields {
      name
    }
  }
}
```

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

## Error yang Muncul

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

Log di terminal server juga menampilkan error yang sama:

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

Catatan: HTTP status tetap `200 OK` walaupun query salah. Error GraphQL dikirim di dalam body JSON pada key `errors`.

---

## Solusi

### Solusi 1: Hapus `isbn` dari query (cara tercepat)

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

## Kode Client (`client.py`) yang Sudah Diperbaiki

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

## Troubleshooting

| Masalah | Penyebab | Solusi |
|---------|----------|--------|
| `Cannot query field 'isbn' on type 'Book'` | Field tidak ada di schema | Hapus field dari query, atau tambahkan di server lalu restart |
| `"data": null` padahal HTTP 200 | Query tidak valid | Baca isi `errors` pada respons |
| `Gagal terhubung ke server` | Server belum jalan | Jalankan `python3 run.py` di terminal lain |
| Perubahan schema tidak terlihat | Server belum di-restart | `CTRL+C`, lalu `python3 run.py` lagi |

---

## Pelajaran

1. Schema adalah kontrak antara server dan client.
2. Gunakan introspection (`__type`) untuk melihat field yang tersedia sebelum menulis query.
3. Di GraphQL, HTTP 200 tidak menjamin berhasil; selalu cek `errors`.
4. Restart server setiap kali schema diubah.
