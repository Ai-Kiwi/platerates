import threading
import requests
import time

url = "http://127.0.0.1:3030"
num_threads = 25
requests_per_thread = 100



# Function to be executed by each thread
def send_requests(thread_id):
    for i in range(requests_per_thread):
        try:
            #get post feed
            response = requests.get(url + "/post/feed?page=0&page_size=5")
            if response.status_code != 200:
                print("request failed")

            #get post data
            response = requests.get(url + "/post/data?postId=qJKJjOj03v89Ry4c")
            if response.status_code != 200:
                print("request failed")

            #get post maker data
            response = requests.get(url + "/profile/basicData?userId=xjQZP7KfGphN4rIk")
            if response.status_code != 200:
                print("request failed")

            #get post image
            response = requests.get(url + "/post/image?postId=qJKJjOj03v89Ry4c&imageNumber=0")
            if response.status_code != 200:
                print("request failed")

        except requests.RequestException as e:
            print(f"Thread {thread_id}, Request {i + 1}, Error: {e}")

# Create and start threads
threads = []
start_time = time.time()

for i in range(num_threads):
    thread = threading.Thread(target=send_requests, args=(i,))
    threads.append(thread)
    thread.start()

# Wait for all threads to complete
for thread in threads:
    thread.join()

end_time = time.time()
total_time = end_time - start_time

print(f"Total time taken: {total_time:.2f} seconds")
print(f"Total requests made {num_threads * requests_per_thread} over {num_threads} threads")
print(f"That means {(num_threads * requests_per_thread) / total_time} post requests per second")