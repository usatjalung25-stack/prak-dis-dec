# Menggunakan uv untuk Mengelola Environment dan Paket Python

Panduan praktis untuk membuat *workspace* proyek dengan versi Python tertentu dan paket khusus menggunakan [uv](https://docs.astral.sh/uv/), lengkap dengan cara mengatasi error yang sering muncul.

- **Sistem operasi**: macOS (x86_64), langkah di Linux hampir sama
- **uv**: 0.13.0
- **Python**: 3.12.15 (CPython)
- **Last update**: 10 Oktober 2026

## Daftar Isi

- [Apa itu uv?](#apa-itu-uv)
- [Ringkasan Cepat](#ringkasan-cepat)
- [1. Instalasi](#1-instalasi)
- [2. Update uv](#2-update-uv)
- [3. Membuat Workspace](#3-membuat-workspace)
- [4. Membuat Environment](#4-membuat-environment)
- [5. Mengelola Paket](#5-mengelola-paket)
- [6. Menyimpan dan Memasang Ulang Paket](#6-menyimpan-dan-memasang-ulang-paket)
- [7. Menghapus Environment](#7-menghapus-environment)
- [Alternatif: Workflow Proyek (uv init/add/sync)](#alternatif-workflow-proyek-uv-initaddsync)
- [Troubleshooting](#troubleshooting)
- [Struktur Akhir Workspace](#struktur-akhir-workspace)
- [Referensi](#referensi)

## Apa itu uv?

`uv` adalah peranti untuk mengelola instalasi Python, environment (venv), dan paket dalam satu perintah. Dokumen ini berisi petunjuk praktis, bukan petunjuk lengkap. Hasilnya adalah direktori (*workspace*) yang spesifik untuk satu proyek dengan versi Python dan paket sendiri.

## Ringkasan Cepat

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh   # instal uv
mkdir workspace-01 && cd workspace-01              # buat workspace
uv python pin 3.12                                 # pin versi Python
uv venv                                            # buat environment
source .venv/bin/activate                          # aktifkan
uv pip install pandas                              # pasang paket
uv pip freeze > requirements.txt                   # simpan daftar paket
```

## 1. Instalasi

Petunjuk lengkap: <https://docs.astral.sh/uv/getting-started/installation/>. Contoh di macOS/Linux:

```bash
$ curl -LsSf https://astral.sh/uv/install.sh | sh
downloading uv 0.13.0 x86_64-apple-darwin
skipping sha256 checksum verification (it requires the 'sha256sum' command)
installing to /Users/danel/.local/bin
  uv
  uvx
everything's installed!
```

Alternatif lain:

```bash
brew install uv          # Homebrew (macOS/Linux)
pip install uv           # lewat pip
```

Windows (PowerShell):

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Pastikan `$PATH` berisi lokasi uv (`~/.local/bin`), lalu cek:

```bash
$ uv --version
uv 0.13.0
```

Jika muncul `command not found: uv`, lihat [Troubleshooting](#error-command-not-found-uv).

## 2. Update uv

```bash
$ uv self update
```

Jika sudah versi terbaru, uv akan menampilkan pesan bahwa kamu sudah di versi terakhir. Jika uv dipasang lewat Homebrew, update dengan `brew upgrade uv`.

## 3. Membuat Workspace

Buat direktori yang akan menjadi workspace proyek:

```bash
$ mkdir workspace-01
$ cd workspace-01
```

Lihat daftar versi Python yang tersedia:

```bash
$ uv python list
cpython-3.15.0-macos-x86_64-none                  <download available>
cpython-3.14.8-macos-x86_64-none                  <download available>
cpython-3.14.4-macos-x86_64-none                  /Users/danel/.local/bin/python3.14 -> ...
cpython-3.13.9-macos-x86_64-none                  /usr/local/bin/python3.13 -> ...
cpython-3.12.15-macos-x86_64-none                 /Users/danel/.local/share/uv/python/cpython-3.12-macos-x86_64-none/bin/python3.12
cpython-3.11.17-macos-x86_64-none                 <download available>
...
```

Arti kolom kanan:

- Berisi path: versi **sudah terpasang** di komputer.
- `<download available>`: **belum terpasang**, akan diunduh otomatis jika dipakai.

Pin versi Python untuk workspace ini:

```bash
$ uv python pin 3.12
Updated `.python-version` from `/home/bpdp/.local/bin/python3.14` -> `3.12`
```

> **Catatan**: `uv python pin` bisa menerima nomor versi (`3.12`) atau path executable (`/Users/danel/.local/bin/python3.14`). Nomor versi lebih mudah dan portabel antar komputer. Path absolut hanya berlaku di komputer tersebut.

Jika ingin memasang Python tanpa pin:

```bash
$ uv python install 3.12
```

File `.python-version` akan dibuat/diperbarui di direktori tersebut.

## 4. Membuat Environment

```bash
$ uv venv
Using CPython 3.12.15
Creating virtual environment at: .venv
Activate with: source .venv/bin/activate
```

uv otomatis membaca `.python-version`, jadi Python yang dipakai sesuai hasil `pin`.

Aktifkan environment:

```bash
$ source .venv/bin/activate
(workspace-01) $ which python
/Users/danel/workspace-01/.venv/bin/python
```

Perhatikan prefix `(workspace-01)` di depan prompt. Itu menandakan environment yang sedang aktif, dan `which python` kini menunjuk ke `.venv`. Sebelum aktivasi, `which python` biasanya menunjuk ke Python bawaan sistem.

Untuk keluar dari environment:

```bash
(workspace-01) $ deactivate
```

Aktivasi untuk shell lain:

| Shell | Perintah |
|---|---|
| bash / zsh | `source .venv/bin/activate` |
| fish | `source .venv/bin/activate.fish` |
| Windows CMD | `.venv\Scripts\activate.bat` |
| Windows PowerShell | `.venv\Scripts\Activate.ps1` |

## 5. Mengelola Paket

Gunakan `uv pip`. Perintahnya kompatibel dengan `pip`, tetapi hanya berlaku untuk workspace ini.

```bash
(workspace-01) $ uv pip install pandas
Resolved 4 packages in 627ms
Prepared 4 packages in 2.92s
Installed 4 packages in 192ms
 + numpy==2.5.3
 + pandas==3.0.6
 + python-dateutil==2.9.0.post0
 + six==1.17.0
```

Perintah yang sering dipakai:

```bash
uv pip list                      # daftar paket terpasang
uv pip show pandas               # detail satu paket
uv pip install "pandas==3.0.6"   # versi tertentu
uv pip install -U pandas         # upgrade paket
uv pip uninstall pandas          # hapus paket
```

Contoh hasil `uv pip list`:

```bash
(workspace-01) $ uv pip list
Package         Version
--------------- -----------
numpy           2.5.3
pandas          3.0.6
python-dateutil 2.9.0.post0
six             1.17.0
```

Uji hasilnya:

```bash
(workspace-01) $ python -c "import pandas; print(pandas.__version__)"
3.0.6
```

## 6. Menyimpan dan Memasang Ulang Paket

Simpan daftar paket:

```bash
(workspace-01) $ uv pip freeze > requirements.txt
(workspace-01) $ cat requirements.txt
numpy==2.5.3
pandas==3.0.6
python-dateutil==2.9.0.post0
six==1.17.0
```

Pasang ulang di mesin/folder lain:

```bash
$ uv venv
$ source .venv/bin/activate
(workspace-01) $ uv pip install -r requirements.txt
```

## 7. Menghapus Environment

Environment hanyalah folder `.venv`, jadi aman dihapus lalu dibuat ulang kapan saja:

```bash
$ deactivate        # jika sedang aktif
$ rm -rf .venv
$ uv venv
```

## Alternatif: Workflow Proyek (uv init/add/sync)

Selain `uv pip`, uv punya workflow berbasis proyek yang otomatis mengelola `pyproject.toml` dan `uv.lock`:

```bash
uv init                  # buat pyproject.toml
uv add pandas            # tambah dependency + update lock
uv remove pandas         # hapus dependency
uv sync                  # samakan environment dengan lockfile
uv run python main.py    # jalankan tanpa perlu activate manual
```

Cocok untuk proyek yang akan dibagikan atau di-deploy karena versi paket terkunci di `uv.lock`.

## Troubleshooting

### Error: `command not found: uv`

**Penyebab**: folder instalasi uv belum ada di `$PATH`.

**Solusi**:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc    # zsh (default macOS)
# untuk bash: ganti ~/.zshrc dengan ~/.bashrc
source ~/.zshrc
uv --version
```

Atau tutup lalu buka ulang Terminal.

### Error: `source: no such file or directory: /Users/<nama>/.local/bin/env`

**Penyebab**: installer versi tertentu tidak membuat file `env`. Ini tidak berbahaya.

**Solusi**: abaikan dan gunakan cara PATH manual di atas. Selama `uv --version` berjalan, uv sudah siap dipakai.

### Pesan: `mkdir: workspace-01: File exists`

**Penyebab**: direktori sudah ada.

**Solusi**: lanjutkan dengan `cd workspace-01`, atau pakai `mkdir -p workspace-01` agar tidak muncul pesan error.

### Error: `No virtual environment found` saat `uv pip install`

**Penyebab**: `.venv` belum dibuat di folder ini.

**Solusi**:

```bash
uv venv
source .venv/bin/activate
uv pip install pandas
```

### Paket terpasang di tempat yang salah / `which python` bukan `.venv`

**Penyebab**: environment belum diaktifkan, atau terminal baru dibuka.

**Solusi**: jalankan `source .venv/bin/activate` dari dalam folder workspace, lalu cek ulang `which python`. Setiap membuka terminal baru, aktivasi harus diulang.

### Error: `A virtual environment already exists at .venv`

**Penyebab**: `.venv` sudah ada.

**Solusi**:

```bash
uv venv --clear     # buat ulang dari nol
```

### Error: `No interpreter found for Python 3.x`

**Penyebab**: versi Python tidak ditemukan atau unduhan otomatis dinonaktifkan.

**Solusi**:

```bash
uv python list              # cek versi yang tersedia
uv python install 3.12      # pasang manual
```

Pastikan juga variabel `UV_PYTHON_DOWNLOADS=never` tidak aktif dan opsi `--no-python-downloads` tidak dipakai.

### Versi Python tidak sesuai `.python-version`

**Penyebab**: `.venv` dibuat sebelum `pin` diubah, atau file `.python-version` berisi path dari komputer lain (misalnya `/home/bpdp/...`).

**Solusi**:

```bash
uv python pin 3.12
rm -rf .venv
uv venv
```

### Gagal mengunduh (network, timeout, proxy, atau SSL error)

**Penyebab**: koneksi bermasalah, atau jaringan kantor/kampus memakai proxy atau sertifikat sendiri.

**Solusi**:

```bash
uv --system-certs pip install pandas        # pakai sertifikat bawaan sistem
export HTTPS_PROXY="http://proxy:port"      # jika memakai proxy
export UV_HTTP_TIMEOUT=120                  # perpanjang timeout (detik)
```

Jika paket sudah pernah diunduh, coba mode offline: `uv --offline pip install pandas`.

### Error: `No solution found when resolving dependencies`

**Penyebab**: ada paket yang versinya saling bertentangan, atau paket belum mendukung versi Python yang dipakai (misal Python 3.15 yang masih baru).

**Solusi**:

- Baca pesan error, biasanya menyebut paket yang konflik.
- Turunkan versi Python (misal `uv python pin 3.12`) lalu buat ulang `.venv`.
- Longgarkan batasan versi paket di `requirements.txt`.

### Error saat build paket (`Failed to build ...`)

**Penyebab**: paket perlu dikompilasi dan compiler/library sistem belum ada.

**Solusi di macOS**:

```bash
xcode-select --install
```

Atau pilih versi Python yang lebih umum didukung (3.12 atau 3.13) agar tersedia wheel siap pakai.

### Error: `Permission denied`

**Penyebab**: mencoba menulis ke lokasi yang dilindungi sistem.

**Solusi**: jangan pakai `sudo`. Pakai `uv venv` dan pasang paket di dalam `.venv`, bukan ke Python sistem.

### Cache bermasalah / paket aneh setelah gagal instal

**Solusi**:

```bash
uv cache clean
rm -rf .venv && uv venv
```

### Masih bermasalah?

Jalankan perintah dengan mode verbose untuk melihat detailnya:

```bash
uv -v pip install pandas
```

## Struktur Akhir Workspace

```
workspace-01/
├── .python-version
├── .venv/
└── requirements.txt
```

> Tambahkan `.venv/` ke `.gitignore` agar tidak ikut ter-commit:
>
> ```bash
> echo ".venv/" >> .gitignore
> ```

## Referensi

- Dokumentasi uv: <https://docs.astral.sh/uv/>
- Panduan instalasi: <https://docs.astral.sh/uv/getting-started/installation/>
- Panduan asli oleh Dr. Bambang Purnomosidi D. P. ([PT Neo Akselerasi Indonesia](https://neo-x.id))
