// Constantes y macros del sistema
.equ SYS_EXIT, 93
.equ SYS_READ, 63
.equ SYS_WRITE, 64
.equ STDIN, 0
.equ STDOUT, 1

// Macros para imprimir y leer
.macro print fd, buffer, len
    mov x0, \fd
    ldr x1, =\buffer
    mov x2, \len
    mov x8, #64
    svc #0
.endm

.macro read fd, buffer, len
    mov x0, \fd
    ldr x1, =\buffer
    mov x2, \len
    mov x8, #63
    svc #0
.endm
