#!/bin/bash
set -euo pipefail

echo "=== Тест: healthcheck без аргументов ==="
../healthcheck.sh

echo "=== Тест: несуществующий порт ==="
curl -x http://localhost:9999 http://example.com --max-time 2 2>/dev/null && exit 1 || echo "Ожидаемая ошибка"

echo "=== Тест граничных условий пройден ==="
