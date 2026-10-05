#!/bin/bash
TARGET="8.8.8.8"
LOG="network.log"

echo "=== Старт мониторинга сети: $(date) ===" >> "$LOG"

while true; do
    if ping -c 1 "$TARGET" &> /dev/null; then
        STATUS="ONLINE (Пинг успешен)"
    else
        STATUS="OFFLINE (Узел недоступен)"
    fi
    
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] Хост $TARGET -> $STATUS" >> "$LOG"
    sleep 15
done
