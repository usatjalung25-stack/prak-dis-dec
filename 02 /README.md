# 🚀 proyek-saya: Setup Proyek Python dengan `uv`

Dokumentasi langkah demi langkah penyiapan proyek Python menggunakan **[uv](https://docs.astral.sh/uv/)**, sebuah *package & project manager* Python yang sangat cepat, ditulis dengan Rust oleh Astral.

Seluruh perintah di bawah ini dijalankan di **macOS (Intel / `x86_64`)** menggunakan terminal **zsh**.

---

## 📑 Daftar Isi

1. [Ringkasan](#-ringkasan)
2. [Prasyarat](#-prasyarat)
3. [Penjelasan Setiap Perintah](#-penjelasan-setiap-perintah)
4. [Pembahasan](#-pembahasan)
5. [Cara Cepat (Quick Start)](#-cara-cepat-quick-start)
6. [Struktur Proyek Akhir](#-struktur-proyek-akhir)
7. [Cheat Sheet](#-cheat-sheet)
8. [Referensi](#-referensi)

---

## 📌 Ringkasan

| Item | Nilai |
|------|-------|
| Nama proyek | `proyek-saya` |
| Package manager | `uv` v0.12.23 |
| Versi Python | CPython 3.12.15 (di-*pin* ke `3.12`) |
| Virtual environment | `.venv` |
| Library terpasang | `pandas`, `numpy`, `python-dateutil`, `six` |
| OS | macOS (Intel, `x86_64`) |

---

## ✅ Prasyarat

- macOS dengan terminal (zsh/bash)
- Koneksi internet (untuk mengunduh `uv`, Python, dan paket)
- `curl` (sudah tersedia bawaan macOS)

---

## 📖 Penjelasan Setiap Perintah

### 1. Instalasi `uv`

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Mengunduh skrip instalasi resmi `uv` lalu langsung menjalankannya.

| Bagian | Fungsi |
|--------|--------|
| `curl` | Alat untuk mengunduh konten dari URL |
| `-L` | Mengikuti *redirect* jika URL dialihkan |
| `-s` | *Silent*, menyembunyikan progress bar |
| `-S` | Tetap menampilkan pesan error walaupun mode `-s` aktif |
| `-f` | *Fail*, gagal dengan tenang jika server mengembalikan error HTTP |
| `\| sh` | Menyalurkan (*pipe*) hasil unduhan ke shell untuk dieksekusi |

**Hasil:** `uv` dan `uvx` terpasang di `/Users/danel/.local/bin`.

> ⚠️ Pesan `skipping sha256 checksum verification` muncul karena perintah `sha256sum` tidak tersedia di macOS (macOS memakai `shasum`). Ini hanya peringatan, instalasi tetap berhasil.

---

### 2. Instalasi `uv` versi Windows (❌ tidak berlaku di macOS)

```bash
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Perintah ini adalah cara instalasi **khusus Windows** (via PowerShell). Karena dijalankan di macOS:

```
zsh: command not found: powershell
```

**Kesimpulan:** Error ini wajar dan **bisa diabaikan**, karena instalasi dari langkah 1 sudah berhasil.

---

### 3. Memperbarui `uv`

```bash
uv self update
```

Memeriksa dan memperbarui `uv` ke versi terbaru.

**Hasil:** `You're already on version v0.12.23 of uv (the latest version).` Artinya `uv` sudah versi terbaru.

---

### 4. Membuat folder proyek

```bash
mkdir proyek-saya
cd proyek-saya
```

| Perintah | Fungsi |
|----------|--------|
| `mkdir proyek-saya` | *Make directory*, membuat folder baru bernama `proyek-saya` |
| `cd proyek-saya` | *Change directory*, berpindah masuk ke folder tersebut |

---

### 5. Melihat daftar versi Python

```bash
uv python list
```

Menampilkan semua versi Python yang **sudah terpasang** maupun yang **bisa diunduh** oleh `uv`.

Cara membaca outputnya:

| Keterangan | Arti |
|------------|------|
| `<download available>` | Versi tersedia, tapi belum terpasang |
| Path (mis. `/usr/local/bin/python3.13`) | Versi sudah terpasang di sistem |
| `cpython` | Implementasi Python standar |
| `+freethreaded` | Varian tanpa GIL (eksperimental) |
| `pypy`, `graalpy` | Implementasi Python alternatif |

Versi yang sudah terdeteksi di komputer ini:

- `3.14.4` (terkelola `uv`)
- `3.13.9` (instalasi python.org)
- `3.9.6` (bawaan macOS, `/usr/bin/python3`)

---

### 6. Mengunci versi Python proyek

```bash
uv python pin 3.12
```

Membuat file **`.python-version`** berisi `3.12`. Setiap kali `uv` dijalankan di folder ini, versi Python 3.12 akan dipakai secara konsisten.

**Hasil:** `Pinned .python-version to 3.12`

---

### 7. Membuat virtual environment

```bash
uv venv
```

Membuat *virtual environment* di folder `.venv`. Karena Python 3.12 belum terpasang, `uv` **mengunduhnya otomatis** (CPython 3.12.15).

**Hasil:**

```
Using CPython 3.12.15
Creating virtual environment at: .venv
```

> 💡 Virtual environment memisahkan library tiap proyek agar tidak saling bentrok.

---

### 8. Mengaktifkan virtual environment

```bash
source .venv/bin/activate
```

Mengaktifkan environment. Tanda berhasil: prompt berubah menjadi `(proyek-saya)`.

---

### 9. Perintah aktivasi Windows (❌ tidak berlaku di macOS)

```bash
.venv\Scripts\activate.bat
venv\Scripts\Activate.ps1
```

Ini adalah cara aktivasi **khusus Windows** (CMD dan PowerShell). Di macOS menghasilkan error:

```
zsh: command not found: .venvScriptsactivate.bat
zsh: command not found: venvScriptsActivate.ps1
```

Perhatikan bahwa tanda `\` hilang pada pesan error. Di zsh, backslash dianggap karakter *escape*, sehingga path menjadi menyatu. Selain itu, pada perintah kedua nama foldernya `venv` (bukan `.venv`).

**Kesimpulan:** Di macOS/Linux cukup gunakan `source .venv/bin/activate`.

| Sistem Operasi | Perintah Aktivasi |
|----------------|-------------------|
| macOS / Linux | `source .venv/bin/activate` |
| Windows (CMD) | `.venv\Scripts\activate.bat` |
| Windows (PowerShell) | `.venv\Scripts\Activate.ps1` |

---

### 10. Memasang library `pandas`

```bash
uv pip install pandas
```

Memasang `pandas` beserta dependensinya ke dalam `.venv`.

**Hasil:**

```
Resolved 4 packages in 2.93s
Prepared 4 packages in 3.29s
Installed 4 packages in 76ms
 + numpy==2.5.3
 + pandas==3.0.6
 + python-dateutil==2.9.0.post0
 + six==1.17.0
```

| Paket | Peran |
|-------|-------|
| `pandas` | Library utama untuk analisis data |
| `numpy` | Dependensi: komputasi numerik/array |
| `python-dateutil` | Dependensi: pengolahan tanggal dan waktu |
| `six` | Dependensi: kompatibilitas Python 2/3 |

---

### 11. Melihat daftar paket terpasang

```bash
uv pip list
```

Menampilkan tabel paket beserta versinya di environment aktif.

---

### 12. Menyimpan daftar dependensi

```bash
uv pip freeze > requirements.txt
```

| Bagian | Fungsi |
|--------|--------|
| `uv pip freeze` | Mencetak semua paket terpasang dengan versi persis (`paket==versi`) |
| `>` | Mengalihkan output ke dalam file, bukan ke layar |
| `requirements.txt` | File tujuan penyimpanan |

---

### 13. Memasang dependensi dari file

```bash
uv pip install -r requirements.txt
```

Memasang semua paket yang tercantum di `requirements.txt` (flag `-r` = *requirement file*).

**Hasil:** `Checked 4 packages in 12ms`. Tidak ada yang dipasang ulang karena semuanya sudah ada. Perintah ini berguna saat memindahkan proyek ke komputer lain atau saat *clone* dari GitHub.

---

### 14. Melihat isi file

```bash
cat requirements.txt
```

Menampilkan isi file di terminal:

```
numpy==2.5.3
pandas==3.0.6
python-dateutil==2.9.0.post0
six==1.17.0
```

---

## 🧠 Pembahasan

### 1. Mengapa memakai `uv`?

| Aspek | `pip` + `venv` klasik | `uv` |
|-------|----------------------|------|
| Kecepatan | Lambat | **10-100x lebih cepat** |
| Kelola versi Python | Tidak bisa | **Bisa** (unduh otomatis) |
| Buat virtual env | `python -m venv` | `uv venv` |
| Instalasi paket | `pip install` | `uv pip install` |
| Satu alat untuk semua | Tidak | **Ya** |

Terlihat dari output: memasang 4 paket hanya butuh sekitar **76 ms** untuk tahap instalasi, dan pengecekan ulang hanya **12 ms**.

### 2. Alur kerja yang terbentuk

```
Install uv → Buat folder → Pin Python → Buat venv → Aktifkan venv
          → Install paket → Simpan requirements.txt → Verifikasi
```

### 3. Pelajaran dari error yang muncul

Dua error yang terjadi (`powershell` dan `activate.bat`) disebabkan **mengikuti panduan untuk Windows di macOS**. Tidak ada yang rusak. Tips:

- Perhatikan tab/label OS pada dokumentasi (macOS/Linux vs Windows).
- `command not found` berarti perintah tersebut memang tidak ada di sistem Anda.

### 4. Catatan penting tentang `uv pip` vs alur proyek `uv`

Sesi ini memakai **antarmuka kompatibel pip** (`uv pip ...`). Cara ini bagus dan familiar, tetapi `uv` juga punya **alur kerja proyek modern** yang lebih ringkas:

| Alur yang dipakai (gaya pip) | Alternatif modern (gaya proyek `uv`) |
|------------------------------|--------------------------------------|
| `uv venv` | `uv init` (membuat `pyproject.toml`) |
| `uv pip install pandas` | `uv add pandas` |
| `uv pip freeze > requirements.txt` | `uv lock` (membuat `uv.lock`) |
| `uv pip install -r requirements.txt` | `uv sync` |
| `source .venv/bin/activate` + `python` | `uv run python main.py` (tanpa aktivasi manual) |

Keunggulan alur modern: dependensi tercatat di `pyproject.toml`, ada *lock file* yang menjamin hasil instalasi identik, dan tidak perlu mengaktifkan environment secara manual.

### 5. Catatan tentang `requirements.txt`

`uv pip freeze` mencatat **semua** paket, termasuk dependensi turunan (`numpy`, `six`, dll.), bukan hanya yang dipasang langsung (`pandas`). Kelebihannya hasil bisa direproduksi persis. Kekurangannya, sulit membedakan mana paket utama dan mana dependensi turunan.

### 6. Rekomendasi `.gitignore`

Jika proyek diunggah ke GitHub, **jangan** ikut mengunggah `.venv`. Buat file `.gitignore`:

```gitignore
.venv/
__pycache__/
*.pyc
```

File yang **sebaiknya di-commit:** `.python-version`, `requirements.txt` (atau `pyproject.toml` dan `uv.lock`).

---

## ⚡ Cara Cepat (Quick Start)

Bagi yang ingin menjalankan ulang proyek ini dari awal (macOS/Linux):

```bash
# 1. Pasang uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. Clone repositori dan masuk ke folder
git clone <url-repo-anda>
cd proyek-saya

# 3. Buat environment sesuai .python-version
uv venv

# 4. Aktifkan environment
source .venv/bin/activate

# 5. Pasang dependensi
uv pip install -r requirements.txt

# 6. Verifikasi
uv pip list
```

---

## 🗂️ Struktur Proyek Akhir

```
proyek-saya/
├── .venv/               # Virtual environment (jangan di-commit)
├── .python-version      # Versi Python yang dikunci (3.12)
└── requirements.txt     # Daftar dependensi
```

---

## 🧾 Cheat Sheet

| Tujuan | Perintah |
|--------|----------|
| Pasang uv | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Update uv | `uv self update` |
| Lihat versi Python | `uv python list` |
| Pasang versi Python | `uv python install 3.12` |
| Kunci versi Python | `uv python pin 3.12` |
| Buat venv | `uv venv` |
| Aktifkan venv (macOS/Linux) | `source .venv/bin/activate` |
| Nonaktifkan venv | `deactivate` |
| Pasang paket | `uv pip install <paket>` |
| Hapus paket | `uv pip uninstall <paket>` |
| Daftar paket | `uv pip list` |
| Ekspor dependensi | `uv pip freeze > requirements.txt` |
| Pasang dari file | `uv pip install -r requirements.txt` |

---

## 🔗 Referensi

- [Dokumentasi resmi uv](https://docs.astral.sh/uv/)
- [Repositori uv di GitHub](https://github.com/astral-sh/uv)
- [Dokumentasi pandas](https://pandas.pydata.org/docs/)
