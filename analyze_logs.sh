#!/usr/bin/env bash

LOG_FILE="access.log"
LINES_COUNT=350

echo "Генерация тестового файла $LOG_FILE ($LINES_COUNT строк)..."

IPS=("192.168.1.10" "10.0.0.5" "172.16.0.12" "192.168.1.55" "10.0.0.99" "192.168.1.200")
METHODS=("GET" "POST" "PUT" "DELETE")
ENDPOINTS=("/api/users" "/api/login" "/api/orders" "/api/products" "/api/health")
STATUSES=(200 200 200 201 204 400 401 403 404 500 502 503)

> "$LOG_FILE"

for ((i=1; i<=LINES_COUNT; i++)); do
    IP="${IPS[$RANDOM % ${#IPS[@]}]}"
    METHOD="${METHODS[$RANDOM % ${#METHODS[@]}]}"
    ENDPOINT="${ENDPOINTS[$RANDOM % ${#ENDPOINTS[@]}]}"
    STATUS="${STATUSES[$RANDOM % ${#STATUSES[@]}]}"
    SEC=$(printf "%02d" $((i % 60)))
    MIN=$(printf "%02d" $(((i / 60) % 60)))
    
    echo "$IP - - [15/Aug/2026:10:$MIN:$SEC] \"$METHOD $ENDPOINT HTTP/1.1\" $STATUS" >> "$LOG_FILE"
done

echo "Файл $LOG_FILE успешно создан."
echo "----------------------------------------"

TOTAL_REQUESTS=$(awk 'END {print NR}' "$LOG_FILE")
echo "Общее количество запросов: $TOTAL_REQUESTS"

echo "Топ-3 IP-адреса с наибольшим числом запросов:"
grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 3 | awk '{print $2 " - " $1 " запросов"}'

ERROR_REQUESTS=$(grep -cE '\" [45][0-9]{2}$' "$LOG_FILE")
echo "Количество запросов с кодами 4xx и 5xx: $ERROR_REQUESTS"
