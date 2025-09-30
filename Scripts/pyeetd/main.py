#!/usr/bin/env python3
"""
pyeetd - https://github.com/biscuitehh/yeetd but python
"""

import os
import signal
import time
import subprocess
import re
from dataclasses import dataclass

DEFAULT_PROCESSES = {
    "AegirPoster",
    "InfographPoster",
    "CollectionsPoster",
    "ExtragalacticPoster",
    "KaleidoscopePoster",
    "EmojiPosterExtension",
    "AmbientPhotoFramePosterProvider",
    "PhotosPosterProvider",
    "AvatarPosterExtension",
    "GradientPosterExtension",
    "MonogramPosterExtension"
}

SIMULATOR_PATH_SEARCH_KEY = "simruntime/Contents/Resources/RuntimeRoot"

# How long to sleep between checks in seconds
SLEEP_DELAY = 10

@dataclass
class ProcessInfo:
    pid: int
    cpu_percent: float
    memory_percent: float
    name: str

def get_processes():
    """Get all processes using ps command - equivalent to Swift's proc_listallpids"""
    result = subprocess.run(['ps', '-ero', 'pid,pcpu,pmem,comm'],
                            capture_output=True, text=True, check=True)
    processes = []

    for line in result.stdout.splitlines()[1:]:  # Skip header
        parts = line.strip().split(None, 3)
        if len(parts) >= 3:
            pid = int(parts[0])
            cpu_percent = float(parts[1])
            memory_percent = float(parts[2])
            name = parts[3]
            processes.append(ProcessInfo(pid, cpu_percent, memory_percent, name))

    return processes

def print_processes(processes):
    print("PID\tCPU%\tMemory%\tName")
    for p in processes:
        print(f"{p.pid}\t{p.cpu_percent}%\t{p.memory_percent}%\t{p.name}")

def find_unwanted(processes):
    yeeting = []
    for p in processes:
        for k in DEFAULT_PROCESSES:
            if k in p.name:
                yeeting.append(p)
    return yeeting

def yeet(processes):
    output = []
    for p in processes:
        output.append(f"pyeetd: Stopping - {p.pid} {p.cpu_percent}% {p.memory_percent}% {p.name}")
        os.killpg(p.pid, signal.SIGKILL)
    return output

def main():
    while True:
        output = []
        output.append(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - pyeetd scanning...")
        processes = get_processes()
        #print_processes(processes)
        processes_to_yeet = find_unwanted(processes)
        output.extend(yeet(processes_to_yeet))
        output.append(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - pyeetd {len(processes_to_yeet)} processes!")
        print("\n".join(output))
        time.sleep(SLEEP_DELAY)

if __name__ == '__main__':
    main()
