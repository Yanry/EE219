; =======================================
; task1_2
; =======================================

; load matrix_A base-address 0x80100000 to the register x1 
; ( the immediate number is already shifted 12-bits here )
lui     x1,     2148532224          ; x1 = 0x80100000, A
lui     x15,    2148532224          ; x15= 0x80100000, A
lui     x2,     2151677952          ; x2 = 0x80300000, BT
lui     x3,     2152726528          ; x3 = 0x80500000, C
lui     x4,     2154823680          ; x4 = 0x80700000, D

addi    x5,     zero,   63          ; x5 = 63, loop1 num 64
addi    x6,     zero,   0           ; x6 = 0 , zero

addi    x7,     zero,   0           ; x7 = 0 , loop count

; load C to D loop
loop1: 
lw      x8,     0(x3)               ; x8  = C[0][0]
sw      x8,     0(x4)               ; D[0][0] = x8 
addi    x7,     x7,     1           ; x7 = x7 + 1 , loop1 count increase
blt     x5,     x7,     label1      ; if( x7>63 ) jump to label1
addi    x3,     x3,     4           ; x3 = x3 + 4, C address increase
addi    x4,     x4,     4           ; x4 = x4 + 4, D address increase
jal     x8,     loop1               ; jump to loop1 

; reset loop1 param
label1:
lui     x3,     2152726528          ; x2 = 0x80500000, C
lui     x4,     2154823680          ; x2 = 0x80700000, D
addi    x7,     zero,   0           ; x7 = 0 , loop count reset

addi    x11,    zero,   0           ; x11 = 0, loop2 count
addi    x12,    zero,   0           ; x12 = 0, loop3 count
addi    x16,    zero,   0           ; x16 = 0, loop4 count
addi    x13,    zero,   7           ; x13 = 7, loop2 num 8
; A * B + D, output stationary
loop2:
lw      x8,     0(x1)               ; x8  = A[0][0]
lw      x9,     0(x2)               ; x9  = BT[0][0]
mul     x10,    x8,     x9          ; x10 = x8 * x9
lw      x14,    0(x4)               ; x14 = D[0][0]
add     x14,    x14,    x10         ; x14 = x14 + x10
sw      x14,    0(x4)               ; D[0][0] = x14 

addi    x11,    x11,    1           ; x11 = x11 + 1 , loop2 count increase
blt     x13,    x11,    label2      ; if( x11>7 ) jump to label2
addi    x2,     x2,     4           ; x2 = x2 + 4, B address increase
addi    x1,     x1,     4           ; x1 = x1 + 4, A address increase
jal     x8,     loop2               ; jump to loop2 

label2:
addi    x11,    zero,   0           ; x11 = 0, loop2 count reset
addi    x12,    x12,    1           ; x12 = x12 + 1, loop3 count increase
blt     x13,    x12,    label3      ; if( x12>7 ) jump to label3
addi    x1,     x15,    0           ; x1  = x15 + 4, A address reset
addi    x2,     x2,     4           ; x2 = x2 + 4, B address increase
addi    x4,     x4,     4           ; x4 = x4 + 4, D address increase
jal     x8,     loop2               ; jump to loop2

label3:
addi    x12,    zero,   0           ; x12 = 0, loop2 count reset
addi    x16,    x16,    1           ; x16 = x16 + 1 , loop4 count increase
blt     x13,    x16,    label4      ; if( x16>7 ) jump to label4
addi    x15,    x1,     4           ; x15  = x1 + 4, A row increase
addi    x1,     x15,    0           ; x1   = x15, A row increase
lui     x2,     2151677952          ; x2 = 0x80300000, BT address reset
addi    x4,     x4,     4           ; x4 = x4 + 4, D address increase
jal     x8,     loop2               ; jump to loop2 

label4:
halt