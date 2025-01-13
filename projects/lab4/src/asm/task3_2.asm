; =======================================
; task3_2
; =======================================

; load matrix_A base-address 0x80100000 to the register x1 
; ( the immediate number is already shifted 12-bits here )
lui     x1,     2149580800          ;	nop		; 	nop  ; x1 = 0x80200000, AT
lui     x2,     2151677952          ;	nop		; 	nop  ; x2 = 0x80400000, BT
lui     x3,     2153775104          ;	nop		; 	nop	 ; x3 = 0x80600000, CT
lui     x4,     2155872256          ;	nop		; 	nop  ; x4 = 0x80800000, DT

addi    x5,     zero,   7           ;	nop		;	nop	 ; x5 = 7, loop1 num 7
addi    x6,     zero,   0           ;	nop		;	nop  ; x6 = 0 , loop count

addi    x7,     zero,   0           ;	nop		; 	nop  ; x7 = 0 , loop count

; load CT to DT loop
loop1: 
nop ;	nop ;	vle32.v      vx3,     x3    ,	1        ; vx3  = CT[0][7:0]
addi    x7,     x7,     1           ;	nop ;	vse32.v      vx3,     x4    ,	1      
; loop1 count increase				;	DT[0][7:0] = vx3 
blt     x5,     x7,     label1      ;	nop		;	nop	 ; if( x7>7 ) jump to label1
addi    x3,     x3,     32          ;	nop		; 	nop	 ; x3 = x3 + 32, CT address increase
addi    x4,     x4,     32          ; 	nop		; 	nop	 ; x4 = x4 + 32, DT address increase
jal     x0,     loop1               ; 	nop		; 	nop  ; jump to loop1 

; reset loop1 param
label1:
lui     x3,     2153775104          ; 	nop		; 	nop  ; x3 = 0x80600000, CT
lui     x4,     2155872256          ; 	nop		; 	nop  ; x4 = 0x80800000, DT
addi    x7,     zero,   0           ; 	nop		; 	nop  ; x7 = 0 , loop count reset

; MAC, output staionary
loop2:
lw      x8,     0(x2)               ;	nop		;	vle32.v      vx1,     x1    ,	1      
; x8  = BT[0][0]					;	AT[0][7:0] = vx1
nop ;	vmul.vx      vx3,     vx1,      x8,     1     ;	vle32.v      vx4,     x4    ,	1       ;		vx4  = DT[0][7:0]	vx3 = AT[0][7:0] * BT[0][0]
# nop	;	vmul.vx      vx3,     vx1,      x8,     1     ;	 nop  ;	vx3 = AT[0][7:0] * BT[0][0]
nop	;	vadd.vv      vx3,     vx3,      vx4,    1     ;	 nop  ; vx3 = vx3 + vx4
addi    x7,     x7,     1           ;	nop		;	vse32.v       vx3,     x4    ,	1   	
; loop2 count increase				;	DT[0][7:0] = vx3 
blt     x5,     x7,     label2      ;	nop		;	nop	 ; if( x7>7 ) jump to label2
addi    x1,     x1,     32          ;	nop		;	nop	 ; AT row address increase
addi    x2,     x2,     4           ;	nop		;	nop	 ; B address increase
jal     x0,     loop2               ; 	nop		;	nop	 ; jump to loop2 

label2:
addi    x7,     zero,   0           ;	nop		;	nop	 ;	nop	 ; x7 = 0 , loop count reset
addi    x6,     x6,   	1           ;	nop		;	nop	 ; x6 = 0 , loop count increase
blt     x5,     x6,     label3      ;	nop		;	nop	 ; if( x6>7 ) jump to label3
lui     x1,     2149580800          ;	nop		;	nop	 ; x1 = 0x80200000, AT
addi    x2,     x2,     4           ;	nop		;	nop	 ; B address increase
addi    x4,     x4,     32          ;	nop		;	nop	 ; DT row address increase
jal     x0,     loop2               ; 	nop		;	nop	 ; jump to loop2

label3:
halt; nop; nop;