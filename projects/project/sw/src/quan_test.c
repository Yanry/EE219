#include "trap.h"
#include "model.h"

#define STR2(s)             #s
#define STR(s)              STR2(s)

#define INST_OPV_BIN(funct6, vm, vs2, vs1, funct3, vd, opcode) 0b##funct6##vm##vs2##vs1##funct3##vd##opcode
#define WORD(inst) ".word "#inst""
#define ASM_CUSTOM(inst) WORD(inst)
#define PUTCH ASM_CUSTOM(0x0005007f)

#define ADDR_A      ADDR_INPUT
#define ADDR_B      ADDR_WCONV1
#define ADDR_C      ADDR_SAVE
#define ADDR_ZERO   0x80850000

void vle32(register int* vd,register int* vs1){
    asm volatile( ".insn r 0x7, 0x6, 0x01, %0, %1, %2": :"r"(vd), "r"(vs1), "r"(0x0));
}

void vse32(register int* vd,register int* vs1){
    asm volatile( ".insn r 0x27, 0x6, 0x01, %0, %1, %2": :"r"(vd), "r"(vs1), "r"(0x0));
}

void vadd_vv(register int* vd,register int* vs1,register int* vs2){
    asm volatile( ".insn r 0x57, 0x0, 0x01, %0, %1, %2": :"r"(vd), "r"(vs1), "r"(vs2) );
}

void vadd_vx(register int* vd,register int* rs1,register int* vs2){
    asm volatile( ".insn r 0x57, 0x4, 0x01, %0, %1, %2": :"r"(vd), "r"(rs1), "r"(vs2) );
}

void vadd_vi(register int* vd,register int* imm,register int* vs2){
    asm volatile( ".insn r 0x57, 0x3, 0x01, %0, %1, %2": :"r"(vd), "r"(imm), "r"(vs2) );
} // under test

void vconv1_vv(register int* vd,register int* vs1,register int* vs2){
    asm volatile( ".insn r 0x57, 0x0, 0x03, %0, %1, %2": :"r"(vd), "r"(vs1), "r"(vs2) );
}

#define VRSI_VI(vd, imm, vs2) asm volatile(".insn r 0x57, 0x3, 0x51, %0, x" #imm ", %1": :"r"(vd), "r"(vs2) )

#define VLE_ALIGN(vd, vs1, align) do{ \
    uintptr_t addr = (uintptr_t)(vs1); \
    vle32(vd, (int*)vs1); \
    switch (addr%align) \
    { \
    case 1: \
        VRSI_VI(vd, 1, vd); \
        break; \
    case 2: \
        VRSI_VI(vd, 2, vd); \
        break; \
    case 3: \
        VRSI_VI(vd, 3, vd); \
        break; \
    case 4: \
        VRSI_VI(vd, 4, vd); \
        break; \
    case 5: \
        VRSI_VI(vd, 5, vd); \
        break; \
    case 6: \
        VRSI_VI(vd, 6, vd); \
        break; \
    case 7: \
        VRSI_VI(vd, 7, vd); \
        break; \
    default: \
        break; \
    } \
}while(0)

void vquan32_vv(register int* vd,register int* vs1,register int* vs2){
    asm volatile( ".insn r 0x57, 0x0, 0x53, %0, %1, %2": :"r"(vd), "r"(vs1), "r"(vs2) );
}
#define VQUAN32(vd, vs1, scale_address) do{ \
    register int *reg_vx20 asm ("x20"); \
    VLE_ALIGN(reg_vx20, scale_address, 8); \
    vquan32_vv(vd, reg_vx20, vs1); \
}while(0)

int main() {
    int i;

    int32_t *p_Input = (int32_t *)ADDR_INPUT ;
    //int8_t *p_Wconv1 = (int8_t *)ADDR_WCONV1 ;
    int8_t *p_Oconv1 = (int8_t *)ADDR_OUTCONV1 ;
    int8_t *p_Sconv1 = (int8_t *)ADDR_SCONV1;
    //int32_t *p_Zero = (int32_t *)ADDR_ZERO ;
    //register int *reg_vx0 asm ("x0");
    register int *reg_vx1 asm ("x1");
    // register int *reg_vx10 asm ("x10");
    //register int *reg_vx2 asm ("x2");
    //register int *reg_vx3 asm ("x3");
    //register int *reg_vx4 asm ("x4");

    /*
    vle32(reg_vx1, (int*)p_Input);
    vle32(reg_vx2, (int*)p_Wconv1);
    vadd_vv(reg_vx3, reg_vx1, reg_vx2);
    vse32( reg_vx3, (int*)p_Oconv1);
    */
    vle32(reg_vx1, (int*)p_Input+16/4);
    VQUAN32(reg_vx1, reg_vx1, (int*)p_Sconv1);
    vse32(reg_vx1, (int*)p_Oconv1);
/*
    for (i=0; i<16; i++) {
        int8_t data = *(p_Input+i);
        printf("%d\t",data);
    }
    printf("\n");
    for (i=0; i<16; i++) {
        int8_t data = *(p_Wconv1+i);
        printf("%d\t",data);
    }
    printf("\n");
*/

    for (i=0; i<16; i++) {
            int32_t data = *(p_Input+i+16/4);
            printf("%d\t",data);
    }
    printf("\n");
    for (i=0; i<16; i++) {
            int8_t data = *(p_Oconv1+i);
            printf("%d\t",data);
    }

    
    return 0;
}
