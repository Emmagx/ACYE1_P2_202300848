.section .text
.include "aes_operations.s"
.include "data.s"
.include "constants.s"
// MANEJO DE RONDAS AES

.type getRoundKey, %function
.global getRoundKey
getRoundKey:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    
    ldr x19, =expandedKeys
    mov x2, #16
    mul x2, x0, x2
    add x19, x19, x2
    
    mov x20, x1
    mov x2, #0

copy_round_key_loop:
    cmp x2, #16
    bge copy_round_key_done
    
    ldrb w3, [x19, x2]
    strb w3, [x20, x2]
    
    add x2, x2, #1
    b copy_round_key_loop

copy_round_key_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldp x29, x30, [sp], #32
    ret
    .size getRoundKey, (. - getRoundKey)

.type addRoundKeyWithRound, %function
.global addRoundKeyWithRound
addRoundKeyWithRound:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    
    // Obtener subclave de la ronda
    ldr x1, =roundKey
    bl getRoundKey
    
    ldr x19, =matState
    ldr x20, =roundKey
    mov x0, #0

addround_loop:
    cmp x0, #16
    bge addround_done
    
    // XOR byte a byte
    ldrb w1, [x19, x0]
    ldrb w2, [x20, x0]
    eor w3, w1, w2
    strb w3, [x19, x0]
    
    add x0, x0, #1
    b addround_loop

addround_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldp x29, x30, [sp], #32
    ret
    .size addRoundKeyWithRound, (. - addRoundKeyWithRound)

.type AESRounds, %function
.global AESRounds
AESRounds:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    // Ronda 0: AddRoundKey inicial
    mov w0, #0
    bl addRoundKeyWithRound

    mov w21, #1  // contador de ronda

round_loop:
    cmp w21, #10
    bgt rounds_done

    // Imprimir cabecera de ronda
    mov w0, w21
    bl printRoundHeader

    // SubBytes
    print STDOUT, msg_before_subbytes, lenMsgBeforeSub
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    bl subBytes
    
    print STDOUT, msg_after_subbytes, lenMsgAfterSub
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix

    // ShiftRows
    print STDOUT, msg_before_shiftrows, lenMsgBeforeShift
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    bl shiftRows
    
    print STDOUT, msg_after_shiftrows, lenMsgAfterShift
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix

    // MixColumns (solo hasta ronda 9)
    cmp w21, #10
    beq skip_mixcolumns
    
    print STDOUT, msg_before_mixcolumns, lenMsgBeforeMix
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    bl mixColumns
    
    print STDOUT, msg_after_mixcolumns, lenMsgAfterMix
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix

skip_mixcolumns:
    // AddRoundKey
    print STDOUT, msg_before_addroundkey, lenMsgBeforeAdd
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix

    mov w0, w21
    bl addRoundKeyWithRound

    print STDOUT, msg_after_addroundkey, lenMsgAfterAdd
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix

    add w21, w21, #1
    b round_loop

rounds_done:
    // Guardar resultado final
    ldr x0, =matState
    ldr x1, =criptograma
    mov x2, #0
copy_result_loop:
    cmp x2, #16
    bge copy_result_done
    ldrb w3, [x0, x2]
    strb w3, [x1, x2]
    add x2, x2, #1
    b copy_result_loop

copy_result_done:
    ldp x29, x30, [sp], #16
    ret
    .size AESRounds, (. - AESRounds)
    