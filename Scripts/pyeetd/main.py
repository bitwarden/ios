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

def main():
    while True:
        output = []
        output.append(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - pyeetd scanning for processes ...")
        processes = get_processes()
        output.append("PID\tCPU%\tMemory%\tName")
        for p in processes[:40]:
            output.append(f"{p.pid}\t{p.cpu_percent}%\t{p.memory_percent}%\t{p.name}")

        print("\n".join(output))
        # for p in processes:
        #     try:
        #         if p.name in DEFAULT_PROCESSES:
        #             if SIMULATOR_PATH_SEARCH_KEY in p.name:
        #                 print(f"Stopping process: {p.name}, PID: {p.pid}, CPU: {p.cpu_percent}%")
        #                 os.kill(p.pid, signal.SIGSTOP)

        #     except OSError:
        #         # Process may have disappeared or we don't have permission
        #         continue

        time.sleep(SLEEP_DELAY)

if __name__ == '__main__':
    main()
