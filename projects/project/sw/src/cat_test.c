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

void vrsi_vi(register int* vd,register int* imm,register int* vs2){
    asm volatile( ".insn r 0x57, 0x3, 0x51, %0, %1, %2": :"r"(vd), "r"(imm), "r"(vs2) );
}
#define VLE_ALIGN(vd, vs1, align) do{ \
    register int *reg_vx1 asm ("x1"); \
    register int *reg_vx2 asm ("x2"); \
    register int *reg_vx3 asm ("x3"); \
    register int *reg_vx4 asm ("x4"); \
    register int *reg_vx5 asm ("x5"); \
    register int *reg_vx6 asm ("x6"); \
    register int *reg_vx7 asm ("x7"); \
    uintptr_t addr = (uintptr_t)(vs1); \
    vle32(vd, (int*)vs1); \
    switch (addr%align) \
    { \
    case 1: \
        vrsi_vi(vd, reg_vx1, vd); \
        break; \
    case 2: \
        vrsi_vi(vd, reg_vx2, vd); \
        break; \
    case 3: \
        vrsi_vi(vd, reg_vx3, vd); \
        break; \
    case 4: \
        vrsi_vi(vd, reg_vx4, vd); \
        break; \
    case 5: \
        vrsi_vi(vd, reg_vx5, vd); \
        break; \
    case 6: \
        vrsi_vi(vd, reg_vx6, vd); \
        break; \
    case 7: \
        vrsi_vi(vd, reg_vx7, vd); \
        break; \
    default: \
        break; \
    } \
}while(0)

void vcat14_vv(register int* vd,register int* vs1,register int* vs2){
    asm volatile( ".insn r 0x57, 0x0, 0x55, %0, %1, %2": :"r"(vd), "r"(vs1), "r"(vs2) );
}

int main() {
    int i;

    int8_t *p_Input = (int8_t *)ADDR_INPUT ;
    //int8_t *p_Wconv1 = (int8_t *)ADDR_WCONV1 ;
    int8_t *p_Oconv1 = (int8_t *)ADDR_OUTCONV1 ;
    //int32_t *p_Zero = (int32_t *)ADDR_ZERO ;
    //register int *reg_vx0 asm ("x0");
    register int *reg_vx1 asm ("x1");
    register int *reg_vx2 asm ("x2");
    // register int *reg_vx3 asm ("x3");
    // register int *reg_vx4 asm ("x4");
    // register int *reg_vx8 asm ("x8");

    /*
    vle32(reg_vx1, (int*)p_Input);
    vle32(reg_vx2, (int*)p_Wconv1);
    vadd_vv(reg_vx3, reg_vx1, reg_vx2);
    vse32( reg_vx3, (int*)p_Oconv1);
    */
    int8_t* addr_ptr = p_Input;
    
    vle32(reg_vx1, (int*)addr_ptr);
    VLE_ALIGN(reg_vx2, (int*)(addr_ptr+18), 8);

    vcat14_vv(reg_vx1, reg_vx1, reg_vx2);
    vse32(reg_vx1, (int*)p_Oconv1);
    
    printf("%x\n", addr_ptr);

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
    for (i=0; i<32; i++) {
            int8_t data = *(p_Input+i);
            printf("%d\t",data);
    }
    printf("\n");
    for (i=0; i<32; i++) {
            int8_t data = *(p_Oconv1+i);
            printf("%d\t",data);
    }

    
    return 0;
}
