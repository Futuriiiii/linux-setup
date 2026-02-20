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

XRANDR_LINES=$(cat <<EOF

exec --no-startup-id xrandr --output $OUTPUT2 --mode $MODE2 --rate $RATE2 
exec --no-startup-id xrandr --output $OUTPUT1 --mode $MODE1 --rate $RATE1 --right-of $OUTPUT2
EOF
)

OLD_WORKSPACES=$(cat <<'EOF'
set $workspace1 "1: "
set $workspace2 "2: "
set $workspace3 "3: "
set $workspace4 "4: "
set $workspace5 "5"
set $workspace6 "6"
set $workspace7 "7"
set $workspace8 "8"
set $workspace9 "9"
set $workspace10 "10: "
EOF
)

NEW_WORKSPACES=$(cat <<'EOF'
set $workspace1 "1: "
set $workspace2 "2"
set $workspace3 "3"
set $workspace4 "4"
set $workspace5 "5"
set $workspace6 "6"
set $workspace7 "7: "
set $workspace8 "8: "
set $workspace9 "9: "
set $workspace10 "10: "
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

awk -v target="$TARGET_LINE" -v newline="$XRANDR_LINES" '
{
    print
    if ($0 == target) {
        print newline
    }
}

' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"

awk -v old="$OLD_WORKSPACES" -v new="$NEW_WORKSPACES" '
BEGIN {
    split(old, o, "\n")
    old_len = length(o)
}
{
    buffer[NR] = $0
}
END {
    for (i = 1; i <= NR; i++) {
        match_block = 1
        for (j = 1; j <= old_len; j++) {
            if (buffer[i+j-1] != o[j]) {
                match_block = 0
                break
            }
        }

        if (match_block) {
            print new
            i += old_len - 1
        } else {
            print buffer[i]
        }
    }
}
' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"

echo "Configuração adicionada com sucesso!"
