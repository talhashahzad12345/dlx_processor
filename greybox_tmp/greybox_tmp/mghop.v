//scfifo ADD_RAM_OUTPUT_REGISTER="ON" CBX_SINGLE_OUTPUT_FILE="ON" INTENDED_DEVICE_FAMILY=""MAX 10"" LPM_NUMWORDS=1024 LPM_SHOWAHEAD="OFF" LPM_TYPE="scfifo" LPM_WIDTH=34 LPM_WIDTHU=10 OVERFLOW_CHECKING="ON" UNDERFLOW_CHECKING="ON" USE_EAB="OFF" clock data empty full q rdreq usedw wrreq
//VERSION_BEGIN 24.1 cbx_mgl 2025:03:05:20:07:01:SC cbx_stratixii 2025:03:05:20:06:36:SC cbx_util_mgl 2025:03:05:20:06:36:SC  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2025  Altera Corporation. All rights reserved.
//  Your use of Altera Corporation's design tools, logic functions 
//  and other software and tools, and any partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Altera Program License 
//  Subscription Agreement, the Altera Quartus Prime License Agreement,
//  the Altera IP License Agreement, or other applicable license
//  agreement, including, without limitation, that your use is for
//  the sole purpose of programming logic devices manufactured by
//  Altera and sold by Altera or its authorized distributors.  Please
//  refer to the Altera Software License Subscription Agreements 
//  on the Quartus Prime software download page.



//synthesis_resources = scfifo 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  mghop
	( 
	clock,
	data,
	empty,
	full,
	q,
	rdreq,
	usedw,
	wrreq) /* synthesis synthesis_clearbox=1 */;
	input   clock;
	input   [33:0]  data;
	output   empty;
	output   full;
	output   [33:0]  q;
	input   rdreq;
	output   [9:0]  usedw;
	input   wrreq;

	wire  wire_mgl_prim1_empty;
	wire  wire_mgl_prim1_full;
	wire  [33:0]   wire_mgl_prim1_q;
	wire  [9:0]   wire_mgl_prim1_usedw;

	scfifo   mgl_prim1
	( 
	.clock(clock),
	.data(data),
	.empty(wire_mgl_prim1_empty),
	.full(wire_mgl_prim1_full),
	.q(wire_mgl_prim1_q),
	.rdreq(rdreq),
	.usedw(wire_mgl_prim1_usedw),
	.wrreq(wrreq));
	defparam
		mgl_prim1.add_ram_output_register = "ON",
		mgl_prim1.intended_device_family = ""MAX 10"",
		mgl_prim1.lpm_numwords = 1024,
		mgl_prim1.lpm_showahead = "OFF",
		mgl_prim1.lpm_type = "scfifo",
		mgl_prim1.lpm_width = 34,
		mgl_prim1.lpm_widthu = 10,
		mgl_prim1.overflow_checking = "ON",
		mgl_prim1.underflow_checking = "ON",
		mgl_prim1.use_eab = "OFF";
	assign
		empty = wire_mgl_prim1_empty,
		full = wire_mgl_prim1_full,
		q = wire_mgl_prim1_q,
		usedw = wire_mgl_prim1_usedw;
endmodule //mghop
//VALID FILE
