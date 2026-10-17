# Modul 3 — Sinkronisasi pada Sistem Terdistribusi

**Mata Kuliah:** Praktikum Sistem Terdistribusi dan Terdesentralisasi
**Prodi:** Informatika — Universitas Teknologi Digital Indonesia
**Penulis modul:** Dr. Bambang Purnomosidi D. P.

| | |
|---|---|
| **Nama** | USAT JALUNG |
| **NIM** | 255410017 |
| **Kelas** | INFORMATIKA - 1 |

---

## Daftar Isi

1. [Struktur Repositori](#1-struktur-repositori)
2. [3.1 Sinkronisasi Waktu (NTP / Chrony)](#2-31-sinkronisasi-waktu-ntp--chrony)
3. [3.2 Vector Clock](#3-32-vector-clock)
4. [3.3 Problem Tanpa Sinkronisasi](#4-33-problem-tanpa-sinkronisasi)
   - [Contoh Multithread](#contoh-program-multithreaded)
   - [3.3.1 Data Race / Race Conditions](#331-data-race--race-conditions)
   - [3.3.2 Deadlock](#332-deadlock)
5. [3.4 Algoritma Raft](#5-34-algoritma-raft)
6. [Kesimpulan](#6-kesimpulan)

---

## 1. Struktur Repositori

```text
03/
├── Sinkronisasi Waktu/
│   ├── Linux-*BSD-Mac.md          # dokumentasi chrony (macOS)
│   └── kode instalasi             # log terminal lengkap
└── modul3_stt.py/
    ├── 01-vclocks.py
    ├── 02-multithreads-example.py
    ├── 03-race-conditions-01.py
    ├── 04-race-conditions-02.py
    ├── 05-deadlock-01.py
    ├── 06-deadlock-02.py
    ├── 07-raft.py
    ├── modul/                     # tugas membuat modul Python
    │   ├── vclock.py
    │   ├── contoh_vclock.py
    │   ├── raft_module.py
    │   └── simulasi_raft.py
    ├── image/                     # screenshot keluaran + gambar tangan
    └── README.md
```

| No | Program | Bukti keluaran | Topik |
|:-:|---|---|---|
| 01 | [`01-vclocks.py`](01-vclocks.py) | `image/01-vclocks.py.png` | Vector clock |
| 02 | [`02-multithreads-example.py`](02-multithreads-example.py) | `image/02-multithreads-example.py.png` | Multithread tanpa sinkronisasi |
| 03 | [`03-race-conditions-01.py`](03-race-conditions-01.py) | `image/03-race-conditions-01.py.png`, `image/03-race-conditions-1.py.png` | Race condition terjadi |
| 04 | [`04-race-conditions-02.py`](04-race-conditions-02.py) | `image/04-race-conditions-02.py.png` | Race condition dicegah (Lock) |
| 05 | [`05-deadlock-01.py`](05-deadlock-01.py) | `image/05-deadlock-01.py.png`, `image/05-deadlock-1.py.png` | Deadlock terjadi |
| 06 | [`06-deadlock-02.py`](06-deadlock-02.py) | `image/06-deadlock-02.py.png` | Deadlock dicegah |
| 07 | [`07-raft.py`](07-raft.py) | `image/07-raft.py-01.png`, `image/07-raft.py-02.png`, `image/07-raft.py-03.png` | Simulasi Raft |

---

## 2. 3.1 Sinkronisasi Waktu (NTP / Chrony)

Dokumentasi lengkap (instalasi, masalah yang muncul, dan pembahasan) ada di
[`../Sinkronisasi Waktu/Linux-*BSD-Mac.md`](<../Sinkronisasi Waktu/Linux-*BSD-Mac.md>) dan log terminal lengkap di
[`../Sinkronisasi Waktu/kode instalasi`](<../Sinkronisasi Waktu/kode instalasi>).

**Lingkungan:** macOS 13 (Ventura) Intel, Homebrew, chrony 4.9.

**Perintah utama**

```bash
sudo mkdir -p /var/run/chrony /usr/local/var/run /usr/local/var/lib/chrony
sudo chmod 755 /var/run/chrony
sudo /usr/local/sbin/chronyd -f /usr/local/etc/chrony.conf
chronyc sources -v
chronyc tracking
sudo chronyc makestep
chronyc tracking
```

**Keluaran `chronyc sources -v`**

```text
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^- waktos2.unpak.ac.id           2   6    37    35    +27ms[  +27ms] +/-  565ms
^- time.citra.net.id             2   6    37    35    -12ms[  -12ms] +/-   41ms
^* 172-235-254-88.ip.linode>     2   6    37    36   -436us[  +20ms] +/-   42ms
^- jkt-tmd.caliph.dev            2   6    37    35   -779ms[ -779ms] +/-  859ms
```

**Hasil koreksi `makestep`**

| Kondisi | `System time` |
|---|---|
| Sebelum `makestep` | 0.013657703 detik **lebih cepat** dari waktu NTP |
| Sesudah `makestep` | 0.000000000 detik |

Chrony memilih server bertanda `*` (Linode, galat ±42 ms) sebagai sumber terbaik. Selisih awal 13,7 ms hilang setelah `makestep`.

---

## 3. 3.2 Vector Clock

Vector clock dipakai untuk mengurutkan event pada sistem terdistribusi tanpa jam fisik bersama.

### Program — `01-vclocks.py`

```python
class VectorClock:
    def __init__(self, num_processes, process_id):
        self.clocks = [0] * num_processes  # Initialize all clocks to zero
        self.process_id = process_id      # The ID of the current process

    def increment(self):
        """Increments the local clock for the current process."""
        self.clocks[self.process_id] += 1

    def send_message(self):
        """Prepares the vector clock for sending with a message."""
        self.increment()  # Increment local clock before sending
        return list(self.clocks) # Return a copy of the current vector clock

    def receive_message(self, received_clocks):
        """Updates the vector clock upon receiving a message."""
        for i in range(len(self.clocks)):
            self.clocks[i] = max(self.clocks[i], received_clocks[i])
        self.increment()  # Increment local clock after receiving and merging

    def __str__(self):
        return f"P{self.process_id}: {self.clocks}"

    def happens_before(self, other_vector_clock):
        """
        Determines if this vector clock happens before another.
        A happens before B if all elements in A are less than or equal to
        the corresponding elements in B, and at least one element in A is
        strictly less than the corresponding element in B.
        """
        if self.clocks == other_vector_clock.clocks:
            return False  # Same clocks, not "happens before"

        all_le = True  # All elements are less than or equal
        any_lt = False # At least one element is strictly less than

        for i in range(len(self.clocks)):
            if self.clocks[i] > other_vector_clock.clocks[i]:
                return False # Not "happens before" if any element is greater

            if self.clocks[i] < other_vector_clock.clocks[i]:
                any_lt = True

        return all_le and any_lt

    def is_concurrent(self, other_vector_clock):
        """
        Determines if two vector clocks are concurrent.
        Two events are concurrent if neither happens before the other.
        """
        return not (self.happens_before(other_vector_clock) or
                    other_vector_clock.happens_before(self))

# Simulate a system with 3 processes
vc0 = VectorClock(num_processes=3, process_id=0)
vc1 = VectorClock(num_processes=3, process_id=1)
vc2 = VectorClock(num_processes=3, process_id=2)

print(vc0)
print(vc1)
print(vc2)

# Process 0 performs a local event
vc0.increment()
print(vc0)

# Process 0 sends a message to Process 1
message_from_p0 = vc0.send_message()
vc1.receive_message(message_from_p0)
print(vc0)
print(vc1)

# Process 2 performs a local event
vc2.increment()
print(vc2)

# Process 1 sends a message to Process 2
message_from_p1 = vc1.send_message()
vc2.receive_message(message_from_p1)
print(vc1)
print(vc2)

# Check causality
print(f"VC0 happens before VC1: {vc0.happens_before(vc1)}")
print(f"VC1 happens before VC0: {vc1.happens_before(vc0)}")
print(f"VC0 is concurrent with VC2: {vc0.is_concurrent(vc2)}")
```

### Keluaran

![Keluaran vector clock](image/01-vclocks.py.png)

```text
P0: [0, 0, 0]
P1: [0, 0, 0]
P2: [0, 0, 0]
P0: [1, 0, 0]
P0: [2, 0, 0]
P1: [2, 1, 0]
P2: [0, 0, 1]
P1: [2, 2, 0]
P2: [2, 2, 2]
VC0 happens before VC1: True
VC1 happens before VC0: False
VC0 is concurrent with VC2: False
```

### Tugas 1 — Penjelasan keluaran dan perbandingan dengan cara manual

Aturan vector clock: (1) event lokal → tambah 1 pada slot milik sendiri; (2) kirim pesan → tambah 1 lalu sertakan vektor; (3) terima pesan → ambil nilai **maksimum per elemen**, lalu tambah 1 pada slot sendiri.

| Langkah | Perhitungan manual | Keluaran program |
|---|---|---|
| Awal | Semua proses `[0,0,0]` | `P0`, `P1`, `P2` = `[0,0,0]` |
| P0 event lokal | `[0,0,0]` → `[1,0,0]` | `P0: [1, 0, 0]` |
| P0 kirim ke P1 | P0 +1 → `[2,0,0]`, kirim `[2,0,0]` | `P0: [2, 0, 0]` |
| P1 terima | max(`[0,0,0]`,`[2,0,0]`) = `[2,0,0]`, +1 slot P1 → `[2,1,0]` | `P1: [2, 1, 0]` |
| P2 event lokal | `[0,0,0]` → `[0,0,1]` | `P2: [0, 0, 1]` |
| P1 kirim ke P2 | P1 +1 → `[2,2,0]`, kirim `[2,2,0]` | `P1: [2, 2, 0]` |
| P2 terima | max(`[0,0,1]`,`[2,2,0]`) = `[2,2,1]`, +1 slot P2 → `[2,2,2]` | `P2: [2, 2, 2]` |

Hasil program **sama persis** dengan perhitungan manual.

Pengecekan kausalitas:

| Perbandingan | Hasil | Alasan |
|---|:-:|---|
| VC0 `[2,0,0]` *happens-before* VC1 `[2,2,0]` | **True** | Semua elemen ≤ dan ada yang < |
| VC1 `[2,2,0]` *happens-before* VC0 `[2,0,0]` | **False** | Elemen ke-2 bernilai 2 > 0 |
| VC0 *concurrent* dengan VC2 `[2,2,2]` | **False** | VC0 mendahului VC2 lewat rantai P0 → P1 → P2 |

Dua event dikatakan *concurrent* jika tidak ada yang mendahului yang lain, misalnya `[1,0,0]` dan `[0,0,1]`.

### Tugas 2 — Modul Python `VectorClock`

Class dipisah ke [`modul/vclock.py`](modul/vclock.py) dan contoh penggunaannya ada di [`modul/contoh_vclock.py`](modul/contoh_vclock.py).

<details>
<summary><b>modul/vclock.py</b></summary>

```python
"""Modul VectorClock untuk pengurutan event pada sistem terdistribusi."""


class VectorClock:
    def __init__(self, num_processes, process_id):
        self.clocks = [0] * num_processes
        self.process_id = process_id

    def increment(self):
        """Event lokal: tambah 1 pada slot milik sendiri."""
        self.clocks[self.process_id] += 1

    def send_message(self):
        """Tambah clock lalu kembalikan salinan vektor untuk dikirim."""
        self.increment()
        return list(self.clocks)

    def receive_message(self, received_clocks):
        """Ambil max per elemen, lalu tambah 1 pada slot sendiri."""
        for i in range(len(self.clocks)):
            self.clocks[i] = max(self.clocks[i], received_clocks[i])
        self.increment()

    def happens_before(self, other):
        """True jika semua elemen <= other dan minimal satu elemen < other."""
        if self.clocks == other.clocks:
            return False
        any_lt = False
        for a, b in zip(self.clocks, other.clocks):
            if a > b:
                return False
            if a < b:
                any_lt = True
        return any_lt

    def is_concurrent(self, other):
        return not (self.happens_before(other) or other.happens_before(self))

    def __str__(self):
        return f"P{self.process_id}: {self.clocks}"
```

</details>

<details open>
<summary><b>modul/contoh_vclock.py</b></summary>

```python
"""Contoh penggunaan modul vclock."""
from vclock import VectorClock

vc0, vc1, vc2 = (VectorClock(3, i) for i in range(3))
print(vc0); print(vc1); print(vc2)

vc0.increment(); print(vc0)

m0 = vc0.send_message()
vc1.receive_message(m0)
print(vc0); print(vc1)

vc2.increment(); print(vc2)

m1 = vc1.send_message()
vc2.receive_message(m1)
print(vc1); print(vc2)

print(f"VC0 happens before VC1: {vc0.happens_before(vc1)}")
print(f"VC1 happens before VC0: {vc1.happens_before(vc0)}")
print(f"VC0 is concurrent with VC2: {vc0.is_concurrent(vc2)}")

# Contoh event konkuren: dua event lokal tanpa komunikasi
a, b = VectorClock(3, 0), VectorClock(3, 2)
a.increment(); b.increment()
print(a, b, "-> concurrent:", a.is_concurrent(b))
```

</details>

Keluaran `contoh_vclock.py`:

```text
P0: [0, 0, 0]
P1: [0, 0, 0]
P2: [0, 0, 0]
P0: [1, 0, 0]
P0: [2, 0, 0]
P1: [2, 1, 0]
P2: [0, 0, 1]
P1: [2, 2, 0]
P2: [2, 2, 2]
VC0 happens before VC1: True
VC1 happens before VC0: False
VC0 is concurrent with VC2: False
P0: [1, 0, 0] P2: [0, 0, 1] -> concurrent: True
```

---

## 4. 3.3 Problem Tanpa Sinkronisasi

Pada sistem terdistribusi, ketiadaan sinkronisasi dapat menimbulkan dua masalah besar: **data race / race condition** dan **deadlock**. Pada program asynchronous maupun multithread, pola pikir sekuensial tidak bisa dipakai karena urutan selesainya tiap task tidak dapat diprediksi.

### Contoh Program Multithreaded

**`02-multithreads-example.py`**

```python
import threading
import time

def task(name, delay):
    print(f"Task {name} starting...")
    time.sleep(delay)  # Simulates an I/O-bound operation
    print(f"Task {name} finished after {delay}s.")

# 1. Create thread objects
t1 = threading.Thread(target=task, args=("A", 5))
t2 = threading.Thread(target=task, args=("B", 5))
t3 = threading.Thread(target=task, args=("C", 5))
t4 = threading.Thread(target=task, args=("D", 5))
t5 = threading.Thread(target=task, args=("E", 5))

# 2. Start the threads
t1.start()
t2.start()
t3.start()
t4.start()
t5.start()

# 3. Wait for threads to finish before continuing
t1.join()
t2.join()
t3.join()
t4.join()
t5.join()

print("All tasks completed.")
```

**Keluaran**

![Keluaran multithread](image/02-multithreads-example.py.png)

```text
Task A starting...
Task B starting...
Task C starting...
Task D starting...
Task E starting...
Task A finished after 5s.
Task B finished after 5s.
Task C finished after 5s.
Task E finished after 5s.
Task D finished after 5s.
All tasks completed.
```

**Penjelasan mengapa keluaran bisa berbeda:** pada eksekusi ini `Task E` selesai **sebelum** `Task D`, padahal D dimulai lebih dulu. Kelima thread tidur selama 5 detik dan bangun hampir bersamaan. Urutan bangun dan pencetakan ditentukan oleh *scheduler* sistem operasi dan interpreter Python, sehingga tidak deterministik dan bisa berubah di setiap eksekusi. Hanya baris `All tasks completed.` yang pasti paling akhir karena semua thread di-`join()` terlebih dahulu.

---

### 3.3.1 Data Race / Race Conditions

#### a. Race condition terjadi — `03-race-conditions-01.py`

```python
import time
from threading import Thread

balance = 100

def withdraw(amount):
    global balance
    if balance >= amount:
        time.sleep(0.01)
        balance -= amount
        print(f"Mengambil sejumlah Rp {amount}. Saldo: Rp {balance}")

t1 = Thread(target=withdraw, args=(80,))
t2 = Thread(target=withdraw, args=(80,))

t1.start(); t2.start()
t1.join(); t2.join()
```

**Keluaran**

![Keluaran race condition 01](image/03-race-conditions-01.py.png)

```text
Mengambil sejumlah Rp 80. Saldo: Rp 20
Mengambil sejumlah Rp 80. Saldo: Rp -60
```

**Visualisasi (gambar tangan)**

![Gambar tangan race condition](image/03-race-conditions-1.py.png)

**Penjelasan:**

| Waktu | Thread 1 | Thread 2 | `balance` |
|:-:|---|---|:-:|
| 1 | cek `100 >= 80` → True | | 100 |
| 2 | | cek `100 >= 80` → True | 100 |
| 3 | `sleep(0.01)` | `sleep(0.01)` | 100 |
| 4 | `balance = 100 - 80 = 20` | | 20 |
| 5 | | `balance = 20 - 80 = -60` | **-60** |

Kedua thread mengecek saldo **sebelum** salah satunya sempat mengurangi, sehingga keduanya lolos kondisi `if`. Proses *check-then-act* ini tidak atomik. Variabel global `balance` diubah bersamaan tanpa pengaman sehingga saldo menjadi negatif (-60). Inilah *race condition*.

#### b. Race condition dicegah — `04-race-conditions-02.py`

```python
import time
from threading import Thread
import threading

counter_lock = threading.Lock()
balance = 100

def withdraw(amount):
    global balance
    with counter_lock:
        if balance >= amount:
            time.sleep(0.01)
            balance -= amount
            print(f"Mengambil sejumlah Rp {amount}. Saldo: Rp {balance}")

t1 = Thread(target=withdraw, args=(80,))
t2 = Thread(target=withdraw, args=(80,))

t1.start(); t2.start()
t1.join(); t2.join()
```

**Keluaran**

![Keluaran race condition 02](image/04-race-conditions-02.py.png)

```text
Mengambil sejumlah Rp 80. Saldo: Rp 20
```

**Penjelasan:** `with counter_lock` membuat blok cek → tidur → kurangi menjadi *critical section* yang hanya boleh dimasuki satu thread pada satu waktu. Thread kedua harus menunggu sampai thread pertama selesai. Ketika thread kedua masuk, saldo sudah 20 sehingga kondisi `balance >= amount` bernilai False dan penarikan kedua tidak terjadi. Saldo tidak pernah negatif.

---

### 3.3.2 Deadlock

#### a. Deadlock terjadi — `05-deadlock-01.py`

```python
import threading
import time

# Create two locks
lock_a = threading.Lock()
lock_b = threading.Lock()

def thread_task1():
    with lock_a:
        print("Thread 1: Locked A, waiting for B...")
        time.sleep(1) # Increase chance of deadlock
        with lock_b:
            print("Thread 1: Locked both")

def thread_task2():
    with lock_b:
        print("Thread 2: Locked B, waiting for A...")
        time.sleep(1) # Increase chance of deadlock
        with lock_a:
            print("Thread 2: Locked both")

# Start threads
t1 = threading.Thread(target=thread_task1)
t2 = threading.Thread(target=thread_task2)
t1.start()
t2.start()
t1.join()
t2.join()
```

**Keluaran**

![Keluaran deadlock 01](image/05-deadlock-01.py.png)

```text
Thread 1: Locked A, waiting for B...
Thread 2: Locked B, waiting for A...
```

Program berhenti di titik ini dan tidak pernah selesai (menggantung) sampai dihentikan manual dengan `Ctrl+C`.

**Visualisasi (gambar tangan)**

![Gambar tangan deadlock](image/05-deadlock-1.py.png)

**Penjelasan:**

| Thread | Memegang | Menunggu |
|:-:|:-:|:-:|
| Thread 1 | Lock A | Lock B |
| Thread 2 | Lock B | Lock A |

Thread 1 mengunci A lalu meminta B, sedangkan Thread 2 mengunci B lalu meminta A. Keduanya saling menunggu sehingga terbentuk siklus tunggu dan tidak ada yang bisa maju. `time.sleep(1)` memastikan kedua thread sudah memegang lock pertamanya sebelum meminta lock kedua. Empat syarat deadlock (Coffman) terpenuhi: *mutual exclusion*, *hold and wait*, *no preemption*, dan *circular wait*.

#### b. Deadlock dicegah — `06-deadlock-02.py`

```python
import threading
import time

# Create two shared locks
lock_a = threading.Lock()
lock_b = threading.Lock()

def thread1_task():
    if lock_a.acquire(timeout=5):
        try:
            print("Thread 1: Acquired Lock A")
            time.sleep(1)  # Simulate some work
            print("Thread 1: Waiting for Lock B...")
        finally:
            lock_a.release()
        if lock_b.acquire(timeout=5):
            try:
                print("Thread 1: Acquired Lock B")
            finally:
                lock_b.release()

def thread2_task():
    if lock_b.acquire(timeout=5):
        try:
            print("Thread 2: Acquired Lock B")
            time.sleep(1)  # Simulate some work
            print("Thread 2: Waiting for Lock A...")
        finally:
            lock_b.release()
        if lock_a.acquire(timeout=5):
            try:
                print("Thread 2: Acquired Lock A")
            finally:
                lock_a.release()

t1 = threading.Thread(target=thread1_task)
t2 = threading.Thread(target=thread2_task)

t1.start()
t2.start()
t1.join()
t2.join()
print("Execution Finished")
```

**Keluaran**

![Keluaran deadlock 02](image/06-deadlock-02.py.png)

```text
Thread 1: Acquired Lock A
Thread 2: Acquired Lock B
Thread 2: Waiting for Lock A...
Thread 1: Waiting for Lock B...
Thread 1: Acquired Lock B
Thread 2: Acquired Lock A
Execution Finished
```

**Penjelasan:** deadlock tidak terjadi karena dua hal. Pertama, lock pertama **dilepas** (`finally: release()`) sebelum meminta lock kedua, sehingga kondisi *hold and wait* hilang. Thread tidak lagi memegang satu lock sambil menunggu lock lain. Kedua, setiap `acquire` memakai `timeout=5`, jadi thread tidak menunggu selamanya. Program selesai dan mencetak `Execution Finished`.

---

## 5. 3.4 Algoritma Raft

Raft banyak dipakai pada sistem terdistribusi untuk mencapai **konsensus**, antara lain untuk memilih koordinator (**LEADER**). Simulasi ini diambil dari artikel C# Corner: *Simulate Distributed Consensus with the Raft Protocol (Simplified) using Python*.

### Program — `07-raft.py`

```python
import random
import time
from enum import Enum
from typing import List, Dict, Optional

class State(Enum):
    FOLLOWER = 1
    CANDIDATE = 2
    LEADER = 3

class RaftNode:
    def __init__(self, node_id: int, all_nodes: List[int]):
        self.id = node_id
        self.nodes = all_nodes
        self.state = State.FOLLOWER
        self.current_term = 0
        self.voted_for: Optional[int] = None
        self.log: List[str] = []
        self.commit_index = 0
        self.last_heartbeat = time.time()
        self.election_timeout = self._random_timeout()

    def _random_timeout(self) -> float:
        return time.time() + random.uniform(1.0, 2.0)

    def on_heartbeat(self, term: int):
        if term >= self.current_term:
            self.current_term = term
            self.state = State.FOLLOWER
            self.voted_for = None
            self.last_heartbeat = time.time()
            self.election_timeout = self._random_timeout()

    def start_election(self):
        self.current_term += 1
        self.state = State.CANDIDATE
        self.voted_for = self.id
        votes = 1  # vote for self

        # Simulate requesting votes from others
        for node_id in self.nodes:
            if node_id == self.id:
                continue
            # In real Raft, we'd send RequestVote RPC
            # Here, we simulate: grant vote if term is higher and log is not behind
            votes += 1  # Simplified: assume all grant vote

        if votes > len(self.nodes) // 2:
            self.state = State.LEADER
            print(f"Node {self.id} elected leader in term {self.current_term}")

    def append_entry(self, entry: str):
        if self.state == State.LEADER:
            self.log.append(entry)
            print(f"Leader {self.id} appended: {entry}")
            # In real system, replicate to followers
            self.commit_index = len(self.log) - 1

    def tick(self):
        now = time.time()
        if self.state == State.LEADER:
            # Send heartbeat (simplified)
            pass
        elif now > self.election_timeout:
            self.start_election()
        elif self.state == State.FOLLOWER and now - self.last_heartbeat > 2.0:
            # Missed heartbeats → start election
            self.election_timeout = self._random_timeout()
            self.start_election()


def simulate_raft():
    node_ids = [1, 2, 3]
    nodes = [RaftNode(i, node_ids) for i in node_ids]

    # Simulate time steps
    for step in range(20):
        time.sleep(0.5)
        print(f"\n--- Step {step + 1} ---")

        # Randomly trigger heartbeat from current leader (if any)
        leaders = [n for n in nodes if n.state == State.LEADER]
        if leaders:
            leader = random.choice(leaders)
            for node in nodes:
                if node.id != leader.id:
                    node.on_heartbeat(leader.current_term)
            # Leader appends a command every few steps
            if step % 5 == 0:
                leader.append_entry(f"command-{step}")

        # Each node processes its state
        for node in nodes:
            node.tick()

        # Print status
        for node in nodes:
            print(f"Node {node.id}: {node.state.name} | Term {node.current_term} | Log len {len(node.log)}")


if __name__ == "__main__":
    print(" Simulating Raft Consensus for Drone Swarm Coordination\n")
    simulate_raft()
```

### Keluaran

![Keluaran Raft bagian 1](image/07-raft.py-01.png)

![Keluaran Raft bagian 2](image/07-raft.py-02.png)

<details>
<summary><b>Teks keluaran lengkap (20 step)</b></summary>

```text
Simulating Raft Consensus for Drone Swarm Coordination

--- Step 1 ---
Node 1: FOLLOWER | Term 0 | Log len 0
Node 2: FOLLOWER | Term 0 | Log len 0
Node 3: FOLLOWER | Term 0 | Log len 0

--- Step 2 ---
Node 1: FOLLOWER | Term 0 | Log len 0
Node 2: FOLLOWER | Term 0 | Log len 0
Node 3: FOLLOWER | Term 0 | Log len 0

--- Step 3 ---
Node 1 elected leader in term 1
Node 2 elected leader in term 1
Node 1: LEADER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 0
Node 3: FOLLOWER | Term 0 | Log len 0

--- Step 4 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 0
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 5 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 0
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 6 ---
Leader 2 appended: command-5
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 1
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 7 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 1
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 8 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 1
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 9 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 1
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 10 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 1
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 11 ---
Leader 2 appended: command-10
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 2
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 12 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 2
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 13 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 2
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 14 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 2
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 15 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 2
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 16 ---
Leader 2 appended: command-15
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 3
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 17 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 3
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 18 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 3
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 19 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 3
Node 3: FOLLOWER | Term 1 | Log len 0

--- Step 20 ---
Node 1: FOLLOWER | Term 1 | Log len 0
Node 2: LEADER | Term 1 | Log len 3
Node 3: FOLLOWER | Term 1 | Log len 0
```

</details>

> Keluaran Raft bersifat acak (timeout 1–2 detik), jadi node yang terpilih dan langkah terjadinya pemilihan bisa berbeda di setiap eksekusi.

### Tugas 2 — Penjelasan algoritma Raft memilih LEADER

**Visualisasi (gambar tangan)**

![Gambar tangan alur pemilihan leader Raft](image/07-raft.py-03.png)

**Penjelasan berdasarkan keluaran:**

| Tahap | State | Yang terjadi pada keluaran |
|:-:|:-:|---|
| 1 | FOLLOWER | Step 1–2: semua node `FOLLOWER`, `Term 0`. Tiap node punya *election timeout* acak 1–2 detik |
| 2 | CANDIDATE | Di Step 3, timeout Node 1 dan Node 2 habis lebih dulu. Mereka menaikkan term (0 → 1), memilih diri sendiri, dan meminta suara |
| 3 | LEADER | Suara yang didapat > N/2 (3 node → minimal 2), sehingga `Node 1 elected leader in term 1` dan `Node 2 elected leader in term 1` |
| 4 | FOLLOWER | Step 4: leader mengirim *heartbeat* dengan term 1. Node yang menerima heartbeat (term ≥ term sendiri) kembali menjadi `FOLLOWER` dan reset timeout, sehingga Node 1 turun jadi follower dan Node 3 ikut `Term 1` |
| 5 | LEADER | Node 2 bertahan sebagai satu-satunya leader dan menambah log tiap 5 langkah: `command-5` (Step 6), `command-10` (Step 11), `command-15` (Step 16) → `Log len 3` |

Ringkasnya: **FOLLOWER** yang tidak menerima heartbeat sampai timeout → **CANDIDATE** (term + 1, minta suara) → **LEADER** jika mendapat suara mayoritas. Leader terus mengirim heartbeat agar node lain tetap menjadi follower.

**Catatan tentang simulasi:** pada Step 3 dua node menjadi leader di term yang sama karena kode menganggap semua node selalu memberi suara (`votes += 1`). Pada Raft asli setiap node hanya memberi satu suara per term sehingga hal ini tidak terjadi. Log Node 1 dan Node 3 tetap 0 karena replikasi log ke follower tidak disimulasikan.

### Tugas 3 — Modul Python Raft dan contoh simulasi

Kode dipisah ke [`modul/raft_module.py`](modul/raft_module.py) dan contoh simulasi dengan **5 node** di [`modul/simulasi_raft.py`](modul/simulasi_raft.py).

<details>
<summary><b>modul/raft_module.py</b></summary>

```python
"""Modul simulasi algoritma Raft (disederhanakan)."""
import random
import time
from enum import Enum
from typing import List, Optional


class State(Enum):
    FOLLOWER = 1
    CANDIDATE = 2
    LEADER = 3


class RaftNode:
    def __init__(self, node_id: int, all_nodes: List[int]):
        self.id = node_id
        self.nodes = all_nodes
        self.state = State.FOLLOWER
        self.current_term = 0
        self.voted_for: Optional[int] = None
        self.log: List[str] = []
        self.commit_index = 0
        self.last_heartbeat = time.time()
        self.election_timeout = self._random_timeout()

    def _random_timeout(self) -> float:
        return time.time() + random.uniform(1.0, 2.0)

    def on_heartbeat(self, term: int):
        if term >= self.current_term:
            self.current_term = term
            self.state = State.FOLLOWER
            self.voted_for = None
            self.last_heartbeat = time.time()
            self.election_timeout = self._random_timeout()

    def start_election(self):
        self.current_term += 1
        self.state = State.CANDIDATE
        self.voted_for = self.id
        votes = 1  # suara untuk diri sendiri
        for node_id in self.nodes:
            if node_id == self.id:
                continue
            votes += 1  # disederhanakan: semua node memberi suara
        if votes > len(self.nodes) // 2:
            self.state = State.LEADER
            print(f"Node {self.id} elected leader in term {self.current_term}")

    def append_entry(self, entry: str):
        if self.state == State.LEADER:
            self.log.append(entry)
            print(f"Leader {self.id} appended: {entry}")
            self.commit_index = len(self.log) - 1

    def tick(self):
        now = time.time()
        if self.state == State.LEADER:
            pass  # kirim heartbeat (disederhanakan)
        elif now > self.election_timeout:
            self.start_election()
        elif self.state == State.FOLLOWER and now - self.last_heartbeat > 2.0:
            self.election_timeout = self._random_timeout()
            self.start_election()


def simulate_raft(n_nodes: int = 3, steps: int = 20, delay: float = 0.5):
    """Jalankan simulasi dan kembalikan daftar node."""
    ids = list(range(1, n_nodes + 1))
    nodes = [RaftNode(i, ids) for i in ids]
    for step in range(steps):
        time.sleep(delay)
        print(f"\n--- Step {step + 1} ---")
        leaders = [n for n in nodes if n.state == State.LEADER]
        if leaders:
            leader = random.choice(leaders)
            for node in nodes:
                if node.id != leader.id:
                    node.on_heartbeat(leader.current_term)
            if step % 5 == 0:
                leader.append_entry(f"command-{step}")
        for node in nodes:
            node.tick()
        for node in nodes:
            print(f"Node {node.id}: {node.state.name} | Term {node.current_term} | Log len {len(node.log)}")
    return nodes
```

</details>

<details open>
<summary><b>modul/simulasi_raft.py</b></summary>

```python
"""Contoh simulasi memakai modul raft_module (5 node, 15 langkah)."""
from raft_module import simulate_raft, State

nodes = simulate_raft(n_nodes=5, steps=15, delay=0.3)

print("\n=== Ringkasan akhir ===")
for n in nodes:
    print(f"Node {n.id}: {n.state.name}, term={n.current_term}, log={n.log}")
print("Leader:", [n.id for n in nodes if n.state == State.LEADER])
```

</details>

Cara menjalankan:

```bash
cd modul
python3 simulasi_raft.py
```

Contoh ringkasan akhir (acak, bisa berbeda):

```text
=== Ringkasan akhir ===
Node 1: FOLLOWER, term=1, log=[]
Node 2: LEADER, term=1, log=['command-5', 'command-10']
Node 3: FOLLOWER, term=1, log=[]
Node 4: FOLLOWER, term=1, log=[]
Node 5: FOLLOWER, term=1, log=[]
Leader: [2]
```

---

## 6. Kesimpulan

| Topik | Kesimpulan |
|---|---|
| NTP / Chrony | Jam lokal disinkronkan ke server NTP; selisih awal 13,7 ms menjadi 0 detik setelah `makestep` |
| Vector clock | Menentukan urutan kausal antar event tanpa jam fisik yang sama; hasil program sama dengan hitungan manual |
| Multithread | Urutan selesai thread tidak dapat diprediksi (pada percobaan, Task E selesai sebelum Task D) |
| Race condition | Terjadi saat *check-then-act* tidak atomik (saldo -60); diatasi dengan `Lock` pada critical section |
| Deadlock | Terjadi karena siklus tunggu antar lock; dicegah dengan melepas lock sebelum meminta lock lain dan memakai `timeout` |
| Raft | Konsensus dicapai lewat pemilihan leader berbasis term, election timeout acak, dan suara mayoritas |
