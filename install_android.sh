#!/bin/bash

# Проверяем, запущен ли скрипт от рута (sudo)
if [ "$EUID" -ne 0 ]; then
  echo "Скрипт нужно запустить с правами sudo. Выполни: sudo bash install_android.sh"
  exit 1
fi

# Получаем имя твоего реального пользователя (чтобы не кидать файлы в /root)
REAL_USER=${SUDO_USER:-$(whoami)}
USER_HOME=$(eval echo ~$REAL_USER)

echo "=== 1. Установка базовых зависимостей и Cage ==="
apt update
apt install -y curl ca-certificates cage

echo "=== 2. Установка Waydroid ==="
# Добавляем официальный репозиторий
curl -s https://repo.waydro.id | bash
apt install -y waydroid

echo "=== 3. Инициализация базовой системы (без гугл-сервисов) ==="
# Команда скачает нужные образы, если их еще нет (около 1 ГБ)
waydroid init

echo "=== 4. Выдача прав на видеокарту AMD для твоего пользователя ==="
usermod -aG render,video $REAL_USER

echo "=== 5. Настройка и запуск системной службы эмулятора ==="
systemctl enable --now waydroid-container

echo "=== 6. Создание изолированного ярлыка на рабочем столе ==="
DESKTOP_FILE="$USER_HOME/Desktop/Android.desktop"

# Создаем ярлык с нашим "ядерным" фиксом для окон
cat << 'EOF' > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=Android
Exec=bash -c "waydroid session stop; WAYLAND_DISPLAY=wayland-android cage waydroid show-full-ui"
Icon=waydroid
Terminal=false
Categories=System;
EOF

# Делаем ярлык запускаемым и отдаем его твоему пользователю
chmod +x "$DESKTOP_FILE"
chown $REAL_USER:$REAL_USER "$DESKTOP_FILE"

echo "=== 7. Скачиваем Aegis Authenticator на рабочий стол ==="
wget -q --show-progress https://github.com/beemdevelopment/Aegis/releases/download/v3.0/aegis-v3.0-x86_64.apk -O "$USER_HOME/Desktop/Aegis.apk"
chown $REAL_USER:$REAL_USER "$USER_HOME/Desktop/Aegis.apk"

echo ""
echo "=================================================================="
echo "УСТАНОВКА ЗАВЕРШЕНА!"
echo "=================================================================="
echo "1. ОБЯЗАТЕЛЬНО ПЕРЕЗАГРУЗИ КОМПЬЮТЕР прямо сейчас (чтобы применились права на AMD)."
echo "2. После перезагрузки на рабочем столе будет ярлык 'Android' — запускай его двойным кликом."
echo "3. Aegis APK тоже лежит на рабочем столе. Установить его можно командой в терминале (без sudo):"
echo "   waydroid app install ~/Desktop/Aegis.apk"
echo "=================================================================="
