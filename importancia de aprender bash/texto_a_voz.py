#!/usr/bin/env python3
# texto_a_voz.py
# Convierte texto a voz usando gTTS y reproduce automáticamente

import sys
from gtts import gTTS
import os

if len(sys.argv) < 2:
    print("Uso: python texto_a_voz.py archivo.txt")
    sys.exit(1)

archivo = sys.argv[1]
audio_file = f"{archivo}.mp3"

# Leer archivo
with open(archivo, "r", encoding="utf-8") as f:
    text = f.read()

# Generar audio y reproducir
tts = gTTS(text=text, lang="es")
tts.save(audio_file)

# Reproducir automáticamente
os.system(f"mpg123 -q {audio_file}")
