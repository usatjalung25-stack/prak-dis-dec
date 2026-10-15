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
