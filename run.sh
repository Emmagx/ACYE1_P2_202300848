#!/bin/bash
echo "Compilando AES ARM64..."

# Ensamblar
echo "Ensamblando main.s..."
aarch64-linux-gnu-as -o main.o main.s

if [ $? -ne 0 ]; then
    echo "Error en el ensamblaje"
    exit 1
fi

# Enlazar
echo "Enlazando..."
aarch64-linux-gnu-ld -o aes main.o

if [ $? -ne 0 ]; then
    echo "Error en el enlace"
    exit 1
fi

echo "Compilación exitosa!"
echo "Ejecutando con QEMU:"
qemu-aarch64 ./aes