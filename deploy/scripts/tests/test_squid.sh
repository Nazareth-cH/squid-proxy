#!/bin/bash
set -euo pipefail
PROXY="http://localhost:3128"
USER="student"
PASS="student123"

echo "=== Тест 1: Разрешённый сайт ==="
curl -s -o /dev/null -w "%{http_code}" -x "$PROXY" -U "$USER:$PASS" http://example.com | grep -q 200 || exit 1

echo "=== Тест 2: Запрещённый домен ==="
curl -s -o /dev/null -w "%{http_code}" -x "$PROXY" -U "$USER:$PASS" http://facebook.com --max-time 10 | grep -qE "403|407" || exit 1

echo "=== Тест 3: Кэширование (если включено) ==="
URL="http://neverssl.com/online.jpg"
t1=$(curl -s -o /dev/null -w "%{time_total}" -x "$PROXY" -U "$USER:$PASS" "$URL")
t2=$(curl -s -o /dev/null -w "%{time_total}" -x "$PROXY" -U "$USER:$PASS" "$URL")
if (( $(echo "$t2 < $t1" | bc -l) )); then
    echo "Кэш работает: первый $t1 с, второй $t2 с"
else
    echo "Кэш не активен (можно игнорировать)"
fi

echo "=== Все тесты пройдены ==="
