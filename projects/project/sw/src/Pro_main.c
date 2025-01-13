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

// register int *reg_vx20 asm ("x20");


#define VLE32(vd, vs1) asm volatile(".insn r 0x7, 0x6, 0x01, x" #vd ", %0, x0": :"r"(vs1))

#define VSE32(vd, vs1) asm volatile(".insn r 0x27, 0x6, 0x01, x" #vd ", %0, x0": :"r"(vs1))

#define VADD_VV(vd, vs1, vs2) asm volatile(".insn r 0x57, 0x0, 0x01, x" #vd ", x" #vs1 ", x" #vs2 )

#define VCONV1_VV(vd, vs1, vs2) asm volatile(".insn r 0x57, 0x0, 0x03, x" #vd ", x" #vs1 ", x" #vs2 )

#define VCONV2_VV(vd, vs1, vs2) asm volatile(".insn r 0x57, 0x0, 0x07, x" #vd ", x" #vs1 ", x" #vs2 )

#define VRSI_VI(vd, imm, vs2) asm volatile(".insn r 0x57, 0x3, 0x51, x" #vd", x" #imm ", x" #vs2 )

// Align for 8bytes
#define VLE_ALIGN(vd, vs1, align) do{ \
    uintptr_t addr = (uintptr_t)(vs1); \
    VLE32(vd, (int*)vs1); \
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


#define VQUAN32_VV(vd, vs1, vs2) asm volatile(".insn r 0x57, 0x0, 0x53, x" #vd ", x" #vs1 ", x" #vs2 )

#define VQUAN32(vd, vs1, scale_address) do{ \
    VQUAN32_VV(vd, scale_address, vs1); \
}while(0)

#define VCAT14_VV(vd, vs1, vs2) asm volatile(".insn r 0x57, 0x0, 0x55, x" #vd ", x" #vs1 ", x" #vs2 )

#define VRELU_VI(vd, vs2) asm volatile(".insn r 0x57, 0x3, 0x57, x" #vd", x0, x" #vs2 )

#define VPOOL1_VV(vd, vs1, vs2) asm volatile(".insn r 0x57, 0x0, 0x5, x" #vd ", x" #vs1 ", x" #vs2 )
#define VPOOL2_VV(vd, vs1) asm volatile(".insn r 0x57, 0x0, 0x9, x" #vd ", x" #vs1 ", x0" )

#define VFC1_VV(vd, vs1, vs2) asm volatile(".insn r 0x57, 0x0, 0xb, x" #vd ", x" #vs1 ", x" #vs2 )

#define VBIAS16_VV(vd, vs1, vs2) asm volatile(".insn r 0x57, 0x0, 0x59, x" #vd ", x" #vs1 ", x" #vs2 )

