.section .text

// FUNCIONES DE ENTRADA/SALIDA
.include "constants.s"
.include "data.s"
.type readTextInput, %function
.global readTextInput
readTextInput:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // Leer texto del usuario
    read STDIN, buffer, 256
    
    ldr x1, =buffer
    ldr x2, =matState
    mov x3, #0

convert_text_loop:
    cmp x3, #16
    bge pad_remaining_bytes
    
    ldrb w4, [x1, x3]
    cmp w4, #10  // newline
    beq pad_remaining_bytes
    cmp w4, #0   // null terminator
    beq pad_remaining_bytes
    
    // Almacenar en orden column-major
    mov x7, #4
    udiv x8, x3, x7      // fila = index / 4
    msub x9, x8, x7, x3  // columna = index % 4
    mul x10, x9, x7      // columna * 4
    add x10, x10, x8     // + fila
    
    strb w4, [x2, x10]
    add x3, x3, #1
    b convert_text_loop

pad_remaining_bytes:
    cmp x3, #16
    bge convert_text_done
    
    // Rellenar bytes restantes con 0
    mov x7, #4
    udiv x8, x3, x7
    msub x9, x8, x7, x3
    mul x10, x9, x7
    add x10, x10, x8
    
    mov w4, #0
    strb w4, [x2, x10]
    add x3, x3, #1
    b pad_remaining_bytes

convert_text_done:
    ldp x29, x30, [sp], #16
    ret
    .size readTextInput, (. - readTextInput)

.type convertHexKey, %function
.global convertHexKey
convertHexKey:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    read STDIN, buffer, 33
    ldr x1, =buffer
    ldr x2, =key
    mov x3, #0      // contador de bytes procesados
    mov x11, #0     // índice en el buffer

convert_hex_loop:
    cmp x3, #16
    bge convert_hex_done

skip_non_hex:
    ldrb w4, [x1, x11]
    cmp w4, #0
    beq convert_hex_done
    cmp w4, #10
    beq convert_hex_done
    
    bl is_hex_char
    cmp w0, #1
    beq process_hex_pair
    
    add x11, x11, #1
    b skip_non_hex

process_hex_pair:
    ldrb w4, [x1, x11]
    add x11, x11, #1
    bl hex_char_to_nibble
    lsl w5, w0, #4
    
    ldrb w4, [x1, x11]
    add x11, x11, #1
    bl hex_char_to_nibble
    orr w5, w5, w0
    
    strb w5, [x2, x3]
    add x3, x3, #1
    b convert_hex_loop

convert_hex_done:
    ldp x29, x30, [sp], #16
    ret
    .size convertHexKey, (. - convertHexKey)

// Funciones auxiliares para hexadecimal
is_hex_char:
    cmp w4, #'0'
    blt not_hex
    cmp w4, #'9'
    ble is_hex
    
    orr w4, w4, #0x20  // convertir a minúscula
    cmp w4, #'a'
    blt not_hex
    cmp w4, #'f'
    ble is_hex

not_hex:
    mov w0, #0
    ret

is_hex:
    mov w0, #1
    ret

hex_char_to_nibble:
    cmp w4, #'0'
    blt hex_error
    cmp w4, #'9'
    ble hex_digit
    
    orr w4, w4, #0x20
    cmp w4, #'a'
    blt hex_error
    cmp w4, #'f'
    bgt hex_error
    
    sub w0, w4, #'a'
    add w0, w0, #10
    ret

hex_digit:
    sub w0, w4, #'0'
    ret

hex_error:
    print STDOUT, key_err_msg, lenKeyErr
    mov w0, #0
    ret

