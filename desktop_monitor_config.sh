#!/bin/bash

CONFIG1="$HOME/.i3/config"
CONFIG2="$HOME/.config/i3/config"

TARGET_LINE="exec --no-startup-id xset -dpms"

# ===== CONFIGURE AQUI =====
OUTPUT1="DisplayPort-0"
MODE1="2560x1440"
RATE1="180"

OUTPUT2="DisplayPort-1"
MODE2="1920x1080"
RATE2="144"
# ===========================

NEW_LINES=$(cat <<EOF

exec --no-startup-id xrandr --output $OUTPUT2 --mode $MODE2 --rate $RATE2 
exec --no-startup-id xrandr --output $OUTPUT1 --mode $MODE1 --rate $RATE1 --right-of $OUTPUT2
EOF
)

# Detecta qual config existe
if [ -f "$CONFIG1" ]; then
    CONFIG="$CONFIG1"
elif [ -f "$CONFIG2" ]; then
    CONFIG="$CONFIG2"
else
    echo "Arquivo de configuração do i3 não encontrado."
    exit 1
fi

# Evita duplicação
if grep -Fq "$OUTPUT1 --mode $MODE1 --rate $RATE1" "$CONFIG"; then
    echo "Configuração já existe."
    exit 0
fi

awk -v target="$TARGET_LINE" -v newline="$NEW_LINES" '
{
    print
    if ($0 == target) {
        print newline
    }
}
' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"

echo "Configuração adicionada com sucesso!"
