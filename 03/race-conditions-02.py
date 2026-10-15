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
