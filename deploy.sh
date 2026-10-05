#!/bin/bash
set -e

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Ошибка: Запустите скрипт с правами суперпользователя (sudo)."
  exit 1
fi

echo "=== [1/5] Создание loop-устройств и RAID 1 ==="
mkdir -p /mnt/raid-lab

# Очищаем старые монтирования и loop-устройства, если они остались от предыдущих запусков
umount /mnt/raid 2>/dev/null || true
mdadm --stop /dev/md0 2>/dev/null || true
losetup -D 2>/dev/null || true

# Создаем файлы-образы по 256 МБ
dd if=/dev/zero of=/mnt/raid-lab/disk1.img bs=1M count=256 status=none
dd if=/dev/zero of=/mnt/raid-lab/disk2.img bs=1M count=256 status=none

# Настраиваем loop-устройства
LOOP1=$(losetup -fP --show /mnt/raid-lab/disk1.img)
LOOP2=$(losetup -fP --show /mnt/raid-lab/disk2.img)
echo "[+] Loop-устройства созданы: $LOOP1 и $LOOP2"

# Создаем RAID 1 массив /dev/md0
yes | mdadm --create /dev/md0 --level=1 --raid-devices=2 $LOOP1 $LOOP2

echo "=== [2/5] Форматирование и монтирование RAID ==="
mkfs.ext4 -F /dev/md0
mkdir -p /mnt/raid
mount /dev/md0 /mnt/raid
echo "[+] RAID успешно примонтирован в /mnt/raid"

echo "=== [3/5] Сборка Docker-контейнера ==="
# Убедитесь, что запускаете скрипт из папки репозитория, где лежит Dockerfile
if [ ! -f "Dockerfile" ]; then
  echo "[-] Ошибка: Dockerfile не найден в текущей директории!"
  exit 1
fi

docker build -t network-monitor-tools .

echo "=== [4/5] Запуск контейнера ==="
docker rm -f my-app 2>/dev/null || true
docker run -d --name my-app -p 8080:8080 -v /var/log:/var/log:ro network-monitor-tools

echo "=== [5/5] Готово! Проверка статуса контейнера ==="
docker ps --filter name=my-app
echo "=== Все этапы развертывания успешно завершены! ==="
