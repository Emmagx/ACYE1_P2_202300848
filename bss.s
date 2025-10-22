.section .bss
    // Variables globales
    .global matState
    matState: .space 16, 0
    
    .global key
    key: .space 16, 0
    
    .global criptograma
    criptograma: .space 16, 0
    
    .global expandedKeys
    expandedKeys: .space 176, 0
    
    // Variables temporales
    buffer: .space 256, 0
    tempWord: .space 4, 0
    roundKey: .space 16, 0