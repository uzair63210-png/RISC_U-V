module cpu (
    input  clk,
    input  rst,
    output [15:0] dbg_alu_out,   
    output [15:0] dbg_pc,       
    output [5:0]  dbg_flags,     
    output        dbg_wr         
);

wire [5:0] flag_in;
wire [15:0] out1, out2, data_out;
wire is_load_ex, stall;
wire [3:0] con;
wire [31:0] instruction, instruction1, instructions, instructions2, pc, pc_brch, pc1, pc2;
wire [31:0] pc_out, pc_brch1;
wire brch, wr_ex, wr, su;
wire [15:0] sp_add, sp_add_, out;
wire return;
wire [15:0] A, B, update_r;
wire [5:0] addr;
wire [5:0] flags;
wire [15:0] rs11, rs12, rs21;
wire [4:0] ars11, ars12, ars13, ars21, ars22, ars23;
wire [4:0] ard1;
wire [5:0] ard2, ard3;
wire use11, use21;
wire [4:0] id_rs1, id_rs2;
wire [15:0] st_rdata;

assign pc_brch = (return) ? pc_out : pc_brch1;
assign flag_in = (return) ? out[5:0] : flags;

IF_stage IF (pc_brch,brch|return,rst,clk,pc,instruction, stall);

ID ID (instruction,pc,clk,rst,brch,pc_brch1,instruction1,sp_add,pc1,ard1,ars11,
ars21,use11,use21,rs11,rs21,flags,wr,addr[4:0],update_r,A,B,con,wr_ex,su,stall,id_rs1,id_rs2,
ard2[4:0],st_rdata);

// EX operand forwarding (incl. acc/r0)
forwarding_unit #(1) fu (ard2,A,ard3,out,addr,update_r,ars11,ars21,
use11,use21,rs11,rs21,out1,out2);
 
// load-use stall
load_use_hazard luh (is_load_ex,ard1,id_rs1,id_rs2,stall);
 
// store data: read regfile at MEM stage + independent forwarding
store_data_fwd sdf (ard2[4:0],st_rdata,ard3,out,addr,update_r,data_out);
    
ex_state EX (instruction1,instructions,clk,rst,sp_add,ard1,ars11,ars21,out1,out2,
flag_in,flags,pc1,pc2,ard2,ars12,ars22,rs12,B,A,sp_add_,con,su,wr_ex,return,is_load_ex);

MEM_state MEM (instructions,pc_out,clk,rst,A,sp_add_,data_out,pc2,flags,instructions2,
ard2,ars12,ars22,ard3,out,return);

WB_state WB (instructions2,clk,rst,ard3,addr,out,wr,update_r);

assign dbg_alu_out = out;          // WB 阶段回写数据，或选 EX 阶段 ALU 结果
assign dbg_pc      = pc[15:0];     // IF 阶段 PC
assign dbg_flags   = flags;        // EX 阶段标志位
assign dbg_wr      = wr;           // WB 写使能

endmodule