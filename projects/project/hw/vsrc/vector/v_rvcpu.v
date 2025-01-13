`include "v_defines.v"

module v_rvcpu(
    input                       clk,
    input                       rst,
    input   [`VINST_BUS]        inst ,

    input   [`SREG_BUS]         vec_rs1_data,
	output            	        vec_rs1_r_ena,
	output  [`SREG_ADDR_BUS]   	vec_rs1_r_addr,

    output                      vram_r_ena,
    output  [`VRAM_ADDR_BUS]    vram_r_addr,
    input   [`VRAM_DATA_BUS]    vram_r_data,

    output                      vram_w_ena,
    output  [`VRAM_ADDR_BUS]    vram_w_addr,
    output  [`VRAM_DATA_BUS]    vram_w_data,
    output  [`VRAM_DATA_BUS]    vram_w_mask
);

// =================================================
//                     Vector
// =================================================
wire    [`ALU_OP_BUS]      is2_alu_opcode      ;
wire    [`VREG_BUS]        is2_operand_1       ;
wire    [`VREG_BUS]        is2_operand_2       ;
wire                       is2_mem_ren         ;
wire                       is2_mem_wen         ;
wire                       is2_id_wb_en        ;
wire                       is2_id_wb_sel       ;
wire    [`VREG_ADDR_BUS]   is2_id_wb_addr      ;
wire    [`VREG_BUS]        is2_alu_result      ;

wire    [`VMEM_ADDR_BUS]   is2_mem_raddr      ;
wire    [`VMEM_ADDR_BUS]   is2_mem_waddr      ;
wire    [`VMEM_DATA_BUS]   is2_mem_dout       ;
wire    [`VMEM_DATA_BUS]   is2_mem_din        ;

wire                       is2_wb_en           ;
wire    [`VREG_ADDR_BUS]   is2_wb_addr         ;
wire    [`VREG_BUS]        is2_wb_data         ;
wire                       is2_rs1_en          ;
wire    [`VREG_ADDR_BUS]   is2_rs1_addr        ;
wire    [`VREG_BUS]        is2_rs1_data        ;
wire                       is2_vs1_en          ;
wire    [`VREG_ADDR_BUS]   is2_vs1_addr        ;
wire    [`VREG_BUS]        is2_vs1_data        ;
wire                       is2_vs2_en          ;
wire    [`VREG_ADDR_BUS]   is2_vs2_addr        ;
wire    [`VREG_BUS]        is2_vs2_data        ;

v_inst_decode V_ID (
    .clk            ( clk           ),
    .rst            ( rst           ),
    .inst_i         ( inst          ),
    .rs1_en_o       ( vec_rs1_r_ena     ),
    .rs1_addr_o     ( vec_rs1_r_addr    ),
    .rs1_dout_i     ( vec_rs1_data      ),
    .vs1_en_o       ( is2_vs1_en        ),
    .vs1_addr_o     ( is2_vs1_addr      ),
    .vs1_dout_i     ( is2_vs1_data      ),
    .vs2_en_o       ( is2_vs2_en        ),
    .vs2_addr_o     ( is2_vs2_addr      ),
    .vs2_dout_i     ( is2_vs2_data      ),
    .valu_opcode_o  ( is2_alu_opcode    ),
    .operand_v1_o   ( is2_operand_1     ),
    .operand_v2_o   ( is2_operand_2     ),

    .vmem_ren_o     ( is2_mem_ren       ),
    .vmem_wen_o     ( is2_mem_wen       ),
    .vmem_raddr_o   ( is2_mem_raddr     ),
    .vmem_waddr_o   ( is2_mem_waddr     ),
    .vmem_din_o     ( is2_mem_din       ),
    .vid_wb_en_o    ( is2_id_wb_en      ),
    .vid_wb_sel_o   ( is2_id_wb_sel     ),
    .vid_wb_addr_o  ( is2_id_wb_addr    )
);

v_execute V_ALU (
    .clk             ( clk               ),
    .rst             ( rst               ),
    .valu_opcode_i   ( is2_alu_opcode    ),
    .operand_v1_i    ( is2_operand_1     ),
    .operand_v2_i    ( is2_operand_2     ),
    .valu_result_o   ( is2_alu_result    )
);

v_mem V_MEM (
    .clk             ( clk           ),
    .rst             ( rst           ),
    .vmem_ren_i      ( is2_mem_ren       ),
    .vmem_wen_i      ( is2_mem_wen       ),
    .vmem_raddr_i    ( is2_mem_raddr     ),
    .vmem_waddr_i    ( is2_mem_waddr     ),
    .vmem_din_i      ( is2_mem_din       ),
    .vmem_dout_o     ( is2_mem_dout      ),
    .vram_ren_o      ( vram_r_ena     ),
    .vram_wen_o      ( vram_w_ena     ),
    .vram_raddr_o    ( vram_r_addr    ),
    .vram_waddr_o    ( vram_w_addr    ),
    .vram_mask_o     ( vram_w_mask    ),
    .vram_din_o      ( vram_w_data    ),
    .vram_dout_i     ( vram_r_data    )
);

v_write_back V_WB (
    .clk             ( clk           ),
    .rst             ( rst           ),
    .vid_wb_en_i     ( is2_id_wb_en      ),
    .vid_wb_addr_i   ( is2_id_wb_addr    ),
    .vid_wb_sel_i    ( is2_id_wb_sel     ),
    .valu_result_i   ( is2_alu_result    ),
    .vmem_result_i   ( is2_mem_dout      ),
    .vwb_en_o        ( is2_wb_en         ),
    .vwb_addr_o      ( is2_wb_addr       ),
    .vwb_data_o      ( is2_wb_data       )
);

v_regfile V_REG (
    .clk            ( clk           ),
    .rst            ( rst           ),
    .vwb_en_i       ( is2_wb_en         ),
    .vwb_addr_i     ( is2_wb_addr       ),
    .vwb_data_i     ( is2_wb_data       ),
    .vs1_en_i       ( is2_vs1_en        ),
    .vs1_addr_i     ( is2_vs1_addr      ),
    .vs1_data_o     ( is2_vs1_data      ),
    .vs2_en_i       ( is2_vs2_en        ),
    .vs2_addr_i     ( is2_vs2_addr      ),
    .vs2_data_o     ( is2_vs2_data      )
);
endmodule
