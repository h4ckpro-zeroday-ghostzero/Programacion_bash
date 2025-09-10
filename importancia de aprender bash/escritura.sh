#!/bin/bash
# full_demo escritura.sh
# Bash automatizacion de escritura por pantalla + creacion de pdf + convewrtir texto a voz 
# Autor: HackPro Demo

FILE="${1:-demo.txt}"
SPEED="${2:-0.05}"
OUTPUT="${FILE%.*}.pdf"

RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; CYAN="\e[36m"; RESET="\e[0m"
COLORS=($RED $GREEN $YELLOW $CYAN)

typewriter() {
    local text="$1"
    local color="$2"
    for ((i=0; i<${#text}; i++)); do
        echo -ne "${color}${text:$i:1}${RESET}"
        sleep "$SPEED"
    done
    echo ""
}

random_color() {
    echo "${COLORS[$RANDOM % ${#COLORS[@]}]}"
}

check_dependencies() {
    echo -e "${CYAN}🔍 Verificando dependencias...${RESET}"
    for cmd in python3 python3-venv python3-pip mpg123 pandoc xelatex whiptail; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${YELLOW}Instalando $cmd...${RESET}"
            sudo apt -y install $cmd
        fi
    done
}

setup_virtualenv() {
    if [[ ! -d "env" ]]; then
        python3 -m venv env
    fi
    source env/bin/activate
    pip install --upgrade pip
    pip install gtts
}

start_gtts() {
    source env/bin/activate
    python3 - <<END &
from gtts import gTTS
import os
FILE = "$FILE"
AUDIO_FILE = "audio_gtts.mp3"

with open(FILE, "r", encoding="utf-8") as f:
    text = f.read()

tts = gTTS(text=text, lang="es")
tts.save(AUDIO_FILE)
os.system(f"mpg123 -q {AUDIO_FILE}")
END
    TTS_PID=$!
}

generate_pdf() {
    echo -e "${CYAN}\n📄 Generando PDF con portada: $OUTPUT${RESET}"
    CLEAN_FILE="${FILE%.txt}_clean.txt"
    sed 's/‣/-/g' "$FILE" > "$CLEAN_FILE"

    PORTADA="portada.md"
    cat > "$PORTADA" <<EOL
# 🖥️ HackPro Academia
## Curso de Bash y Python
**Archivo:** $FILE

---

EOL

    MERGED="merged_temp.md"
    cat "$PORTADA" "$CLEAN_FILE" > "$MERGED"

    (
        for i in $(seq 1 100); do
            echo $i
            sleep 0.01
        done
    ) | whiptail --gauge "Generando PDF..." 6 60 0

    pandoc "$MERGED" -o "$OUTPUT" --pdf-engine=xelatex -V mainfont="DejaVu Sans" 2>/tmp/pdf_error.log
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✔ PDF generado exitosamente: $OUTPUT${RESET}"
    else
        echo -e "${RED}❌ Error al generar PDF. Revisa /tmp/pdf_error.log${RESET}"
    fi

    rm -f "$PORTADA" "$MERGED" "$CLEAN_FILE"
}

# -------------------------------
# VALIDACIÓN
if [[ ! -f "$FILE" ]]; then
    echo -e "${RED}❌ Archivo '$FILE' no encontrado.${RESET}"
    exit 1
fi

# -------------------------------
# EJECUCIÓN
check_dependencies
setup_virtualenv
start_gtts

# Mostrar texto con typewriter mientras gTTS reproduce audio
while IFS= read -r line; do
    typewriter "$line" "$(random_color)"
done < "$FILE"

# Esperar a que termine el audio
wait $TTS_PID

# Generar PDF con portada
generate_pdf

deactivate
echo -e "${GREEN}\n🎉 Script completado exitosamente.${RESET}"
