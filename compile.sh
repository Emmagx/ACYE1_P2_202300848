#!/bin/bash
echo "🔨 Compilando AES-128 para ARM64..."

# Verificar que las herramientas estén instaladas
command -v aarch64-linux-gnu-as >/dev/null 2>&1 || { echo "❌ aarch64-linux-gnu-as no encontrado"; exit 1; }
command -v aarch64-linux-gnu-ld >/dev/null 2>&1 || { echo "❌ aarch64-linux-gnu-ld no encontrado"; exit 1; }
command -v qemu-aarch64 >/dev/null 2>&1 || { echo "❌ qemu-aarch64 no encontrado"; exit 1; }

# Ensamblar ambos archivos
echo "📦 Ensamblando constants.s..."
aarch64-linux-gnu-as -o constants.o constants.s || exit 1

echo "📦 Ensamblando main.s..."
aarch64-linux-gnu-as -o aes128.o main.s || exit 1

# Enlazar
echo "🔗 Enlazando objetos..."
aarch64-linux-gnu-ld -o aes128 constants.o aes128.o || exit 1

# Verificar
echo "📁 Verificando arquitectura del ejecutable:"
if [ -f "aes128" ]; then
    file aes128
    echo "✅ Compilación exitosa!"
    echo "📋 Ejecutable creado: ./aes128 (ARM64)"
    
    # Dar permisos de ejecución
    chmod +x aes128
    
    # Ejecutar con QEMU
    echo "🚀 Ejecutando con QEMU:"
    qemu-aarch64 ./aes128
else
    echo "❌ Error en la compilación"
    exit 1
fi