int main() {

    // NCHW
    // conv1
    int8_t *p_Input = (int8_t *)ADDR_INPUT ;
    int8_t *p_Wconv1 = (int8_t *)ADDR_WCONV1 ;
    int8_t *p_Oconv1 = (int8_t *)ADDR_OUTCONV1 ;
    int8_t *p_Sconv1 = (int8_t *)ADDR_SCONV1 ;
    int8_t *p_Zero = (int8_t *)ADDR_ZERO ;

    VLE_ALIGN(10, (int*)p_Sconv1, 8);
    for (int out_channel = 0; out_channel < 12; out_channel++)
    {
        for (int out_row = 0; out_row < 28; out_row++)
        {
            VLE32(14, (int*)p_Zero);
            VLE32(15, (int*)p_Zero);
            for (int in_channel = 0; in_channel < 3; in_channel++)
            {
                for (int kernel_size = 0; kernel_size < 5; kernel_size++)
                {
                    VLE32(11, (int*)(p_Input + kernel_size*32 + in_channel*32*32 + out_row*32));    // input
                    VLE_ALIGN(12, (int*)(p_Input + kernel_size*32 + in_channel*32*32 + 14 + out_row*32), 8);
                    VLE_ALIGN(13, (int*)(p_Wconv1 + kernel_size*5 + in_channel*5*5 + out_channel*5*5*3), 8);   // conv1 weight
                    VCONV1_VV(11, 11, 13);
                    VADD_VV(14, 14, 11);
                    VCONV1_VV(12, 12, 13);
                    VADD_VV(15, 15, 12);
                }
            }
            VQUAN32(14, 14, 10);
            VQUAN32(15, 15, 10);
            VCAT14_VV(14, 14, 15);
            VRELU_VI(14, 14);
            VSE32(14, (int*)(p_Oconv1 + out_row*32 + out_channel*28*32)); 
        }
    }

    // pool1
    int8_t *p_Opool1 = (int8_t *)ADDR_OUTPOOL1;
    for (int out_channel = 0; out_channel < 12; out_channel++)
    {
        for (int in_row = 0; in_row < 28; in_row+=2)
        {
            VLE32(16, (int*)(p_Oconv1 + in_row*32 + out_channel*32*28));
            VLE32(17, (int*)(p_Oconv1 + (in_row+1)*32 + out_channel*32*28));
            VPOOL1_VV(16, 16, 17);
            VSE32(16, (int*)(p_Opool1 + in_row/2*16 + out_channel*16*14));
        }
    }

    // conv2
    int8_t *p_Wconv2 = (int8_t *)ADDR_WCONV2;
    int8_t *p_Sconv2 = (int8_t *)ADDR_SCONV2;
    int8_t *p_Oconv2 = (int8_t *)ADDR_OUTCONV2;

    VLE_ALIGN(10, (int*)p_Sconv2, 8);
    for (int out_channel = 0; out_channel < 32; out_channel++)
    {
        for (int out_row = 0; out_row < 12; out_row++)
        {
            VLE32(22, (int*)p_Zero);
            for (int in_channel = 0; in_channel < 12; in_channel++)
            {
                for (int kernel_size = 0; kernel_size < 3; kernel_size++)
                {
                    VLE32(21, (int*)(p_Opool1 + kernel_size*16 + in_channel*14*16 + out_row*16));
                    VLE_ALIGN(23, (int*)(p_Wconv2 + kernel_size*3 + in_channel*3*3 + out_channel*3*3*12), 8);
                    VCONV2_VV(21, 21, 23);
                    VADD_VV(22, 22, 21);
                }
            }
            VQUAN32(22, 22, 10);
            VRELU_VI(22, 22);
            VSE32(22, (int*)(p_Oconv2 + out_row*16 + out_channel*12*16)); 
        }
    }

    // pool2
    int8_t *p_Opool2 = (int8_t *)ADDR_OUTPOOL2;
    for (int out_channel = 0; out_channel < 32; out_channel++)
    {
        for (int in_row = 0; in_row < 12; in_row+=4)
        {
            VLE32(24, (int*)(p_Oconv2 + in_row*16 + out_channel*16*12));
            VPOOL2_VV(24, 24);
            VSE32(24, (int*)(p_Opool2 + in_row/2*8 + out_channel*8*6));
        }
    }

    // fc1
    int8_t *p_Wfc1 = (int8_t *)ADDR_WFC1;
    int8_t *p_Sfc1 = (int8_t *)ADDR_SFC1;
    int8_t *p_Ofc1 = (int8_t *)ADDR_OUTFC1;

    VLE_ALIGN(10, (int*)p_Sfc1, 8);
    for (int row = 0; row < 256; row+=16)
    {
        VLE32(13, (int*)p_Zero);
        for (int col = 0; col < 1152; col++)
        {
            VLE_ALIGN(11, (int*)(p_Opool2 + (col%6+col/6*8)), 8); // pool2 output has two additional zeros every row
            VLE_ALIGN(12, (int*)(p_Wfc1 + col*256 + row), 8); // fc1 weight
            VFC1_VV(11, 12, 11);
            VADD_VV(13, 13, 11);
        }
        VQUAN32(13, 13, 10);
        VRELU_VI(13, 13);
        VSE32(13, (int*)(p_Ofc1 + row));
    }

    // fc2
    int8_t *p_Wfc2 = (int8_t *)ADDR_WFC2;
    int8_t *p_Sfc2 = (int8_t *)ADDR_SFC2;
    int8_t *p_Ofc2 = (int8_t *)ADDR_OUTFC2;

    VLE_ALIGN(10, (int*)p_Sfc2, 8);
    for (int row = 0; row < 64; row+=16)
    {
        VLE32(13, (int*)p_Zero);
        for (int col = 0; col < 256; col++)
        {
            VLE_ALIGN(11, (int*)(p_Ofc1 + col), 8); // fc1 output
            VLE_ALIGN(12, (int*)(p_Wfc2 + col*64 + row), 8); // fc2 weight
            VFC1_VV(11, 12, 11);
            VADD_VV(13, 13, 11);
        }
        VQUAN32(13, 13, 10);
        VRELU_VI(13, 13);
        VSE32(13, (int*)(p_Ofc2 + row));
    }
    
    // fc3
    int8_t *p_Wfc3 = (int8_t *)ADDR_WFC3;
    int8_t *p_Sfc3 = (int8_t *)ADDR_SFC3;
    int8_t *p_Bfc3 = (int8_t *)ADDR_BFC3;
    int8_t *p_Ofc3 = (int8_t *)ADDR_OUTFC3;

    VLE_ALIGN(10, (int*)p_Sfc3, 8);

    VLE32(13, (int*)p_Zero);
    for (int col = 0; col < 64; col++)
    {
        VLE_ALIGN(11, (int*)(p_Ofc2 + col), 8); // fc2 output
        VLE_ALIGN(12, (int*)(p_Wfc3 + col*10), 8); // fc3 weight
        VFC1_VV(11, 12, 11);
        VADD_VV(13, 13, 11);
    }
    VLE_ALIGN(14, (int*)p_Bfc3, 8); // fc3 bias
    VBIAS16_VV(13, 13, 14);
    VQUAN32(13, 13, 10);
    VSE32(13, (int*)(p_Ofc3));
    
    

    // vle32(reg_vx2, (int*)(0x80800c19));
    

    // for (int i=0; i<8; i++) {
    //     int8_t data = *(p_Opool2+i+26);
    //     printf("%x\t",data);
    // }
    // printf("\n");
    // for (int i=0; i<16; i++) {
    //     int8_t data = *(p_Wfc1+i+256*20);
    //     printf("%x\t",data);
    // }
    // printf("\n");

    // printf("\n");

    for (int i=0; i<10; i++) {
        int8_t data = *(p_Ofc3+i);
        printf("%d\t",data);
    }
    printf("\n");

    // printf("[");
    // for (int k = 0; k < 32; k++)
    // {
    //     if (k != 0) printf(" ");
    //     printf("[");
    //     for (int i=0; i<6; i++) {
    //         if (i != 0) printf("  ");
    //         printf("[");
    //         for (int j = 0; j < 8; j++)
    //         {
    //             int8_t data = *(p_Opool2+i*8+j+k*8*6);
    //             printf("%d",data);
    //             if (j != 7) printf(", ");
    //         }
    //         printf("]");
    //         if (i != 5) printf(",\n");
            
    //     }
    //     printf("]");
    //     if (k != 31) printf(",\n\n");
    // }
    // printf("]");
    
    
    
    return 0;
}
