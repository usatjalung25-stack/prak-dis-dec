# Panduan uv: Environment dan Paket Python (Step by Step)

Panduan ini disusun dari praktik langsung di terminal macOS. Setiap langkah berisi **perintah**, **output asli**, **penjelasan**, dan **cara mengatasi jika error**.

| Info | Nilai |
|---|---|
| Sistem operasi | macOS (x86_64) |
| uv | 0.13.0 |
| Python | CPython 3.12.15 |
| Paket contoh | pandas 3.0.6 |
| Last update | 10 Oktober 2026 |

## Daftar Langkah

1. [Instal uv](#langkah-1-instal-uv)
2. [Buat folder workspace](#langkah-2-buat-folder-workspace)
3. [Lihat daftar versi Python](#langkah-3-lihat-daftar-versi-python)
4. [Pin versi Python](#langkah-4-pin-versi-python)
5. [Buat environment (.venv)](#langkah-5-buat-environment-venv)
6. [Aktifkan environment](#langkah-6-aktifkan-environment)
7. [Instal paket](#langkah-7-instal-paket)
8. [Muat file env (opsional, bisa error)](#langkah-8-muat-file-env-opsional-bisa-error)
9. [Cek paket terpasang](#langkah-9-cek-paket-terpasang)
10. [Simpan daftar paket (opsional)](#langkah-10-simpan-daftar-paket-opsional)

Setelah itu: [Ringkasan Perintah](#ringkasan-perintah) | [Daftar Error dan Solusi](#daftar-error-dan-solusi) | [Struktur Akhir](#struktur-akhir-workspace)

---

## Langkah 1: Instal uv

**Perintah**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Output**

```
downloading uv 0.13.0 x86_64-apple-darwin
skipping sha256 checksum verification (it requires the 'sha256sum' command)
installing to /Users/danel/.local/bin
  uv
  uvx
everything's installed!
```

**Penjelasan**

- `uv` dan `uvx` dipasang ke `/Users/danel/.local/bin`.
- Baris `skipping sha256 checksum verification` hanya peringatan, bukan error. Instalasi tetap berhasil.
- Petunjuk resmi untuk sistem operasi lain: <https://docs.astral.sh/uv/getting-started/installation/>

**Cek berhasil atau tidak**

```bash
uv --version
```

**Jika error: `command not found: uv`**

Folder `~/.local/bin` belum ada di PATH. Tambahkan:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
uv --version
```

Atau tutup Terminal lalu buka lagi.

---

## Langkah 2: Buat folder workspace

**Perintah**

```bash
mkdir workspace-01
cd workspace-01
```

**Output**

```
mkdir: workspace-01: File exists
```

**Penjelasan**

- Pesan ini artinya folder `workspace-01` **sudah ada**. Ini bukan masalah serius.
- Perintah `cd workspace-01` tetap berhasil, jadi lanjut saja.

**Cara menghindari pesan ini**

```bash
mkdir -p workspace-01
cd workspace-01
```

Opsi `-p` membuat folder hanya jika belum ada, tanpa menampilkan error.

---

## Langkah 3: Lihat daftar versi Python

**Perintah**

```bash
uv python list
```

**Output**

```
cpython-3.15.0-macos-x86_64-none                  <download available>
cpython-3.15.0+freethreaded-macos-x86_64-none     <download available>
cpython-3.14.8-macos-x86_64-none                  <download available>
cpython-3.14.8+freethreaded-macos-x86_64-none     <download available>
cpython-3.14.4-macos-x86_64-none                  /Users/danel/.local/bin/python3.14 -> /Users/danel/.local/share/uv/python/cpython-3.14-macos-x86_64-none/bin/python3.14
cpython-3.14.4-macos-x86_64-none                  /Users/danel/.local/share/uv/python/cpython-3.14-macos-x86_64-none/bin/python3.14
cpython-3.13.16-macos-x86_64-none                 <download available>
cpython-3.13.16+freethreaded-macos-x86_64-none    <download available>
cpython-3.13.9-macos-x86_64-none                  /usr/local/bin/python3.13 -> ../../../Library/Frameworks/Python.framework/Versions/3.13/bin/python3.13
cpython-3.13.9-macos-x86_64-none                  /usr/local/bin/python3 -> ../../../Library/Frameworks/Python.framework/Versions/3.13/bin/python3
cpython-3.12.15-macos-x86_64-none                 /Users/danel/.local/share/uv/python/cpython-3.12-macos-x86_64-none/bin/python3.12
cpython-3.11.17-macos-x86_64-none                 <download available>
cpython-3.10.22-macos-x86_64-none                 <download available>
cpython-3.9.25-macos-x86_64-none                  <download available>
cpython-3.9.6-macos-x86_64-none                   /usr/bin/python3
cpython-3.8.20-macos-x86_64-none                  <download available>
pypy-3.12.14-macos-x86_64-none                    <download available>
pypy-3.11.16-macos-x86_64-none                    <download available>
pypy-3.10.16-macos-x86_64-none                    <download available>
pypy-3.9.19-macos-x86_64-none                     <download available>
pypy-3.8.16-macos-x86_64-none                     <download available>
graalpy-3.12.0-macos-x86_64-none                  <download available>
graalpy-3.11.0-macos-x86_64-none                  <download available>
graalpy-3.10.0-macos-x86_64-none                  <download available>
graalpy-3.8.5-macos-x86_64-none                   <download available>
```

**Cara membaca output**

| Kolom kanan | Artinya |
|---|---|
| `<download available>` | Belum terpasang. Akan diunduh otomatis jika dipilih. |
| Berisi path (misal `/Users/danel/.local/share/uv/...`) | Sudah terpasang dan siap dipakai. |

Dari output di atas, Python yang **sudah terpasang** antara lain:

- 3.14.4 (dikelola uv)
- 3.13.9 (dari python.org, di `/usr/local/bin`)
- **3.12.15 (dikelola uv)**: versi yang dipilih pada langkah berikutnya
- 3.9.6 (bawaan macOS, `/usr/bin/python3`)

Tanda `+freethreaded` adalah varian eksperimental tanpa GIL. Untuk penggunaan umum, pilih versi tanpa tanda itu.

---

## Langkah 4: Pin versi Python

**Perintah**

```bash
uv python pin 3.12
```

**Output**

```
Updated `.python-version` from `/home/bpdp/.local/bin/python3.14` -> `3.12`
```

**Penjelasan**

- Perintah ini membuat atau memperbarui file `.python-version` di folder workspace.
- Kata **Updated** (bukan *Pinned*) berarti file `.python-version` **sudah ada sebelumnya**. Isi lamanya adalah path `/home/bpdp/.local/bin/python3.14`, yaitu path dari komputer lain (kemungkinan terbawa dari contoh/dokumen sumber). Path itu tidak ada di komputermu, jadi harus diganti. Perintah ini sudah menggantinya menjadi `3.12`.
- Memakai **nomor versi** (`3.12`) lebih aman daripada path absolut karena bisa dipakai di komputer mana pun.

**Cek isinya**

```bash
cat .python-version
```

Hasil yang diharapkan: `3.12`

**Jika error: `No interpreter found`**

Pasang dulu versinya, lalu pin ulang:

```bash
uv python install 3.12
uv python pin 3.12
```

---

## Langkah 5: Buat environment (.venv)

**Perintah**

```bash
uv venv
```

**Output**

```
Using CPython 3.12.15
Creating virtual environment at: .venv
Activate with: source .venv/bin/activate
```

**Penjelasan**

- uv membaca `.python-version` sehingga memakai CPython **3.12.15**.
- Folder `.venv` dibuat di dalam workspace. Isinya adalah Python dan paket khusus untuk proyek ini.

**Jika error: `A virtual environment already exists at .venv`**

```bash
uv venv --clear
```

Opsi `--clear` membuat ulang environment dari nol.

---

## Langkah 6: Aktifkan environment

**Perintah**

```bash
source .venv/bin/activate
which python
```

**Output**

```
(workspace-01) danel@1111QD-rs workspace-01 % which python
/Users/danel/workspace-01/.venv/bin/python
```

**Penjelasan**

- Prefix **`(workspace-01)`** di depan prompt menandakan environment sedang aktif.
- `which python` kini menunjuk ke `.venv/bin/python`, artinya semua perintah `python` dan paket yang dipasang akan masuk ke environment ini, bukan ke Python sistem.
- Untuk keluar dari environment: `deactivate`

**Aktivasi di shell lain**

| Shell | Perintah |
|---|---|
| bash / zsh | `source .venv/bin/activate` |
| fish | `source .venv/bin/activate.fish` |
| Windows CMD | `.venv\Scripts\activate.bat` |
| Windows PowerShell | `.venv\Scripts\Activate.ps1` |

**Jika `which python` bukan menunjuk ke `.venv`**

- Pastikan kamu menjalankan `source .venv/bin/activate` dari **dalam folder workspace**.
- Setiap membuka tab/terminal baru, aktivasi harus diulang.

---

## Langkah 7: Instal paket

**Perintah**

```bash
uv pip install pandas
```

**Output**

```
Resolved 4 packages in 627ms
Prepared 4 packages in 2.92s
Installed 4 packages in 192ms
 + numpy==2.5.3
 + pandas==3.0.6
 + python-dateutil==2.9.0.post0
 + six==1.17.0
```

**Penjelasan**

- Kamu hanya meminta `pandas`, tetapi uv memasang **4 paket** karena pandas membutuhkan 3 paket lain (dependency): `numpy`, `python-dateutil`, dan `six`.
- Tanda `+` berarti paket baru ditambahkan.
- `uv pip` sama seperti `pip` biasa, tetapi jauh lebih cepat dan hanya berlaku untuk environment yang aktif.

**Perintah paket lain yang sering dipakai**

```bash
uv pip install "pandas==3.0.6"   # versi tertentu
uv pip install -U pandas         # upgrade
uv pip show pandas               # detail paket
uv pip uninstall pandas          # hapus paket
```

**Jika error: `No virtual environment found`**

Environment belum dibuat/diaktifkan:

```bash
uv venv
source .venv/bin/activate
uv pip install pandas
```

**Jika error jaringan, timeout, atau SSL**

```bash
uv --system-certs pip install pandas
export UV_HTTP_TIMEOUT=120
```

Jika memakai proxy: `export HTTPS_PROXY="http://proxy:port"`

**Jika error `No solution found when resolving dependencies`**

Ada konflik versi paket, atau paket belum mendukung versi Python yang dipakai. Gunakan Python yang lebih umum (3.12 atau 3.13) lalu buat ulang `.venv`.

**Jika error `Failed to build ...`**

Pasang alat compiler macOS, lalu coba lagi:

```bash
xcode-select --install
```

---

## Langkah 8: Muat file env (opsional, bisa error)

**Perintah**

```bash
source $HOME/.local/bin/env
```

**Output (error)**

```
source: no such file or directory: /Users/danel/.local/bin/env
```

**Penjelasan**

- File `env` **tidak ada** di instalasi ini. Installer versi tertentu tidak membuatnya.
- Ini **tidak mempengaruhi** uv. Buktinya, `uv pip install` dan `uv venv` tetap berjalan normal.
- Langkah ini hanya dibutuhkan jika uv tidak dikenali di terminal (`command not found: uv`).

**Solusi yang benar jika uv tidak dikenali**

Tambahkan PATH secara manual (bukan lewat file `env`):

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Jika uv sudah berjalan normal, **langkah ini boleh dilewati**.

---

## Langkah 9: Cek paket terpasang

**Perintah**

```bash
uv pip list
```

**Output**

```
Package         Version
--------------- -----------
numpy           2.5.3
pandas          3.0.6
python-dateutil 2.9.0.post0
six             1.17.0
```

**Penjelasan**

Daftar ini sama persis dengan hasil instalasi di Langkah 7, jadi instalasi **berhasil**. Hanya paket di dalam `.venv` ini yang ditampilkan, bukan paket Python sistem.

**Uji pandas bisa dipakai**

```bash
python -c "import pandas; print(pandas.__version__)"
```

Hasil yang diharapkan: `3.0.6`

---

## Langkah 10: Simpan daftar paket (opsional)

Langkah ini belum dijalankan di sesi di atas, tetapi berguna agar environment bisa dibuat ulang di komputer lain.

**Perintah**

```bash
uv pip freeze > requirements.txt
cat requirements.txt
```

**Hasil yang diharapkan**

```
numpy==2.5.3
pandas==3.0.6
python-dateutil==2.9.0.post0
six==1.17.0
```

**Memasang ulang dari file tersebut**

```bash
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

---

## Ringkasan Perintah

Semua perintah yang dipakai, berurutan:

```bash
# 1. Instal uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. Buat dan masuk ke workspace
mkdir -p workspace-01
cd workspace-01

# 3. Lihat versi Python
uv python list

# 4. Pin versi Python
uv python pin 3.12

# 5. Buat environment
uv venv

# 6. Aktifkan environment
source .venv/bin/activate
which python

# 7. Instal paket
uv pip install pandas

# 9. Cek paket
uv pip list

# 10. Simpan daftar paket (opsional)
uv pip freeze > requirements.txt

# Keluar dari environment
deactivate
```

---

## Daftar Error dan Solusi

| Error / Pesan | Penyebab | Solusi |
|---|---|---|
| `command not found: uv` | PATH belum berisi `~/.local/bin` | `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc` |
| `source: no such file or directory: .../.local/bin/env` | File `env` tidak dibuat installer | Abaikan. Pakai solusi PATH di atas jika uv tidak dikenali. |
| `mkdir: workspace-01: File exists` | Folder sudah ada | Lanjut `cd workspace-01`, atau pakai `mkdir -p` |
| `.python-version` berisi path `/home/bpdp/...` | File terbawa dari komputer lain | `uv python pin 3.12` |
| `No interpreter found for Python 3.x` | Versi belum terpasang atau unduhan dimatikan | `uv python install 3.12` |
| `A virtual environment already exists at .venv` | `.venv` sudah ada | `uv venv --clear` |
| `No virtual environment found` | `.venv` belum dibuat/aktif | `uv venv` lalu `source .venv/bin/activate` |
| `which python` bukan di `.venv` | Environment belum aktif | `source .venv/bin/activate` dari dalam folder workspace |
| Error jaringan / timeout / SSL | Koneksi, proxy, atau sertifikat | `uv --system-certs pip install ...`, atur `UV_HTTP_TIMEOUT`, atau `HTTPS_PROXY` |
| `No solution found when resolving dependencies` | Konflik versi atau Python terlalu baru | Pakai Python 3.12/3.13, longgarkan versi paket |
| `Failed to build ...` | Compiler belum ada | `xcode-select --install` |
| `Permission denied` | Menulis ke lokasi sistem | Jangan pakai `sudo`. Pasang paket di dalam `.venv`. |
| Paket aneh setelah instal gagal | Cache rusak | `uv cache clean`, lalu `rm -rf .venv && uv venv` |

**Butuh detail lebih lanjut?** Jalankan dengan mode verbose:

```bash
uv -v pip install pandas
```

---

## Struktur Akhir Workspace

```
workspace-01/
├── .python-version     # berisi: 3.12
├── .venv/              # environment (jangan di-commit)
└── requirements.txt    # opsional
```

Agar `.venv` tidak ikut ter-commit ke Git:

```bash
echo ".venv/" >> .gitignore
```

## Referensi

- Dokumentasi uv: <https://docs.astral.sh/uv/>
- Panduan instalasi: <https://docs.astral.sh/uv/getting-started/installation/>
- Panduan asli oleh Dr. Bambang Purnomosidi D. P. ([PT Neo Akselerasi Indonesia](https://neo-x.id))
