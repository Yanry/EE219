// =======================================
// You need to finish this module
// =======================================

module rvcpu_two_issue #(
    parameter PC_START  = 32'h8000_0000, 
    parameter ISSUE_NUM = 2,
    parameter INST_DW   = 32,
    parameter INST_AW   = 32,
    parameter MEM_DW    = 32,
    parameter MEM_AW    = 32,
    parameter RAM_DW    = 32,
    parameter RAM_AW    = 32,
    parameter REG_DW    = 32,
    parameter REG_AW    = 5,
    parameter ALUOP_DW  = 5,

    parameter SEW       = 32, 
    parameter VLMAX     = 8,
    parameter VALUOP_DW = 5,
    parameter VREG_DW   = 256,
    parameter VREG_AW   = 5,
    parameter VMEM_DW   = 256,
    parameter VMEM_AW   = 32,
    parameter VRAM_DW   = 256,
    parameter VRAM_AW   = 32
)(
    input                           clk,
    input                           rst,

    output                          inst_en_o,
    output  [INST_AW-1:0]           inst_addr_o,
    input   [INST_DW*ISSUE_NUM-1:0] inst_i,

    output                          ram_ren_o,
    output                          ram_wen_o,
    output  [RAM_AW-1:0]            ram_addr_o,
    output  [RAM_DW-1:0]            ram_mask_o,
    output  [RAM_DW-1:0]            ram_din_o,
    input   [RAM_DW-1:0]            ram_dout_i,

    output                          vram_ren_o,
    output                          vram_wen_o,
    output  [VRAM_AW-1:0]           vram_addr_o,
    output  [VRAM_DW-1:0]           vram_mask_o,
    output  [VRAM_DW-1:0]           vram_din_o,
    input   [VRAM_DW-1:0]           vram_dout_i
);


// =================================================
//                  Scalar
// =================================================
wire    [INST_DW*ISSUE_NUM-1:0]   inst  ;
wire    [INST_DW-1:0]   inst_is1        ;
wire    [INST_DW-1:0]   inst_is2        ;

wire    [ALUOP_DW-1:0]  is1_alu_opcode      ;
wire    [REG_DW-1:0]    is1_operand_1       ;
wire    [REG_DW-1:0]    is1_operand_2       ;
wire                    is1_branch_en       ;
wire    [INST_AW-1:0]   is1_branch_offset   ;
wire                    is1_jump_en         ;
wire    [INST_AW-1:0]   is1_jump_offset     ;
wire                    is1_mem_ren         ;
wire                    is1_mem_wen         ;
wire                    is1_id_wb_en        ;
wire                    is1_id_wb_sel       ;
wire    [REG_AW-1:0]    is1_id_wb_addr      ;

wire                    is1_control_en      ;
wire    [INST_AW-1:0]   is1_control_pc      ;
wire    [INST_AW-1:0]   is1_current_pc      ;
wire    [REG_DW-1:0]    is1_alu_result      ;

wire    [MEM_AW-1:0]    is1_mem_addr        ;
wire    [MEM_DW-1:0]    is1_mem_dout        ;
wire    [MEM_DW-1:0]    is1_mem_din         ;

wire                    is1_wb_en           ;
wire    [REG_AW-1:0]    is1_wb_addr         ;
wire    [REG_DW-1:0]    is1_wb_data         ;
wire                    is1_rs1_en          ;
wire    [REG_AW-1:0]    is1_rs1_addr        ;
wire    [REG_DW-1:0]    is1_rs1_data        ;
wire                    is1_rs2_en          ;
wire    [REG_AW-1:0]    is1_rs2_addr        ;
wire    [REG_DW-1:0]    is1_rs2_data        ;

mi_inst_fetch #(
    .PC_START       ( PC_START      ),
    .ISSUE_NUM      ( ISSUE_NUM     ),
    .INST_DW        ( INST_DW       ),
    .INST_AW        ( INST_AW       )
) SI_IF (
    .clk            ( clk           ),
    .rst            ( rst           ),
    .control_en_i   ( is1_control_en    ),
    .control_pc_i   ( is1_control_pc    ),
    .current_pc_o   ( is1_current_pc    ),
    .inst_en_o      ( inst_en_o     ),
    .inst_addr_o    ( inst_addr_o   ),
    .inst_i         ( inst_i        ),
    .inst_o         ( inst          )
);
assign inst_is1 = inst[INST_DW-1:0];
assign inst_is2 = inst[INST_DW*ISSUE_NUM-1:INST_DW];

