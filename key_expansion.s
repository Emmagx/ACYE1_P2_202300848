.section .text

// EXPANSIÓN DE CLAVE

.type rotByte, %function
rotByte:
    ldrb w1, [x0, #0]
    ldrb w2, [x0, #1]
    ldrb w3, [x0, #2]
    ldrb w4, [x0, #3]
    
    strb w2, [x0, #0]
    strb w3, [x0, #1]
    strb w4, [x0, #2]
    strb w1, [x0, #3]
    
    ret
    .size rotByte, (. - rotByte)

.type byteSub, %function
byteSub:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    
    mov x19, x0
    ldr x20, =Sbox
    mov x1, #0

bytesub_loop:
    cmp x1, #4
    bge bytesub_done
    
    ldrb w2, [x19, x1]
    uxtw x2, w2
    ldrb w3, [x20, x2]
    strb w3, [x19, x1]
    
    add x1, x1, #1
    b bytesub_loop

bytesub_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldp x29, x30, [sp], #32
    ret
    .size byteSub, (. - byteSub)

.type xorWords, %function
xorWords:
    ldrb w2, [x0, #0]
    ldrb w3, [x1, #0]
    eor w2, w2, w3
    strb w2, [x0, #0]
    
    ldrb w2, [x0, #1]
    ldrb w3, [x1, #1]
    eor w2, w2, w3
    strb w2, [x0, #1]
    
    ldrb w2, [x0, #2]
    ldrb w3, [x1, #2]
    eor w2, w2, w3
    strb w2, [x0, #2]
    
    ldrb w2, [x0, #3]
    ldrb w3, [x1, #3]
    eor w2, w2, w3
    strb w2, [x0, #3]
    
    ret
    .size xorWords, (. - xorWords)

.type copyWord, %function
copyWord:
    ldrb w2, [x1, #0]
    strb w2, [x0, #0]
    
    ldrb w2, [x1, #1]
    strb w2, [x0, #1]
    
    ldrb w2, [x1, #2]
    strb w2, [x0, #2]
    
    ldrb w2, [x1, #3]
    strb w2, [x0, #3]
    
    ret
    .size copyWord, (. - copyWord)

.type keyExpansion, %function
.global keyExpansion
keyExpansion:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    str x21, [sp, #32]
    str x22, [sp, #40]
    str x23, [sp, #48]
    str x24, [sp, #56]
    
    ldr x19, =key
    ldr x20, =expandedKeys
    ldr x21, =Rcon
    
    // Copiar clave inicial
    mov x22, #0
copy_initial_key:
    cmp x22, #16
    bge expansion_loop_init
    
    ldrb w23, [x19, x22]
    strb w23, [x20, x22]
    
    add x22, x22, #1
    b copy_initial_key

expansion_loop_init:
    mov x22, #4  // contador de palabras

expansion_loop:
    cmp x22, #44
    bge expansion_done
    
    // temp = word[i-1]
    sub x23, x22, #1
    mov x24, #4
    mul x23, x23, x24
    add x23, x20, x23
    
    ldr x0, =tempWord
    mov x1, x23
    bl copyWord
    
    // Si i es múltiplo de 4, aplicar transformación
    and x26, x22, #3
    cbnz x26, not_multiple_of_n
    
    ldr x0, =tempWord
    bl rotByte
    ldr x0, =tempWord
    bl byteSub
    
    // Aplicar Rcon
    lsr x25, x22, #2
    sub x25, x25, #1
    mov x24, #4
    mul x25, x25, x24
    add x25, x21, x25
    
    ldr x0, =tempWord
    ldrb w1, [x0, #0]
    ldrb w2, [x25, #0]
    eor w1, w1, w2
    strb w1, [x0, #0]

not_multiple_of_n:
    // word[i] = word[i-4] XOR temp
    sub x23, x22, #4
    mov x24, #4
    mul x23, x23, x24
    add x23, x20, x23
    
    mov x24, #4
    mul x24, x22, x24
    add x24, x20, x24
    
    mov x0, x24
    mov x1, x23
    bl copyWord
    
    mov x0, x24
    ldr x1, =tempWord
    bl xorWords
    
    add x22, x22, #1
    b expansion_loop

expansion_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldr x21, [sp, #32]
    ldr x22, [sp, #40]
    ldr x23, [sp, #48]
    ldr x24, [sp, #56]
    ldp x29, x30, [sp], #64
    ret
    .size keyExpansion, (. - keyExpansion)
    