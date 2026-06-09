#!/usr/bin/env python3
import re
import sys
from collections import Counter

def main():
    log_file = sys.argv[1] if len(sys.argv) > 1 else "/var/log/squid/access.log"
    try:
        with open(log_file) as f:
            data = f.read()
    except FileNotFoundError:
        print("Лог-файл не найден")
        return

    domains = re.findall(r'http://([^/]+)', data)
    blocked = data.count("TCP_DENIED")
    counter = Counter(domains)

    print(f"Всего запросов: {len(domains)}")
    print(f"Заблокировано: {blocked}")
    print("Топ-10 доменов:")
    for d, c in counter.most_common(10):
        print(f"{d}: {c}")

if __name__ == "__main__":
    main()
