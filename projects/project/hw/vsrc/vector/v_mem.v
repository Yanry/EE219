`include "v_defines.v"

module v_mem (
    input                      clk,
    input                      rst,
    
    input                      vmem_ren_i,
    input                      vmem_wen_i,
    input   [`VMEM_ADDR_BUS]   vmem_raddr_i,
    input   [`VMEM_ADDR_BUS]   vmem_waddr_i,
    input   [`VMEM_DATA_BUS]   vmem_din_i,
    output  [`VMEM_DATA_BUS]   vmem_dout_o,

    output                     vram_ren_o,
    output                     vram_wen_o,
    output  [`VRAM_ADDR_BUS]   vram_raddr_o,
    output  [`VRAM_ADDR_BUS]   vram_waddr_o,
    output  [`VRAM_DATA_BUS]   vram_mask_o,
    output  [`VMEM_DATA_BUS]   vram_din_o,
    input   [`VMEM_DATA_BUS]   vram_dout_i
);

assign vram_ren_o   = vmem_ren_i ;
assign vram_wen_o   = vmem_wen_i ;
assign vram_raddr_o  = vmem_raddr_i ;
assign vram_waddr_o  = vmem_waddr_i ;
assign vram_din_o   = vmem_din_i ;
assign vram_mask_o  = {(`VLEN){1'b1}};
assign vmem_dout_o  = vram_dout_i ;

endmodule
