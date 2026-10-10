# GraphQL Book: Server & Client Python

Proyek belajar GraphQL sederhana: sebuah **server GraphQL** yang menyediakan data buku dan sebuah **client Python** yang mengambil data tersebut lewat query. Dokumen ini membahas cara menjalankan proyek, hasil percobaan (lengkap dengan screenshot), error yang muncul, dan cara mengatasinya.

| Item | Keterangan |
|------|------------|
| Server | `run.py` (Uvicorn, port `8000`) |
| Client | `client.py` (Python + `requests`) |
| Endpoint | `http://127.0.0.1:8000/graphql` |
| GraphiQL | Buka alamat endpoint di browser untuk uji coba query |

---

## Daftar Isi

1. [Konsep Singkat](#konsep-singkat)
2. [Struktur Proyek](#struktur-proyek)
3. [Prasyarat](#prasyarat)
4. [Cara Menjalankan](#cara-menjalankan)
5. [Pembahasan Hasil Percobaan](#pembahasan-hasil-percobaan)
6. [Analisis Error](#analisis-error)
7. [Cara Mengatasi Error](#cara-mengatasi-error)
8. [Kode Client](#kode-client)
9. [Troubleshooting](#troubleshooting)
10. [Kesimpulan](#kesimpulan)

---

## Konsep Singkat

| Istilah | Arti |
|---------|------|
| **Schema** | Daftar type dan field yang disediakan server. Ini adalah "kontrak" antara server dan client. |
| **Query** | Permintaan data dari client. Client memilih sendiri field yang ingin diambil. |
| **Introspection** | Fitur untuk bertanya ke server tentang schema-nya sendiri, misalnya lewat `__type`. |
| **GraphiQL** | Antarmuka web untuk menulis dan menjalankan query langsung di browser. |

Alur kerja proyek ini:

```
client.py / curl / GraphiQL  --(POST query)-->  Server GraphQL (run.py)
                             <--(JSON data atau errors)--
```

---

## Struktur Proyek

```
.
├── run.py            # Server GraphQL
├── client.py         # Client Python
├── README.md         # Dokumentasi ini
└── images/           # Screenshot hasil percobaan
    ├── GraphQL Client -01.png
    ├── GraphQL Client-02.png
    ├── GraphQL Client-03.png
    └── GraphQL Client-04.png
```

---

## Prasyarat

- Python 3 (cek dengan `python3 --version`)
- Pustaka `requests` untuk client
- Dependensi server sesuai isi `run.py` (termasuk Uvicorn)
- `curl` (opsional, untuk uji cepat dari terminal)

---

## Cara Menjalankan

Gunakan **dua terminal**: satu untuk server, satu untuk client.

### 1. Install dependensi client

```bash
pip install requests
```

### 2. Jalankan server (Terminal 1)

```bash
cd ~
python3 run.py
```

> Jalankan dari folder tempat `run.py` berada. Contoh di atas memakai folder home (`~`).

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

### 5. Cek cepat bahwa server hidup

```bash
curl -s -X POST http://127.0.0.1:8000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __typename }"}'
```

Jika server hidup, hasilnya berisi `"data"` (bukan pesan gagal terhubung).

---

## Pembahasan Hasil Percobaan

### 1. Server dijalankan dan menerima request

![GraphQL Client 01](https://github.com/usatjalung25-stack/prak-dis-dec/blob/f319014562c504b502cc9ca2285fdb81e4630304/02%20/images/GraphQL%20Client%20-01.png?raw=true)

Yang terlihat pada gambar:

- Perintah `cd ~` lalu `python3 run.py`.
- Pesan `Server berhasil dijalankan!` dan alamat `http://127.0.0.1:8000/graphql`.
- Uvicorn aktif (`Application startup complete`) di `0.0.0.0:8000`.
- Setiap request tercatat sebagai `POST /graphql HTTP/1.1" 200 OK`.
- Di sela-sela log, ada pesan `Cannot query field 'isbn' on type 'Book'.` beserta posisi kesalahan (`4:9`, `3:5`, `1:11`).

Pembahasan: server berjalan normal. Status `200 OK` muncul di semua request, termasuk yang gagal, karena GraphQL mengirim error di dalam body JSON, bukan lewat status HTTP. Posisi `baris:kolom` menunjuk tepat ke field `isbn` yang bermasalah (tanda `^` pada log).

### 2. Cek schema lewat curl dan jalankan client

![GraphQL Client 02](https://github.com/usatjalung25-stack/prak-dis-dec/blob/f319014562c504b502cc9ca2285fdb81e4630304/02%20/images/GraphQL%20Client-02.png?raw=true)

Yang terlihat pada gambar:

- Introspection lewat `curl` dengan query `__type(name: "Book")` menghasilkan dua field: `title` dan `author`.
- `client.py` dibuat lewat `cat > client.py << 'EOF'` dan masih meminta field `isbn`.
- Saat `python3 client.py` dijalankan, client mencetak `Berhasil. Berikut adalah data dari server:`, tetapi isinya `"data": null` dan `errors` berisi `Cannot query field 'isbn' on type 'Book'` (baris 4, kolom 9).
- Query yang sama lewat `curl` juga gagal (baris 1, kolom 11).

Pembahasan: ada dua temuan.

1. Schema `Book` hanya punya `title` dan `author`, sehingga permintaan `isbn` pasti ditolak.
2. Client versi awal **tidak memeriksa key `errors`**. Karena HTTP-nya `200`, client menganggap semuanya berhasil dan mencetak "Berhasil" padahal datanya `null`. Ini bug pada client dan sudah diperbaiki di bagian [Kode Client](#kode-client).

### 3. Introspection di GraphiQL

![GraphQL Client 03](https://github.com/usatjalung25-stack/prak-dis-dec/blob/f319014562c504b502cc9ca2285fdb81e4630304/02%20/images/GraphQL%20Client-03.png?raw=true)

Yang terlihat pada gambar:

- Query di panel kiri:

  ```graphql
  {
    __type(name: "Book") {
      fields {
        name
      }
    }
  }
  ```

- Hasil di panel kanan: `data.__type.fields` berisi `title` dan `author`.

Pembahasan: ini cara paling mudah untuk memastikan field apa saja yang boleh diminta. Hasilnya sama dengan pengecekan lewat `curl` pada gambar 2, jadi schema terkonfirmasi hanya punya dua field.

### 4. Error `isbn` di GraphiQL

![GraphQL Client 04](https://github.com/usatjalung25-stack/prak-dis-dec/blob/f319014562c504b502cc9ca2285fdb81e4630304/02%20/images/GraphQL%20Client-04.png?raw=true)

Yang terlihat pada gambar:

- Query di panel kiri meminta `isbn`, `title`, dan `author` pada `books`. Kata `isbn` bergaris merah bergelombang.
- Hasil di panel kanan: `"data": null` dan pesan `Cannot query field 'isbn' on type 'Book'.` pada `line: 3`, `column: 5`.

Pembahasan: GraphiQL sudah menandai field yang tidak dikenal sebelum query dijalankan (garis merah). Ini petunjuk cepat bahwa query tidak sesuai schema. Lokasi error (3:5) cocok dengan posisi `isbn` pada editor.

---

## Analisis Error

Pesan error:

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

| Pertanyaan | Jawaban |
|------------|---------|
| Apa penyebabnya? | Field `isbn` tidak ada di type `Book` pada schema server. |
| Kenapa `data` jadi `null`? | GraphQL memvalidasi query sebelum dijalankan. Satu field tidak dikenal membuat **seluruh query ditolak**, termasuk `title` dan `author`. |
| Kenapa HTTP tetap `200 OK`? | Error GraphQL dikirim di body JSON (key `errors`), bukan lewat status HTTP. |
| Kenapa client lama bilang "Berhasil"? | Client hanya memeriksa status HTTP dan tidak membaca key `errors`. |
| Di mana letak kesalahannya? | Pada `locations`: nomor baris dan kolom field yang bermasalah di dalam query. |

---

## Cara Mengatasi Error

Pilih salah satu solusi, tergantung apakah data ISBN memang dibutuhkan.

### Solusi 1: Hapus `isbn` dari query (tercepat)

Pakai hanya field yang ada di schema:

```graphql
{
  books {
    title
    author
  }
}
```

Uji lewat curl:

```bash
curl -s -X POST http://127.0.0.1:8000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ books { title author } }"}' | python3 -m json.tool
```

Atau ubah `client.py` seperti pada bagian [Kode Client](#kode-client), lalu jalankan `python3 client.py`.

### Solusi 2: Tambahkan field `isbn` di server

Jika ISBN memang dibutuhkan, schema di `run.py` yang harus diubah.

1. Buka `run.py` dan cari definisi type `Book`.
2. Tambahkan field `isbn` bertipe string pada type tersebut.
3. Tambahkan nilai `isbn` pada setiap data buku.
4. Simpan file, lalu **restart server**:
   - Tekan `CTRL+C` di Terminal 1
   - Jalankan lagi: `python3 run.py`
5. Cek ulang schema dengan query introspection. Hasilnya harus memuat `isbn`, `title`, dan `author`.
6. Jalankan ulang query yang memakai `isbn`.

> Cara menulis field mengikuti library GraphQL yang dipakai di `run.py`. Prinsipnya sama: field harus terdaftar di type `Book` **dan** datanya harus tersedia.
>
> Tanpa restart, server masih memakai schema lama dan error yang sama akan tetap muncul.

### Checklist verifikasi

- [ ] Server berjalan dan log menampilkan `Application startup complete`
- [ ] Introspection `__type(name: "Book")` menampilkan field yang dibutuhkan
- [ ] Query hanya memakai field yang ada di hasil introspection
- [ ] Respons berisi `"data"` yang tidak `null` dan tidak ada key `errors`
- [ ] `python3 client.py` mencetak data buku, bukan pesan `Server menolak query`

---

## Kode Client

`client.py` versi perbaikan. Perbedaan dengan versi awal:

- Hanya meminta field yang ada di schema (`title`, `author`).
- Memeriksa key `errors` pada respons, sehingga pesan sukses tidak muncul saat query ditolak.

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

Membuat file langsung dari terminal (seperti pada screenshot 2):

```bash
cat > client.py << 'EOF'
# tempel kode client di atas, lalu akhiri dengan baris EOF
