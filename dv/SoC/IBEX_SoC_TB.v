`define NO_HC_CACHE
`define NO_HC_REGF

//`define FETCH_FROM_ROM
`define ICARUS_VERILOG
//`define USE_RESET_BTN
`define FETCH_FROM_FLASH



`timescale 1ns/1ns

`define CLK_PERIOD 83.3333333


`ifdef ICARUS_VERILOG
    `define   TEST_FILE   "../../sw/test.hex" 
    `define   SIM_TIME    1000_0000
    `define   SIM_LEVEL   0

    //`include "rtl_fpga/n5_netlists.v"
    //`include "sst26wf080b.v"
    //`include "23LC512.v" 
    //`include "M24LC16B.v"
`else
    `define   TEST_FILE   "test.mem" 
`endif

`ifdef USE_RESET_BTN
    `define RESET_DELAY  80000000
    `define RESET_VAL    1     // when button is pressed
`else
    `define RESET_DELAY 800
    `define RESET_VAL   0
`endif

module IBEX_SoC_TB;

localparam  WE_OFF = 32'h4C000000,
                SS_OFF = 32'h4C000004,
                SCK_OFF= 32'h4C000008,
                OE_OFF = 32'h4C00000C,
                SO_OFF = 32'h4C000010,
                SI_OFF = 32'h4C000014,
                ID_OFF = 32'h4C000018; 

    reg HCLK, HRESETn;
    reg  TX; 
    wire RX;
    
    wire [3:0]		fdi;
    wire [3:0]    	fdo;
    wire [3:0]      fdio;
    wire     	    fdoe;
    wire          	fsclk;
    wire          	fcen;

    wire [15: 0] GPIO_Sys0_S2;

    wire [0: 0] RsRx_Sys0_SS0_S0;
    wire [0: 0] RsTx_Sys0_SS0_S0;
    
    wire [0: 0] RsRx_Sys0_SS0_S1;
    wire [0: 0] RsTx_Sys0_SS0_S1;

    wire [0: 0] MSI_Sys0_SS0_S2;
    wire [0: 0] MSO_Sys0_SS0_S2;
    wire [0: 0] SSn_Sys0_SS0_S2;
    wire [0: 0] SCLK_Sys0_SS0_S2;

    wire [0: 0] MSI_Sys0_SS0_S3;
    wire [0: 0] MSO_Sys0_SS0_S3;
    wire [0: 0] SSn_Sys0_SS0_S3;
    wire [0: 0] SCLK_Sys0_SS0_S3;

    wire [0: 0] scl_Sys0_SS0_S4;
    wire [0: 0] sda_Sys0_SS0_S4;

    wire [0: 0] scl_Sys0_SS0_S5;
    wire [0: 0] sda_Sys0_SS0_S5;

    wire [0: 0] pwm_Sys0_SS0_S6;
	wire [0: 0] pwm_Sys0_SS0_S7;

    // I2C E2PROM connected to I2C0
    wire    scl, sda;
    
    /*wire        fm_ce_n,fm_sck;
            wire [3:0]  SIO; 
            wire [3:0]  fm_din, fm_dout,fm_douten;*/
           
    `ifdef FETCH_FROM_FLASH
        // Program Flash 
        sst26wf080b flash(
            .SCK(fsclk),
            .SIO(fdio),
            .CEb(fcen)
        );
    `endif

    /* N5_SoC Core */
    soc MUV (
    `ifdef USE_POWER_PINS
        .VPWR(1'b1),
        .VGND(1'b0),
    `endif
        .HCLK(HCLK),
        .HRESETn(HRESETn),

        // .SYSTICKCLKDIV(8'd100),
        // .NMI(1'b0),
        .UART_MASTER_RX(TX),
        .UART_MASTER_TX(RX),
        
        .fd_Sys0_S0(fdio),
        .fsclk_Sys0_S0(fsclk),
        .fcen_Sys0_S0(fcen),
        
        /*.fdi_Sys0_S0(fm_din),
        .fdo_Sys0_S0(fm_dout),
        .fdoe_Sys0_S0(fm_douten),
        .fsclk_Sys0_S0(fm_sck),
        .fcen_Sys0_S0(fm_ce_n),*/


        .GPIO_Sys0_S2(GPIO_Sys0_S2),
    	
        .RsRx_Sys0_SS0_S0(RsRx_Sys0_SS0_S0),
        .RsTx_Sys0_SS0_S0(RsTx_Sys0_SS0_S0),

        .RsRx_Sys0_SS0_S1(RsRx_Sys0_SS0_S1),
        .RsTx_Sys0_SS0_S1(RsTx_Sys0_SS0_S1),
       
        .MSI_Sys0_SS0_S2(MSI_Sys0_SS0_S2),
        .MSO_Sys0_SS0_S2(MSO_Sys0_SS0_S2),
        .SSn_Sys0_SS0_S2(SSn_Sys0_SS0_S2),
        .SCLK_Sys0_SS0_S2(SCLK_Sys0_SS0_S2),

        .MSI_Sys0_SS0_S3(MSI_Sys0_SS0_S3),
        .MSO_Sys0_SS0_S3(MSO_Sys0_SS0_S3),
        .SSn_Sys0_SS0_S3(SSn_Sys0_SS0_S3),
        .SCLK_Sys0_SS0_S3(SCLK_Sys0_SS0_S3),

        .scl_Sys0_SS0_S4(scl),
        .sda_Sys0_SS0_S4(sda),
    
        .scl_Sys0_SS0_S5(scl_Sys0_SS0_S5),
        .sda_Sys0_SS0_S5(sda_Sys0_SS0_S5),
    
        .pwm_Sys0_SS0_S6(pwm_Sys0_SS0_S6),
	    .pwm_Sys0_SS0_S7(pwm_Sys0_SS0_S7)

    );
    
        /* Program Flash */

        
           
         /*    assign SIO[0] = fm_douten[0] ? fm_dout[0] : 1'bz;
               assign SIO[1] = fm_douten[1] ? fm_dout[1] : 1'bz;
               assign SIO[2] = fm_douten[2] ? fm_dout[2] : 1'bz;
               assign SIO[3] = fm_douten[3] ? fm_dout[3] : 1'bz;
               
        assign fm_din = SIO;
               
        sst26wf080b flash (.SCK(fm_sck),.SIO(SIO),.CEb(fm_ce_n));*/
        
    // GPIO Loopback!
    wire [15:0] GPIO_PINS;

    assign GPIO_PINS[15:8] = GPIO_Sys0_S2[7:0];
    assign GPIO_Sys0_S2  = GPIO_PINS;

    // Serial Terminal connected to UART0 TX*/
    terminal term(.rx(RsTx_Sys0_SS0_S0));

    // SPI SRAM connected to SPI0
    wire SPI_HOLD = 1'b1;
    M23LC512 SPI_SRAM(
        .RESET(~HRESETn),
        .SO_SIO1(MSI_Sys0_SS0_S2),
        .SI_SIO0(MSO_Sys0_SS0_S2),
        .CS_N(SSn_Sys0_SS0_S2),
        .SCK(SCLK_Sys0_SS0_S2),
        .HOLD_N_SIO3(SPI_HOLD)
	);

	pullup p1(scl); // pullup scl line
	pullup p2(sda); // pullup sda line

   /* M24LC16B I2C_E2PROM(
        .A0(1'b0), 
        .A1(1'b0), 
        .A2(1'b0), 
        .WP(1'b0), 
        .SDA(sda), 
        .SCL(scl), 
        .RESET(~HRESETn)
    );*/

    `ifdef FETCH_FROM_FLASH 
        // Load the application into the flash memory
        initial begin
            #1  $readmemh(`TEST_FILE, flash.I0.memory);
            $display("---------N5 Flash -----------");
            $display("Memory[0]: %0d, Memory[1]: %0d, Memory[2]: %0d, Memory[3]: %0d", 
                flash.I0.memory[0], flash.I0.memory[1], flash.I0.memory[2], flash.I0.memory[3]);
        end
    `endif
    
    // Clock and Rest Generation
    /*initial begin
        //Inputs initialization
        HCLK = 0;
        HRESETn = 1'bx;        
        #50;
        HRESETn = `RESET_VAL;
        #(`RESET_DELAY)
        @(posedge HCLK);
        HRESETn <= ~(`RESET_VAL);
    end

    always #(`CLK_PERIOD / 2.00) HCLK = ~ HCLK;*/
    
    // Clock and Rest Generation
    initial begin
        //Inputs initialization
        HCLK = 0;
        HRESETn = 1'bx;        
        #50;
        HRESETn = 0;
        #100;
        @(posedge HCLK);
        HRESETn <= 1;
    end

    always #5 HCLK = ~ HCLK;
    
    /*integer x; 
           initial begin
            UART_MASTER_RX = 1'b0;
               for(x=0; x<10; x=x+1)
               begin
                   UART_MASTER_RX = ~UART_MASTER_RX;
                   #10;
               end
               end*/
      
               
     // Test Case
                /*   reg[32:0] data;
                   //reg[7:0]program[Memsize-1:0];
                   //integer i;
                   initial begin
                       TX = 1;
                       #2000;
                       FW_RD(ID_OFF, data);
                       //$finish;
                       FW_ENABLE;
                       SPI_OE(4'b0001);
                       SPI_STATRT;
                       SPI_BYTE_WR(8'hFF);
                       SPI_STOP;
                       SPI_STATRT;
                       SPI_BYTE_WR(8'h9F);
                       SPI_BYTE_RD(data);
                       $display("JEDEC Byte 0:%x", data);
                       SPI_BYTE_RD(data);
                       $display("JEDEC Byte 1:%x", data);
                       SPI_BYTE_RD(data);
                       $display("JEDEC Byte 2:%x", data);
                       SPI_STOP;
                       #50000;
                       $finish;
                   end */
    
    `ifdef ICARUS_VERILOG
        // Dump file
        initial begin
            $dumpfile("IBEX_SoC_TB.vcd");
            $dumpvars(`SIM_LEVEL, IBEX_SoC_TB);
            #`SIM_TIME;
            $finish;
        end
    `endif
    // Terminate the smulation with ebreak instruction.
    // Calculate the CPI using the CSRs
    /*`ifndef GL
        always @ (posedge HCLK) 
            if(MUV.CPU.N5.instr_ebreak) begin
            //$display("CPI=%d.%0d", MUV.N5.CSR_CYCLE/MUV.N5.CSR_INSTRET,(MUV.N5.CSR_CYCLE%MUV.N5.CSR_INSTRET)*10/MUV.N5.CSR_INSTRET );
            $finish;
            end
    `endif*/
    
    // Monitor Flash memory reads
    //always @(posedge HCLK)
    //    if(MUV.N5.HTRANS[1] & MUV.N5.HREADY & MUV.N5.HSEL_FLASH)
    //    $display("Flash Read A:%X (%0t)", HADDR, $time);

UART_MON MON (.RX(TX));
// Baud rate 1228800
    // Bit time ~ 813.8ns
    // 8N1
    localparam BITTIME = 208333 ; //baud rate 4800
    //localparam BITTIME = 52083.3; //baud rate 19200
    //localparam BITTIME = 813.8; //baud rate 1228800
    //localparam BITTIME = 7812.5 ; //baud rate 128000
task UART_SEND (input [7:0] data);
            begin : task_body
                integer i;
                #BITTIME;
                @(posedge HCLK);
                TX = 0;
                #BITTIME;
                for(i=0; i<8; i=i+1) begin
                    TX = data[i];
                    #BITTIME;
                end
                TX = 1;
                //#BITTIME;
            end
        endtask
    
        task UART_REC (output [7:0] data);
            begin : task_body
                integer i;
                @(negedge RX);
                #(BITTIME+(BITTIME/2));
                for(i=0; i<8; i=i+1) begin
                    data[i] = RX;
                    #BITTIME;
                end
            end
        endtask
    
        task FW_WR(input [31:0] A, input [31:0] D);
            begin
                UART_SEND(8'hA3);
                UART_SEND(A[7:0]);
                UART_SEND(A[15:8]);
                UART_SEND(A[23:16]);
                UART_SEND(A[31:24]);
                UART_SEND(D[7:0]);
                UART_SEND(D[15:8]);
                UART_SEND(D[23:16]);
                UART_SEND(D[31:24]);
            end
        endtask
    
        task FW_RD(input [31:0] A, output [31:0] D); //4c000018
            begin
                UART_SEND(8'hA5);
                UART_SEND(A[7:0]);
                UART_SEND(A[15:8]);
                UART_SEND(A[23:16]);
                UART_SEND(A[31:24]);
                UART_REC(D[7:0]);
                UART_REC(D[15:8]);
                UART_REC(D[23:16]);
                UART_REC(D[31:24]);
            end
        endtask
    
        task SPI_STATRT;
            FW_WR(SS_OFF, 0);
        endtask
    
        task SPI_STOP;
            FW_WR(SS_OFF, 1);
        endtask
    
        task SPI_OE(input [3:0] data);
            FW_WR(OE_OFF, data);
        endtask
    
        task FW_ENABLE;
            FW_WR(WE_OFF,32'hA5A85501);
        endtask
    
        task SPI_BYTE_WR(input [7:0] data);
            begin : task_body
                integer i;
                for(i=7; i>=0; i=i-1) begin
                    FW_WR(SO_OFF, data[i]);
                    FW_WR(SCK_OFF, 1);
                    FW_WR(SCK_OFF, 0);
                end
            end
        endtask
    
        task SPI_WORD_WR(input [32:0] data);
            begin 
                SPI_BYTE_WR(data[7:0]);
                SPI_BYTE_WR(data[15:8]);
                SPI_BYTE_WR(data[23:16]);
                SPI_BYTE_WR(data[31:24]);
            end
        endtask
    
        task SPI_BYTE_RD(output [7:0] data);
            begin : task_body
                integer i;
                reg [31:0] word;
                for(i=7; i>=0; i=i-1) begin
                    FW_WR(SCK_OFF, 1);
                    FW_RD(SI_OFF, word);
                    data[i] = word[0];
                    FW_WR(SCK_OFF, 0);
                end
            end
        endtask
    
    endmodule

//module terminal #(parameter bit_time = 1333.3333333) (input rx);
module terminal #(parameter bit_time = 160) (input rx);

    integer i;
    reg [7:0] char;
    initial begin
        forever begin
            @(negedge rx);
            i = 0;
            char = 0;
            #(3*bit_time/2);
            for(i=0; i<8; i=i+1) begin
                char[i] = rx;
                #bit_time;
            end
            $write("%c", char);
        end
    end


endmodule

//module UART_MON #(parameter BITTIME=813.8)(input RX);
//module UART_MON #(parameter BITTIME=7812.5)(input RX);
module UART_MON #(parameter BITTIME=208333)(input RX);
//module UART_MON #(parameter BITTIME=52083.3)(input RX);
    reg [7:0] data;
    integer i;
    initial begin
        forever begin
            @(negedge RX);
            #BITTIME;
            for(i=0; i<8; i=i+1) begin
                data = {RX, data[7:1]};
                #BITTIME;
            end
            #BITTIME;
            //$write("%c", data);
            $display("0x%X", data);
        end
    end

endmodule
