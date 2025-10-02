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
    "ecosystemanalyticsd"
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

# How often to print process info (in seconds)
PRINT_PROCESSES_INTERVAL = 60

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

    @property
    def output_string(self) -> str:
        return f"{self.pid}\t{self.cpu_percent}%\t{self.memory_percent}%\t{self.name}\t{self.environment}"

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
    output = []
    output.append("🧠 Processes sorted by memory usage:")
    output.append("PID\tCPU%\tMemory%\tName\tEnvironment")
    limit = len(processes) if limit == -1 else limit
    for p in processes[:limit]:
        output.append(p.output_string)

    output.append("--------------------------------")
    output.append("⚡️ Processes sorted by CPU usage:")
    output.append("PID\tCPU%\tMemory%\tName\tEnvironment")

    processes_sorted_by_memory = sorted(processes, key=lambda x: x.memory_percent, reverse=True)
    for p in processes_sorted_by_memory[:limit]:
        output.append(p.output_string)
    print("\n".join(output))

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
        output.append(f"pyeetd: Stopping - {p.output_string}")
        os.killpg(p.pid, signal.SIGKILL)
    return output

def main():
    # processes = get_processes(ProcessSort.CPU)
    # print_processes(processes, 20)
    print_cycles = PRINT_PROCESSES_INTERVAL // SLEEP_DELAY
    i = 0
    while True:
        output = []
        processes = get_processes(ProcessSort.CPU)
        processes_to_yeet = find_unwanted(processes)
        output.extend(yeet(processes_to_yeet))
        output.append(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - pyeetd {len(processes_to_yeet)} processes.")
        print("\n".join(output))

        if i % print_cycles == 0:
            output.append("--------------------------------")
            print_processes(processes, 20)

        i += 1
        time.sleep(SLEEP_DELAY)

if __name__ == '__main__':
    main()
