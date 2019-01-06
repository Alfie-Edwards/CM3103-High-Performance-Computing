import subprocess
import os

directory = 'Binaries'
exe_name = 'Blur.exe'
task_count = 222988
thread_divisions = 16
chunk_divisions = 26
runs_per_value = 10


def Run(threads, chunks):
    output = subprocess.check_output([exe_name, str(threads), str(chunks)], cwd=directory, env=os.environ, shell=True)
    time = float(output)
    return time


thread_range = range(1, thread_divisions + 1)
chunk_increment = 1 / chunk_divisions

chunk_range = []
n = 0
while n <= 1:
    chunk_range.append(n * task_count if n != 0 else 1)
    n += chunk_increment

with open('output_dynamic_linear.csv', 'a') as out:
    out.write("thread_count,chunk_size,average_time\n")
    for thread in thread_range:
        for chunk in chunk_range:
            total = 0
            for i in range(runs_per_value):
                total += Run(thread, chunk)
            total /= runs_per_value

            out.write(str(thread) + "," + str(chunk) + "," + str(total) + "\n")
