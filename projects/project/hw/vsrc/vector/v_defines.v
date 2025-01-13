`define VLEN            512
`define SEW             64
`define LMUL            1
`define VLMAX           (`VLEN/`SEW) * `LMUL

`define VINST_BUS       31:0
`define SREG_BUS        63:0
`define SREG_ADDR_BUS   4:0

`define VREG_WIDTH      `VLEN
`define VREG_BUS        `VLEN-1 : 0
`define VREG_ADDR_BUS   4  : 0

`define VMEM_ADDR_BUS   63 : 0
`define VMEM_DATA_BUS   `VLEN-1 : 0

`define VRAM_ADDR_BUS   63 : 0
`define VRAM_DATA_BUS   `VLEN-1 : 0

`define ALU_OP_BUS      7  : 0

// -------------------------------------------------
// RISC-32V Instruction OPCODE
// -------------------------------------------------
`define OPCODE_VL       7'b000_0111 
`define WIDTH_VLE32     3'b110
`define FUNCT6_VLE32    6'b00_0000

`define OPCODE_VS       7'b010_0111
`define WIDTH_VSE32     3'b110
`define FUNCT6_VSE32    6'b00_0000

`define OPCODE_VEC      7'b101_0111 
`define FUNCT3_IVV      3'b000 
`define FUNCT3_IVI      3'b011 
`define FUNCT3_IVX      3'b100 

`define FUNCT6_VADD     6'b00_0000 
`define FUNCT6_VMUL     6'b10_0101 
`define FUNCT6_CONV1    6'b00_0001
`define FUNCT6_POOL1    6'b00_0010
`define FUNCT6_CONV2    6'b00_0011
`define FUNCT6_POOL2    6'b00_0100
`define FUNCT6_FC1      6'b00_0101

`define FUNCT6_RSI      6'b10_1000
`define FUNCT6_QUAN32   6'b10_1001
`define FUNCT6_CAT14    6'b10_1010
`define FUNCT6_RELU     6'b10_1011
`define FUNCT6_BIAS16   6'b10_1100

`define VALU_OP_NOP     8'b1000_0000
`define VALU_OP_ADD     8'b1000_0001
`define VALU_OP_MUL     8'b1000_0010
`define VALU_OP_CONV1   8'b1000_0011
`define VALU_OP_POOL1   8'b1000_0100
`define VALU_OP_CONV2   8'b1000_0101
`define VALU_OP_POOL2   8'b1000_0110
`define VALU_OP_FC1     8'b1000_0111

`define VALU_OP_RSI     8'b1100_0000
`define VALU_OP_QUAN32  8'b1100_0001
`define VALU_OP_CAT14   8'b1100_0010
`define VALU_OP_RELU    8'b1100_0011
`define VALU_OP_BIAS16  8'b1100_0100