always @(posedge clk) begin
    if (inst_is1 == 32'h0000006b ) begin
        $finish;
    end
end

si_inst_decode #(
    .INST_DW        ( INST_DW       ),
    .INST_AW        ( INST_AW       ),
    .MEM_AW         ( MEM_AW        ),
    .REG_DW         ( REG_DW        ),
    .REG_AW         ( REG_AW        ),
    .ALUOP_DW       ( ALUOP_DW      )
) SI_ID (
    .clk            ( clk           ),
    .rst            ( rst           ),
    .inst_i         ( inst_is1      ),
    .rs1_en_o       ( is1_rs1_en        ),
    .rs1_addr_o     ( is1_rs1_addr      ),
    .rs1_dout_i     ( is1_rs1_data      ),
    .rs2_en_o       ( is1_rs2_en        ),
    .rs2_addr_o     ( is1_rs2_addr      ),
    .rs2_dout_i     ( is1_rs2_data      ),
    .alu_opcode_o   ( is1_alu_opcode    ),
    .operand_1_o    ( is1_operand_1     ),
    .operand_2_o    ( is1_operand_2     ),
    .branch_en_o    ( is1_branch_en     ),
    .branch_offset_o( is1_branch_offset ),
    .jump_en_o      ( is1_jump_en       ),
    .jump_offset_o  ( is1_jump_offset   ),
    .mem_ren_o      ( is1_mem_ren       ),
    .mem_wen_o      ( is1_mem_wen       ),
    .mem_din_o      ( is1_mem_din       ),
    .id_wb_en_o     ( is1_id_wb_en      ),
    .id_wb_sel_o    ( is1_id_wb_sel     ),
    .id_wb_addr_o   ( is1_id_wb_addr    )
);

si_alu #(
    .PC_START       ( PC_START      ),
    .INST_DW        ( INST_DW       ),
    .INST_AW        ( INST_AW       ),
    .REG_DW         ( REG_DW        ),
    .ALUOP_DW       ( ALUOP_DW      )
) SI_ALU (
    .clk            ( clk           ),
    .rst            ( rst           ),
    .alu_opcode_i   ( is1_alu_opcode    ),
    .operand_1_i    ( is1_operand_1     ),
    .operand_2_i    ( is1_operand_2     ),
    .alu_result_o   ( is1_alu_result    ),
    .current_pc_i   ( is1_current_pc    ),
    .branch_en_i    ( is1_branch_en     ),
    .branch_offset_i( is1_branch_offset ),
    .jump_en_i      ( is1_jump_en       ),
    .jump_offset_i  ( is1_jump_offset   ),
    .control_en_o   ( is1_control_en    ),
    .control_pc_o   ( is1_control_pc    )
);

assign is1_mem_addr = is1_alu_result ;

si_mem_access #(
    .MEM_DW         ( MEM_DW        ),
    .MEM_AW         ( MEM_AW        ),
    .RAM_DW         ( RAM_DW        ),
    .RAM_AW         ( RAM_AW        )
) SI_MEM (
    .clk            ( clk           ),
    .rst            ( rst           ),
    .mem_ren_i      ( is1_mem_ren       ),
    .mem_wen_i      ( is1_mem_wen       ),
    .mem_addr_i     ( is1_mem_addr      ),
    .mem_din_i      ( is1_mem_din       ),
    .mem_dout_o     ( is1_mem_dout      ),
    .ram_ren_o      ( ram_ren_o     ),
    .ram_wen_o      ( ram_wen_o     ),
    .ram_addr_o     ( ram_addr_o    ),
    .ram_mask_o     ( ram_mask_o    ),
    .ram_din_o      ( ram_din_o     ),
    .ram_dout_i     ( ram_dout_i    )
);

si_write_back #(
    .REG_DW         ( REG_DW        ),
    .REG_AW         ( REG_AW        )
) SI_WB (
    .clk            ( clk           ),
    .rst            ( rst           ),
    .id_wb_en_i     ( is1_id_wb_en      ),
    .id_wb_addr_i   ( is1_id_wb_addr    ),
    .id_wb_sel_i    ( is1_id_wb_sel     ),
    .alu_result_i   ( is1_alu_result    ),
    .mem_result_i   ( is1_mem_dout      ),
    .wb_en_o        ( is1_wb_en         ),
    .wb_addr_o      ( is1_wb_addr       ),
    .wb_data_o      ( is1_wb_data       )
);

// =================================================
//                     Vector
// =================================================
wire    [VALUOP_DW-1:0] is2_alu_opcode      ;
wire    [VREG_DW-1:0]   is2_operand_1       ;
wire    [VREG_DW-1:0]   is2_operand_2       ;
wire                    is2_mem_ren         ;
wire                    is2_mem_wen         ;
wire                    is2_id_wb_en        ;
wire                    is2_id_wb_sel       ;
wire    [VREG_AW-1:0]   is2_id_wb_addr      ;
wire    [VREG_DW-1:0]   is2_alu_result      ;

wire    [VMEM_AW-1:0]   is2_mem_addr       ;
wire    [VMEM_DW-1:0]   is2_mem_dout       ;
wire    [VMEM_DW-1:0]   is2_mem_din        ;

