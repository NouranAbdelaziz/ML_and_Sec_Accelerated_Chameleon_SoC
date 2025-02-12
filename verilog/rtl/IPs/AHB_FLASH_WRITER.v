
/*

	Copyright 2020 Mohamed Shalan
	
	Licensed under the Apache License, Version 2.0 (the "License"); 
	you may not use this file except in compliance with the License. 
	You may obtain a copy of the License at:

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software 
	distributed under the License is distributed on an "AS IS" BASIS, 
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
	See the License for the specific language governing permissions and 
	limitations under the License.
*/

`timescale              1ns/1ps
`default_nettype        none

//`include                "./include/ahb_util.vh"
`define AHB_REG(name, size, offset, init, prefix)   \
        reg [size-1:0] name; \
        wire ``name``_sel = wr_enable & (last_HADDR[7:0] == offset); \
        always @(posedge HCLK or negedge HRESETn) \
            if (~HRESETn) \
                ``name`` <= 'h``init``; \
            else if (``name``_sel) \
                ``name`` <= ``prefix``HWDATA[``size``-1:0];\

`define AHB_SLAVE_IFC(prefix)   \
        input               ``prefix``HSEL,\
        input wire [31:0]   ``prefix``HADDR,\
        input wire [1:0]    ``prefix``HTRANS,\
        input wire          ``prefix``HWRITE,\
        input wire          ``prefix``HREADY,\
        input wire [31:0]   ``prefix``HWDATA,\
        input wire [2:0]    ``prefix``HSIZE,\
        output wire         ``prefix``HREADYOUT,\
        output wire [31:0]  ``prefix``HRDATA
        

`define AHB_SLAVE_RO_IFC(prefix)   \
        input               ``prefix``HSEL,\
        input wire [31:0]   ``prefix``HADDR,\
        input wire [1:0]    ``prefix``HTRANS,\
        input wire          ``prefix``HWRITE,\
        input wire          ``prefix``HREADY,\
        output wire         ``prefix``HREADYOUT,\
        output wire [31:0]  ``prefix``HRDATA

`define AHB_MASTER_IFC(prefix) \
        output wire [31:0]  ``prefix``HADDR,\
        output wire [1:0]   ``prefix``HTRANS,\
        output wire [2:0] 	 ``prefix``HSIZE,\
        output wire         ``prefix``HWRITE,\
        output wire [31:0]  ``prefix``HWDATA,\
        input wire          ``prefix``HREADY,\
        input wire [31:0]   ``prefix``HRDATA 
        

`define AHB_SLAVE_EPILOGUE(prefix) \
    reg             last_HSEL; \
    reg [31:0]      last_HADDR; \
    reg             last_HWRITE; \
    reg [1:0]       last_HTRANS; \
    \
    always@ (posedge HCLK) begin\
        if(``prefix``HREADY) begin\
            last_HSEL       <= ``prefix``HSEL;   \
            last_HADDR      <= ``prefix``HADDR;  \
            last_HWRITE     <= ``prefix``HWRITE; \
            last_HTRANS     <= ``prefix``HTRANS; \
        end\
    end\
    \
    wire rd_enable = last_HSEL & (~last_HWRITE) & last_HTRANS[1]; \
    wire wr_enable = last_HSEL & (last_HWRITE) & last_HTRANS[1]; 


`define REG_FIELD(reg_name, fld_name, from, to)\
    wire [``to``-``from``:0] ``reg_name``_``fld_name`` = reg_name[to:from]; 

`define AHB_READ assign HRDATA = 

`define AHB_REG_READ(name, offset) (last_HADDR[7:0] == offset) ? name : 

/*
module TEST(
    input wire HCLK,
    input wire HRESETn,

    `AHB_SLAVE_IFC(S0_),
    `AHB_MASTER_IFC(M0_)
);

    `AHB_SLAVE_EPILOGUE(S0_)

    `AHB_REG(XXX, 20, 8'h20, 0, S0_)

    `REG_FIELD(XXX, xxx, 2, 15)

    `AHB_READ
        `AHB_REG_READ(XXX, 8'h20)
        32'hDEADBEEF;

endmodule
*/

/*
    A bit bangging flash writer with AHB slave interface
    Registers:
        00: Write Enable
        04: SSn control
        08: SCK control
        0C: OE control
        10: SO data out (write, 4 bits)
        14: SI data in (read, 4bits)
*/

module AHB_FLASH_WRITER (
    input               HCLK,
    input               HRESETn,
    
    // AHB-Lite Slave Interface
    `AHB_SLAVE_IFC(),
    
    // FLASH Interface from the FR
    input  wire         fr_sck,
    inout  wire         fr_ce_n,
    output wire [3:0]   fr_din,
    input  wire [3:0]   fr_dout,
    input  wire         fr_douten,

    // FLASH Interface
    output  wire        fm_sck,
    output  wire        fm_ce_n,
    input   wire [3:0]  fm_din,
    output  wire [3:0]  fm_dout,
    output  wire [3:0]  fm_douten
);

    localparam  WE_REG_OFF  = 8'h00, 
                SS_REG_OFF  = 8'h04,
                SCK_REG_OFF = 8'h08,
                OE_REG_OFF  = 8'h0c,
                SO_REG_OFF  = 8'h10,
                SI_REG_OFF  = 8'h14,
                ID_REG_OFF  = 8'h18;
                
                
    `AHB_SLAVE_EPILOGUE()

    reg             WE_REG;
    wire WE_REG_sel = wr_enable & (last_HADDR[7:0] == WE_REG_OFF);
    always @(posedge HCLK or negedge HRESETn)
    begin
        if (~HRESETn)
            WE_REG <= 1'h0;
        else if (WE_REG_sel & (HWDATA[31:8] == 24'hA5A855))
            WE_REG <= HWDATA[0];
    end

    `AHB_REG(SS_REG, 1, SS_REG_OFF, 1, )  
    `AHB_REG(SCK_REG, 1, SCK_REG_OFF, 0, )
    `AHB_REG(OE_REG, 4, OE_REG_OFF, 0, )  
    `AHB_REG(SO_REG, 4, SO_REG_OFF, 0, )
    
    assign HRDATA = (last_HADDR == SI_REG_OFF) & rd_enable ? {28'h0, fm_din} : 
                    (last_HADDR == ID_REG_OFF) & rd_enable ? {32'hABCD0001} : 
                    32'h0; 

    assign  fm_sck      =   WE_REG  ?   SCK_REG :   fr_sck;
    assign  fm_ce_n     =   WE_REG  ?   SS_REG  :   fr_ce_n;
    assign  fm_douten   =   WE_REG  ?   OE_REG  :   {4{fr_douten}};
    assign  fm_dout     =   WE_REG  ?   SO_REG  :   fr_dout;

    assign fr_din       =   fm_din;

    //assign HREADY = 1;
    assign HREADYOUT = 1'b1;

endmodule
