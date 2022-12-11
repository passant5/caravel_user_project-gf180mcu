// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example (
`ifdef USE_POWER_PINS
    inout vdd,	// User area 1 5V supply
    inout vss,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [63:0] la_data_in,
    output [63:0] la_data_out,
    input  [63:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq,

    input user_clock2
);
    wire clk, usr_clk2;
    wire rst;

    wire [`MPRJ_IO_PADS*2+99:0] o_q, o_q_dly, const_zero; //1 ack + 32 data + 64 la data + 3 irq + 2*ios out/oeb
    wire [`MPRJ_IO_PADS+198:0] buf_i, buf_i_q; //1 stb + 1 cyc + 1 we + 4 sel + 32 in data + 32 adr + 64 la data + zios in

    // For an input, assume the load is that of a high drive strength buffer
    gf180mcu_fd_sc_mcu7t5v0__clkbuf_8 CLK_BUF[1:0] (
        `ifdef USE_POWER_PINS
			.VDD(vdd),
            .VSS(vss),
		`endif
        .I({wb_clk_i,user_clock2}),
        .Z({clk, usr_clk2})
    );

    gf180mcu_fd_sc_mcu7t5v0__buf_8 i_BUF[`MPRJ_IO_PADS+199:0] (
        `ifdef USE_POWER_PINS
			.VDD(vdd),
            .VSS(vss),
		`endif
        .I({wb_rst_i, wbs_cyc_i, wbs_stb_i, wbs_we_i, wbs_sel_i, io_in, la_data_in, la_oenb, wbs_adr_i, wbs_dat_i}),
        .Z({rst, buf_i})
    );

    gf180mcu_fd_sc_mcu7t5v0__dffq_1 i_FF[`MPRJ_IO_PADS+198:0] (
        `ifdef USE_POWER_PINS
			.VDD(vdd),
            .VSS(vss),
		`endif
        .D(buf_i),
        .CLK(clk),
        .Q(buf_i_q)
    );
    
    // For an output, assume the drive capability is that of a low drive strength buffer 
    gf180mcu_fd_sc_mcu7t5v0__buf_1 o_BUF[`MPRJ_IO_PADS*2+99:0] (
        `ifdef USE_POWER_PINS
			.VDD(vdd),
            .VSS(vss),
		`endif        
        .I({o_q_dly}), 
        .Z({wbs_ack_o, io_oeb, io_out, irq, la_data_out, wbs_dat_o})
    );

    // output transition
    gf180mcu_fd_sc_mcu7t5v0__tiel const_zero[`MPRJ_IO_PADS*2+99:0] (
        `ifdef USE_POWER_PINS
			.VDD(vdd),
            .VSS(vss),
		`endif        
        .ZN(const_zero)
    );

    gf180mcu_fd_sc_mcu7t5v0__dffq_1 o_FF[`MPRJ_IO_PADS*2+99:0] (
        `ifdef USE_POWER_PINS
			.VDD(vdd),
            .VSS(vss),
		`endif        
        .D(const_zero),
        .CLK(clk),
        .Q(o_q)
    );

    gf180mcu_fd_sc_mcu7t5v0__dlyd_1 o_dly[`MPRJ_IO_PADS*2+99:0] (
        `ifdef USE_POWER_PINS
			.VDD(vdd),
            .VSS(vss),
		`endif 
        .I(o_q), 
        .Z(o_q_dly)
    );
endmodule
`default_nettype wire