wire                    is2_wb_en           ;
wire    [VREG_AW-1:0]   is2_wb_addr         ;
wire    [VREG_DW-1:0]   is2_wb_data         ;
wire                    is2_rs1_en          ;
wire    [REG_AW-1:0]    is2_rs1_addr        ;
wire    [REG_DW-1:0]    is2_rs1_data        ;
wire                    is2_vs1_en          ;
wire    [VREG_AW-1:0]   is2_vs1_addr        ;
wire    [VREG_DW-1:0]   is2_vs1_data        ;
wire                    is2_vs2_en          ;
wire    [VREG_AW-1:0]   is2_vs2_addr        ;
wire    [VREG_DW-1:0]   is2_vs2_data        ;

v_id #(
    .INST_DW        ( INST_DW        ),
    .VLMAX          ( VLMAX          ),
    .VMEM_DW        ( VMEM_DW        ),
    .VMEM_AW        ( VMEM_AW        ),
    .VREG_DW        ( VREG_DW        ),
    .VREG_AW        ( VREG_AW        ),
    .VALUOP_DW      ( VALUOP_DW      ),
    .REG_DW         ( REG_DW         ),
    .REG_AW         ( REG_AW         )
) V_ID (
    .clk            ( clk           ),
    .rst            ( rst           ),
    .inst_i         ( inst_is2      ),
    .rs1_en_o       ( is2_rs1_en        ),
    .rs1_addr_o     ( is2_rs1_addr      ),
    .rs1_dout_i     ( is2_rs1_data      ),
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
    .vmem_addr_o    ( is2_mem_addr      ),
    .vmem_din_o     ( is2_mem_din       ),
    .vid_wb_en_o    ( is2_id_wb_en      ),
    .vid_wb_sel_o   ( is2_id_wb_sel     ),
    .vid_wb_addr_o  ( is2_id_wb_addr    )
);

v_alu #(
    .SEW             ( SEW            ),
    .VLMAX           ( VLMAX          ),
    .VREG_DW         ( VREG_DW        ),
    .VREG_AW         ( VREG_AW        ),
    .VALUOP_DW       ( VALUOP_DW      )
) V_ALU (
    .clk             ( clk               ),
    .rst             ( rst               ),
    .valu_opcode_i   ( is2_alu_opcode    ),
    .operand_v1_i    ( is2_operand_1     ),
    .operand_v2_i    ( is2_operand_2     ),
    .valu_result_o   ( is2_alu_result    )
);

v_mem_access #(
    .VMEM_DW         ( VMEM_DW        ),
    .VMEM_AW         ( VMEM_AW        ),
    .VRAM_DW         ( VRAM_DW        ),
    .VRAM_AW         ( VRAM_AW        )
) V_MEM (
    .clk             ( clk           ),
    .rst             ( rst           ),
    .vmem_ren_i      ( is2_mem_ren       ),
    .vmem_wen_i      ( is2_mem_wen       ),
    .vmem_addr_i     ( is2_mem_addr      ),
    .vmem_din_i      ( is2_mem_din       ),
    .vmem_dout_o     ( is2_mem_dout      ),
    .vram_ren_o      ( vram_ren_o     ),
    .vram_wen_o      ( vram_wen_o     ),
    .vram_addr_o     ( vram_addr_o    ),
    .vram_mask_o     ( vram_mask_o    ),
    .vram_din_o      ( vram_din_o     ),
    .vram_dout_i     ( vram_dout_i    )
);

v_wb #(
    .VREG_DW         ( VREG_DW        ),
    .VREG_AW         ( VREG_AW        )
) V_WB (
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

v_regfile #(
    .VREG_DW         ( VREG_DW        ),
    .VREG_AW         ( VREG_AW        )
) V_REG (
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

mi2_regfile #(
    .REG_DW         ( REG_DW        ),
    .REG_AW         ( REG_AW        )
) MI2_REG (
    .clk            ( clk           ),
    .rst            ( rst           ),
    .is1_wb_en_i       ( is1_wb_en         ),
    .is1_wb_addr_i     ( is1_wb_addr       ),
    .is1_wb_data_i     ( is1_wb_data       ),
    .is1_rs1_en_i       ( is1_rs1_en        ),
    .is1_rs1_addr_i     ( is1_rs1_addr      ),
    .is1_rs1_data_o     ( is1_rs1_data      ),
    .is1_rs2_en_i       ( is1_rs2_en        ),
    .is1_rs2_addr_i     ( is1_rs2_addr      ),
    .is1_rs2_data_o     ( is1_rs2_data      ),
    .is2_rs1_en_i       ( is2_rs1_en        ),
    .is2_rs1_addr_i     ( is2_rs1_addr      ),
    .is2_rs1_data_o     ( is2_rs1_data      )
);


endmodule 