// FUNCIONES DE IMPRESIÓN
.type printMatrix, %function
.global printMatrix
printMatrix:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    str x0, [sp, #16]   // matriz
    str x1, [sp, #24]   // mensaje
    str x2, [sp, #32]   // longitud mensaje
    
    // Imprimir mensaje
    mov x0, #1
    ldr x1, [sp, #24]
    ldr x2, [sp, #32]
    mov x8, #64
    svc #0
    
    mov x23, #0  // fila

print_row_loop:
    cmp x23, #4
    bge print_matrix_done
    
    mov x24, #0  // columna

print_col_loop:
    cmp x24, #4
    bge print_row_newline
    
    // Calcular índice: fila * 4 + columna
    mov x25, #4
    mul x25, x23, x25
    add x25, x25, x24
    
    ldr x20, [sp, #16]
    ldrb w0, [x20, x25]
    bl print_hex_byte
    
    add x24, x24, #1
    b print_col_loop

print_row_newline:
    print STDOUT, newline, 1
    add x23, x23, #1
    b print_row_loop

print_matrix_done:
    print STDOUT, newline, 1
    ldp x29, x30, [sp], #48
    ret
    .size printMatrix, (. - printMatrix)

.type print_hex_byte, %function
print_hex_byte:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    and w1, w0, #0xF0
    lsr w1, w1, #4
    and w2, w0, #0x0F
    
    // Convertir nibble alto
    cmp w1, #10
    blt high_digit
    add w1, w1, #'A' - 10
    b high_done
high_digit:
    add w1, w1, #'0'
high_done:
    
    // Convertir nibble bajo
    cmp w2, #10
    blt low_digit
    add w2, w2, #'A' - 10
    b low_done
low_digit:
    add w2, w2, #'0'
low_done:
    
    // Imprimir byte
    sub sp, sp, #16
    strb w1, [sp]
    strb w2, [sp, #1]
    mov w3, #' '
    strb w3, [sp, #2]
    
    mov x0, #1
    mov x1, sp
    mov x2, #3
    mov x8, #64
    svc #0
    
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret

.type printExpandedKeys, %function
.global printExpandedKeys
printExpandedKeys:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    str x21, [sp, #32]
    str x22, [sp, #40]
    
    print STDOUT, msg_expanded_keys, lenMsgExpKeys
    
    ldr x19, =expandedKeys
    mov x20, #0  // número de ronda

print_rounds_loop:
    cmp x20, #11
    bge print_rounds_done
    
    print STDOUT, msg_round_key, lenMsgRoundKey
    mov w0, w20
    bl printRoundNumber
    print STDOUT, msg_colon, 2
    
    // Calcular offset de la subclave
    mov x21, #16
    mul x21, x20, x21
    add x21, x19, x21
    
    // Imprimir en formato 4x4
    mov x22, #0  // fila
print_key_rows:
    cmp x22, #4
    bge print_key_done
    
    mov x23, #0  // columna
print_key_cols:
    cmp x23, #4
    bge print_key_row_end
    
    // Calcular índice column-major
    mov x2, #4
    mul x2, x23, x2
    add x2, x2, x22
    
    ldrb w0, [x21, x2]
    bl print_hex_byte
    
    add x23, x23, #1
    b print_key_cols

print_key_row_end:
    print STDOUT, newline, 1
    add x22, x22, #1
    b print_key_rows

print_key_done:
    add x20, x20, #1
    b print_rounds_loop

print_rounds_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldr x21, [sp, #32]
    ldr x22, [sp, #40]
    ldp x29, x30, [sp], #48
    ret
    .size printExpandedKeys, (. - printExpandedKeys)

.type printRoundNumber, %function
printRoundNumber:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #16
    
    cmp w0, #10
    blt single_digit
    
    // Dos dígitos
    mov w1, #'1'
    strb w1, [sp, #0]
    mov w1, #'0'
    strb w1, [sp, #1]
    
    mov x0, #1
    mov x1, sp
    mov x2, #2
    mov x8, #64
    svc #0
    b print_round_done

single_digit:
    add w0, w0, #'0'
    strb w0, [sp]
    
    mov x0, #1
    mov x1, sp
    mov x2, #1
    mov x8, #64
    svc #0

print_round_done:
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret
    .size printRoundNumber, (. - printRoundNumber)

.type printRoundHeader, %function
printRoundHeader:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    print STDOUT, msg_round, lenMsgRound
    
    sub sp, sp, #16
    cmp w0, #10
    blt round_single_digit
    
    mov w1, #'1'
    strb w1, [sp, #0]
    mov w1, #'0'
    strb w1, [sp, #1]
    
    mov x0, #1
    mov x1, sp
    mov x2, #2
    mov x8, #64
    svc #0
    b round_print_end

round_single_digit:
    add w0, w0, #'0'
    strb w0, [sp]
    
    mov x0, #1
    mov x1, sp
    mov x2, #1
    mov x8, #64
    svc #0

round_print_end:
    add sp, sp, #16
    print STDOUT, msg_round_end, lenMsgRoundEnd
    
    ldp x29, x30, [sp], #16
    ret
    .size printRoundHeader, (. - printRoundHeader)

.type printResult, %function
.global printResult
printResult:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    print STDOUT, msg_result, lenMsgResult
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    ldp x29, x30, [sp], #16
    ret
    .size printResult, (. - printResult)
    