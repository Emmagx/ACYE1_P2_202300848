.section .text
.include "constants.s"
.include "data.s"
.type _start, %function
.global _start
_start:
    // Leer y procesar texto
    print STDOUT, msg_txt, lenMsgTxt
    bl readTextInput
    
    print STDOUT, debug_state, lenDebugState
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix

    // Leer y procesar clave
    print STDOUT, msg_key, lenMsgKey
    bl convertHexKey
    
    print STDOUT, debug_key, lenDebugKey
    ldr x0, =key
    ldr x1, =debug_key
    mov x2, lenDebugKey
    bl printMatrix

    // Expandir clave y ejecutar AES
    bl keyExpansion
    bl printExpandedKeys
    bl AESRounds
    
    // Mostrar resultado
    bl printResult

    // Salir
    mov x0, #0
    mov x8, #93
    svc #0
    .size _start, (. - _start)