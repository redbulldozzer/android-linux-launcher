#!/bin/bash

# 1. Убиваем всё старое
waydroid session stop
killall -9 cage weston 2>/dev/null
sleep 1

unset WAYLAND_DISPLAY

# 2. ФИЗИЧЕСКИЙ КАРАНТИН ДЛЯ ОКОН
CAGE_DIR="$XDG_RUNTIME_DIR/cage_waydroid"
mkdir -p "$CAGE_DIR"
chmod 700 "$CAGE_DIR"

ln -sf "$XDG_RUNTIME_DIR/pulse" "$CAGE_DIR/pulse" 2>/dev/null
ln -sf "$XDG_RUNTIME_DIR/pipewire-0" "$CAGE_DIR/pipewire-0" 2>/dev/null
ln -sf "$XDG_RUNTIME_DIR/bus" "$CAGE_DIR/bus" 2>/dev/null

# 3. Запускаем Cage
XDG_RUNTIME_DIR="$CAGE_DIR" cage -- waydroid show-full-ui &
CAGE_PID=$!

sleep 3

# 4. ДЕМОН БУФЕРА ОБМЕНА (Умный, не трогает файлы)
(
    export XDG_RUNTIME_DIR="$CAGE_DIR"
    export WAYLAND_DISPLAY=wayland-0
    LAST_HASH=""
    
    while kill -0 $CAGE_PID 2>/dev/null; do
        # Спрашиваем у Mint, ЧТО именно сейчас скопировано
        MINT_TYPES=$(xclip -selection clipboard -o -t TARGETS 2>/dev/null)
        
        # Если юзер скопировал файл или картинку — пропускаем цикл
        if echo "$MINT_TYPES" | grep -qE "uri-list|gnome-copied-files|image"; then
            sleep 0.5
            continue
        fi
        
        MINT_HASH=$(xclip -o -selection clipboard 2>/dev/null | md5sum | awk '{print $1}')
        ANDR_HASH=$(wl-paste 2>/dev/null | md5sum | awk '{print $1}')
        
        if [ "$MINT_HASH" != "$LAST_HASH" ] && [ "$MINT_HASH" != "d41d8cd98f00b204e9800998ecf8427e" ]; then
            xclip -o -selection clipboard 2>/dev/null | wl-copy
            LAST_HASH=$MINT_HASH
        elif [ "$ANDR_HASH" != "$LAST_HASH" ] && [ "$ANDR_HASH" != "d41d8cd98f00b204e9800998ecf8427e" ]; then
            wl-paste 2>/dev/null | xclip -selection clipboard -i
            LAST_HASH=$ANDR_HASH
        fi
        sleep 0.5
    done
) &

# 5. Ожидание закрытия окна
wait $CAGE_PID
waydroid session stop
