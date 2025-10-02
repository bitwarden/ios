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
from enum import Enum

OS_PROCESSES = {
    "Spotlight",
    "ReportCrash",
    "com.apple.ecosystemd",
    "com.apple.metadata.mds",
}

SIMULATOR_PROCESSES = {
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
    is_simulator: bool

    @property
    def environment(self) -> str:
        return "Simulator" if self.is_simulator else "OS"

class ProcessSort(Enum):
    CPU = "cpu"
    MEMORY = "memory"

def get_processes(sort_by=ProcessSort.CPU):
    """Get all processes using ps command - equivalent to Swift's proc_listallpids"""
    sorty_by = "-ero" if sort_by == ProcessSort.CPU else "-emo"
    result = subprocess.run(['ps', sorty_by, 'pid,pcpu,pmem,comm'],
                            capture_output=True, text=True, check=True)
    processes = []

    for line in result.stdout.splitlines()[1:]:  # Skip header
        parts = line.strip().split(None, 3)
        if len(parts) >= 3:
            pid = int(parts[0])
            cpu_percent = float(parts[1])
            memory_percent = float(parts[2])
            name = parts[3]
            is_simulator = SIMULATOR_PATH_SEARCH_KEY in name
            processes.append(ProcessInfo(pid, cpu_percent, memory_percent, name, is_simulator))

    return processes

def print_processes(processes, limit=-1):
    print("PID\tCPU%\tMemory%\tName")
    limit = len(processes) if limit == -1 else limit
    for p in processes[:limit]:
        print(f"{p.pid}\t{p.cpu_percent}%\t{p.memory_percent}%\t{p.name}\t{p.environment}")

def find_unwanted(processes):
    yeeting = []
    for p in processes:
        process_target_list = SIMULATOR_PROCESSES if p.is_simulator else OS_PROCESSES
        for k in process_target_list:
            if k in p.name:
                yeeting.append(p)
    return yeeting

def yeet(processes):
    output = []
    for p in processes:
        output.append(f"pyeetd: Stopping - {p.pid} {p.cpu_percent}% {p.memory_percent}% {p.name} {p.environment}")
        os.killpg(p.pid, signal.SIGKILL)
    return output

def main():
    # processes = get_processes(ProcessSort.CPU)
    # print_processes(processes, 20)
    while True:
        output = []
        output.append(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - pyeetd scanning...")
        processes = get_processes(ProcessSort.CPU)
        processes_to_yeet = find_unwanted(processes)
        output.extend(yeet(processes_to_yeet))
        output.append(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - pyeetd {len(processes_to_yeet)} processes!")
        print("\n".join(output))
        time.sleep(SLEEP_DELAY)

if __name__ == '__main__':
    main()
