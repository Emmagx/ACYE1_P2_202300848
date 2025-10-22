#!/bin/bash
echo "🔨 Compilando AES-128 para ARM64..."

# Usar el ensamblador cruzado para ARM64
aarch64-linux-gnu-as -o constants.o constants.s
aarch64-linux-gnu-as -o data.o data.s  
aarch64-linux-gnu-as -o bss.o bss.s
aarch64-linux-gnu-as -o sbox.o sbox.s
aarch64-linux-gnu-as -o input_output.o input_output.s
aarch64-linux-gnu-as -o aes_operations.o aes_operations.s
aarch64-linux-gnu-as -o key_expansion.o key_expansion.s
aarch64-linux-gnu-as -o rounds.o rounds.s
aarch64-linux-gnu-as -o main.o main.s

# Enlazar para ARM64
aarch64-linux-gnu-ld -o aes128 main.o rounds.o key_expansion.o aes_operations.o input_output.o sbox.o bss.o data.o constants.o

# Verificar la arquitectura
echo "📁 Verificando arquitectura del ejecutable:"
file aes128

if [ -f "aes128" ]; then
    echo "✅ Compilación exitosa!"
    echo "📋 Ejecutable creado: ./aes128 (ARM64)"
else
    echo "❌ Error en la compilación"
    exit 1
fi