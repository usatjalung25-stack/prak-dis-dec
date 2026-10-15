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
