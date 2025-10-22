.section .text

// OPERACIONES AES BÁSICAS

.type subBytes, %function
.global subBytes
subBytes:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    
    ldr x19, =matState
    ldr x20, =Sbox
    mov x0, #0

subbytes_loop:
    cmp x0, #16
    bge subbytes_done
    
    ldrb w1, [x19, x0]
    uxtw x1, w1
    ldrb w2, [x20, x1]
    strb w2, [x19, x0]
    
    add x0, x0, #1
    b subbytes_loop

subbytes_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldp x29, x30, [sp], #32
    ret
    .size subBytes, (. - subBytes)

.type shiftRows, %function
.global shiftRows
shiftRows:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    str x21, [sp, #32]
    str x22, [sp, #40]
    
    ldr x19, =matState
    
    // Fila 1: rotar 1 posición
    ldrb w20, [x19, #4]
    ldrb w21, [x19, #5]
    strb w21, [x19, #4]
    ldrb w21, [x19, #6]
    strb w21, [x19, #5]
    ldrb w21, [x19, #7]
    strb w21, [x19, #6]
    strb w20, [x19, #7]
    
    // Fila 2: rotar 2 posiciones
    ldrb w20, [x19, #8]
    ldrb w21, [x19, #9]
    ldrb w22, [x19, #10]
    strb w22, [x19, #8]
    ldrb w22, [x19, #11]
    strb w22, [x19, #9]
    strb w20, [x19, #10]
    strb w21, [x19, #11]
    
    // Fila 3: rotar 3 posiciones
    ldrb w20, [x19, #12]
    ldrb w21, [x19, #15]
    strb w21, [x19, #12]
    ldrb w21, [x19, #14]
    strb w21, [x19, #15]
    ldrb w21, [x19, #13]
    strb w21, [x19, #14]
    strb w20, [x19, #13]
    
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldr x21, [sp, #32]
    ldr x22, [sp, #40]
    ldp x29, x30, [sp], #48
    ret
    .size shiftRows, (. - shiftRows)

// Multiplicación en Galois Field
.type galois_mul2, %function
galois_mul2:
    and w1, w0, #0x80
    lsl w0, w0, #1
    and w0, w0, #0xFF
    cmp w1, #0x80
    bne galois_mul2_done
    mov w2, #0x1B
    eor w0, w0, w2
galois_mul2_done:
    ret
    .size galois_mul2, (. - galois_mul2)

.type galois_mul3, %function
galois_mul3:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov w19, w0
    bl galois_mul2
    eor w0, w0, w19
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
    .size galois_mul3, (. - galois_mul3)

.type mixColumns, %function
.global mixColumns
mixColumns:
    stp x29, x30, [sp, #-80]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    str x21, [sp, #32]
    str x22, [sp, #40]
    str x23, [sp, #48]
    str x24, [sp, #56]
    str x25, [sp, #64]
    str x26, [sp, #72]
    
    ldr x19, =matState
    mov x20, #0  // columna

mixcol_row_loop:
    cmp x20, #4
    bge mixcol_done
    
    // Cargar columna
    ldrb w22, [x19, x20]        // a0
    add x0, x20, #4
    ldrb w23, [x19, x0]         // a1
    add x0, x20, #8
    ldrb w24, [x19, x0]         // a2
    add x0, x20, #12
    ldrb w25, [x19, x0]         // a3
    
    // Aplicar MixColumns
    mov w0, w22
    bl galois_mul2
    mov w26, w0                  // 2*a0
    
    mov w0, w23
    bl galois_mul3
    eor w26, w26, w0            // 2*a0 + 3*a1
    eor w26, w26, w24           // + a2
    eor w26, w26, w25           // + a3
    
    sub sp, sp, #16
    str w26, [sp, #0]           // b0
    
    mov w26, w22                // a0
    mov w0, w23
    bl galois_mul2
    eor w26, w26, w0            // a0 + 2*a1
    mov w0, w24
    bl galois_mul3
    eor w26, w26, w0            // a0 + 2*a1 + 3*a2
    eor w26, w26, w25           // + a3
    str w26, [sp, #4]           // b1
    
    mov w26, w22                // a0
    eor w26, w26, w23           // a0 + a1
    mov w0, w24
    bl galois_mul2
    eor w26, w26, w0            // a0 + a1 + 2*a2
    mov w0, w25
    bl galois_mul3
    eor w26, w26, w0            // a0 + a1 + 2*a2 + 3*a3
    str w26, [sp, #8]           // b2
    
    mov w0, w22
    bl galois_mul3
    mov w26, w0                  // 3*a0
    eor w26, w26, w23           // 3*a0 + a1
    eor w26, w26, w24           // 3*a0 + a1 + a2
    mov w0, w25
    bl galois_mul2
    eor w26, w26, w0            // 3*a0 + a1 + a2 + 2*a3
    str w26, [sp, #12]          // b3
    
    // Guardar resultados
    ldr w26, [sp, #0]
    strb w26, [x19, x20]
    
    add x0, x20, #4
    ldr w26, [sp, #4]
    strb w26, [x19, x0]
    
    add x0, x20, #8
    ldr w26, [sp, #8]
    strb w26, [x19, x0]
    
    add x0, x20, #12
    ldr w26, [sp, #12]
    strb w26, [x19, x0]
    
    add sp, sp, #16
    add x20, x20, #1
    b mixcol_row_loop

mixcol_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldr x21, [sp, #32]
    ldr x22, [sp, #40]
    ldr x23, [sp, #48]
    ldr x24, [sp, #56]
    ldr x25, [sp, #64]
    ldr x26, [sp, #72]
    ldp x29, x30, [sp], #80
    ret
    .size mixColumns, (. - mixColumns)
    