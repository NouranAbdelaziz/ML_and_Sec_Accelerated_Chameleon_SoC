

`timescale              1ns/1ps
`default_nettype        none

//`include "include/ahb_util.vh"
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


// 19.2K using 16MHz
module AHB_UART_MASTER #(parameter PRESCALE=51) 
(
    input wire          HCLK,
    input wire          HRESETn,
    
    `AHB_MASTER_IFC(),

    input wire          RX,
    output wire         TX,

    output [3:0] st
);

    localparam 
        ST_IDLE  = 4'd15, 
        ST_RD    = 4'd1,
        ST_WR    = 4'd2, 
        ST_ADDR1 = 4'd3,
        ST_ADDR2 = 4'd4, 
        ST_ADDR3 = 4'd5,
        ST_ADDR4 = 4'd6,
        ST_WDATA1 = 4'd7,
        ST_WDATA2 = 4'd8,
        ST_WDATA3 = 4'd9,
        ST_WDATA4 = 4'd10,
        ST_RWAIT  = 4'd11,
        ST_RDATA1 = 4'd12,
        ST_RDATA2 = 4'd13,
        ST_RDATA3 = 4'd14,
        ST_RDATA4 = 4'd0;
        
    wire        b_tick;
    wire        rx_done;
    wire        tx_done;

    wire  [7:0]  tx_data;
    wire [7:0]  rx_data;

    reg         tx_start;

    wire        cmd_rd = (rx_data == 8'hA5);
    wire        cmd_wr = (rx_data == 8'hA3);
    
    wire        done;
    wire        busy;
    reg  [31:0] addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;

    reg  [3:0]  state, 
                nstate;
    reg         rd, wr;
    //wire        done;
    reg [31:0]  rdata_reg;
    
    always @(posedge HCLK or negedge HRESETn)
        if(!HRESETn)
            state <= ST_IDLE;
        else
            state <= nstate; 

    always @*
        case (state)
            ST_IDLE:    if(rx_done & (cmd_rd | cmd_wr))
                            nstate = ST_ADDR1;
                        else
                            nstate = ST_IDLE;
            ST_ADDR1:   if(rx_done)
                            nstate = ST_ADDR2;
                        else
                            nstate = ST_ADDR1;
            ST_ADDR2:   if(rx_done)
                            nstate = ST_ADDR3;
                        else
                            nstate = ST_ADDR2;
            ST_ADDR3:   if(rx_done)
                            nstate = ST_ADDR4;
                        else
                            nstate = ST_ADDR3;
            ST_ADDR4:   case ({rx_done,wr,rd})
                            3'b110 : nstate = ST_WDATA1;
                            3'b101 : nstate = ST_RWAIT;
                            default: nstate = ST_ADDR4;
                        endcase
            ST_WDATA1:   if(rx_done)
                            nstate = ST_WDATA2;
                        else
                            nstate = ST_WDATA1;
            ST_WDATA2:   if(rx_done)
                            nstate = ST_WDATA3;
                        else
                            nstate = ST_WDATA2;
            ST_WDATA3:   if(rx_done)
                            nstate = ST_WDATA4;
                        else
                            nstate = ST_WDATA3;
            ST_WDATA4:   if(rx_done)
                            nstate = ST_IDLE;
                        else
                            nstate = ST_WDATA4;
            ST_RWAIT:   if(done) 
                            nstate = ST_RDATA1; 
                        else 
                            nstate = ST_RWAIT;
            ST_RDATA1:   if(tx_done)
                            nstate = ST_RDATA2;
                        else
                            nstate = ST_RDATA1;
            ST_RDATA2:   if(tx_done)
                            nstate = ST_RDATA3;
                        else
                            nstate = ST_RDATA2;
            ST_RDATA3:   if(tx_done)
                            nstate = ST_RDATA4;
                        else
                            nstate = ST_RDATA3;
            ST_RDATA4:   if(tx_done)
                            nstate = ST_IDLE;
                        else
                            nstate = ST_RDATA4;

        endcase

        always @(posedge HCLK or negedge HRESETn)
        if(!HRESETn) begin
            rd <= 1'b0;
            wr <= 1'b0;
        end else 
            if(rx_done & (state == ST_IDLE)) begin
                rd <= cmd_rd;
                wr <= cmd_wr;
            end
        
        // Address Register    
        always @(posedge HCLK)
            if((ST_ADDR1==state) & rx_done)
                addr[7:0] <= rx_data;
        always @(posedge HCLK)
            if((ST_ADDR2==state) & rx_done)
                addr[15:8] <= rx_data;
        always @(posedge HCLK)
            if((ST_ADDR3==state) & rx_done)
                addr[23:16] <= rx_data;
        always @(posedge HCLK)
            if((ST_ADDR4==state) & rx_done)
                addr[31:24] <= rx_data;
                
        // wdata register
        always @(posedge HCLK)
            if((ST_WDATA1==state) & rx_done & wr)
                wdata[7:0] <= rx_data;
        always @(posedge HCLK)
            if((ST_WDATA2==state) & rx_done  & wr)
                wdata[15:8] <= rx_data;
        always @(posedge HCLK)
            if((ST_WDATA3==state) & rx_done  & wr)
                wdata[23:16] <= rx_data;
        always @(posedge HCLK)
            if((ST_WDATA4==state) & rx_done  & wr)
                wdata[31:24] <= rx_data;

    BAUDGEN uBAUDGEN(
        .clk(HCLK),
        .rst_n(HRESETn),
        .prescale(PRESCALE),
        .en(1'b1),
        .baudtick(b_tick)
    );

    UART_RX uUART_RX(
        .clk(HCLK),
        .resetn(HRESETn),
        .b_tick(b_tick),
        .rx(RX),
        .rx_done(rx_done),
        .dout(rx_data)
    );

    UART_TX uUART_TX(
        .clk(HCLK),
        .resetn(HRESETn),
        .tx_start(tx_start), //???
        .b_tick(b_tick),
        .d_in(tx_data),
        .tx_done(tx_done),
        .tx(TX)
    );

    AHB_MASTER M (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HREADY(HREADY),
        .HRDATA(HRDATA),
        .HWDATA(HWDATA),
        
        .wr(wr & rx_done & (state == ST_WDATA4)),
        .rd(rd & rx_done & (state == ST_ADDR4)),
        .done(done),
        .busy(),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
);

    assign tx_data =    (state == ST_RDATA1) ? rdata_reg[7:0] :
                        (state == ST_RDATA2) ? rdata_reg[15:8] :
                        (state == ST_RDATA3) ? rdata_reg[23:16] : rdata_reg[31:24];

    always @(posedge HCLK)
        if(rd & done)
            rdata_reg <= rdata;

    always @(posedge HCLK)
        if(done & (state == ST_RWAIT))
            tx_start <= 'b1;
        else if(tx_done & (state == ST_RDATA1))
            tx_start <= 'b1;
        else if(tx_done & (state == ST_RDATA2))
            tx_start <= 'b1;
        else if(tx_done & (state == ST_RDATA3))
            tx_start <= 'b1;
        else
            tx_start <= 'b0;
        
    assign st = rx_data[3:0];

endmodule

module AHB_MASTER
(
    input wire          HCLK,
    input wire          HRESETn,
    
    `AHB_MASTER_IFC(),

    input wire          wr,
    input wire          rd,
    output wire         done,
    output wire         busy,
    input wire [31:0]   addr,
    input wire [31:0]   wdata,
    output wire [31:0]  rdata
);

    localparam 
        ST_IDLE = 3'd0, 
        ST_RWAIT = 3'd1,
        ST_WWAIT = 3'd2,
        ST_RADDR = 3'd3, 
        ST_RDATA = 3'd4,
        ST_WADDR = 3'd5, 
        ST_WDATA = 3'd6;

    reg [2:0] state, nstate;

    always @(posedge HCLK or negedge HRESETn)
        if(!HRESETn)
            state <= ST_IDLE;
        else
            state <= nstate; 

    always @*
        case (state)
            ST_IDLE:    begin    
                            nstate = ST_IDLE;
                            if(HREADY & rd) nstate = ST_RADDR;
                            else if(HREADY & wr) nstate = ST_WADDR;
                            else if(~HREADY & rd) nstate = ST_RWAIT;
                            else if(~HREADY & wr) nstate = ST_WWAIT;
                        end    
            ST_RWAIT:   if(HREADY)
                            nstate = ST_RADDR;
                        else 
                            nstate = ST_RWAIT;
            ST_WWAIT:   if(HREADY)
                            nstate = ST_WADDR;
                        else 
                            nstate = ST_WWAIT;
            ST_RADDR:   if(HREADY)
                            nstate = ST_RDATA;
                        else 
                            nstate = ST_RADDR;

            ST_RDATA:   nstate = ST_IDLE;

            ST_WADDR:   if(HREADY)
                            nstate = ST_WDATA;
                        else 
                            nstate = ST_WADDR;

            ST_WDATA:   nstate = ST_IDLE;
            
            default:    nstate = ST_IDLE;
        endcase

    assign done = (state == ST_RDATA) || (state == ST_WDATA);
    assign busy = (state != ST_IDLE);

    assign HADDR    = addr;
    assign HWRITE   = (state == ST_WADDR);
    assign HWDATA   = wdata;
    assign HTRANS   = ((state == ST_WADDR) || (state == ST_RADDR)) ? 2'b10 : 2'b00; 
    assign HSIZE    = 3'b010;

    assign rdata = HRDATA;

endmodule

// Baudrate = Clk/((prescale+1)*16)
// 19200 = 50,000,000 / ((prescale+1)*16)
// prescale = 161.76 ==> 162
/*module BAUDGEN
(
  input wire clk,
  input wire rst_n,
  input wire [15:0] prescale, 
  input wire en,
  output wire baudtick
);

reg [15:0] count_reg;
wire [15:0] count_next;

//Counter
always @ (posedge clk, negedge rst_n)
  begin
    if(!rst_n)
      count_reg <= 0;
    else if(en)
      count_reg <= count_next;
end

assign count_next = ((count_reg == prescale) ? 0 : count_reg + 1'b1);
assign baudtick = ((count_reg == prescale) ? 1'b1 : 1'b0);

endmodule


module UART_RX(
  input wire clk,
  input wire resetn,
  input wire b_tick,        //Baud generator tick
  input wire rx,            //RS-232 data port
  
  output reg rx_done,       //transfer completed
  output wire [7:0] dout    //output data
);

//STATE DEFINES  
  localparam [1:0] idle_st = 2'b00;
  localparam [1:0] start_st = 2'b01;
  localparam [1:0] data_st = 2'b11;
  localparam [1:0] stop_st = 2'b10;

//Internal Signals  
  reg [1:0] current_state;
  reg [1:0] next_state;
  reg [3:0] b_reg; //baud-rate/over sampling counter
  reg [3:0] b_next;
  reg [2:0] count_reg; //data-bit counter
  reg [2:0] count_next;
  reg [7:0] data_reg; //data register
  reg [7:0] data_next;
  
//State Machine  
  always @ (posedge clk, negedge resetn)
  begin
    if(!resetn)
      begin
        current_state <= idle_st;
        b_reg <= 0;
        count_reg <= 0;
        data_reg <=0;
      end
    else
      begin
        current_state <= next_state;
        b_reg <= b_next;
        count_reg <= count_next;
        data_reg <= data_next;
      end
  end

//Next State Logic 
  always @*
  begin
    next_state = current_state;
    b_next = b_reg;
    count_next = count_reg;
    data_next = data_reg;
    rx_done = 1'b0;
        
    case(current_state)
      idle_st:
        if(~rx)
          begin
            next_state = start_st;
            b_next = 0;
          end
          
      start_st:
        if(b_tick)
          if(b_reg == 7)
            begin
              next_state = data_st;
              b_next = 0;
              count_next = 0;
            end
          else
            b_next = b_reg + 1'b1;
            
      data_st:
        if(b_tick)
          if(b_reg == 15)
            begin
              b_next = 0;
              data_next = {rx, data_reg [7:1]};
              if(count_next ==7) // 8 Data bits
                next_state = stop_st;
              else
                count_next = count_reg + 1'b1;
            end
          else
            b_next = b_reg + 1;
            
      stop_st:
        if(b_tick)
          if(b_reg == 15) //One stop bit
            begin
              next_state = idle_st;
              rx_done = 1'b1;
            end
          else
           b_next = b_reg + 1;
    endcase
  end
  
  assign dout = data_reg;
  
endmodule

module UART_TX(
  input wire clk,
  input wire resetn,
  input wire tx_start,        
  input wire b_tick,          //baud rate tick
  input wire [7:0] d_in,      //input data
  output reg tx_done,         //transfer finished
  output wire tx              //output data to RS-232
  );
  
    //STATE DEFINES  
    localparam [1:0] idle_st = 2'b00;
    localparam [1:0] start_st = 2'b01;
    localparam [1:0] data_st = 2'b11;
    localparam [1:0] stop_st = 2'b10;
  
    //Internal Signals  
    reg [1:0] current_state;
    reg [1:0] next_state;
    reg [3:0] b_reg;          //baud tick counter
    reg [3:0] b_next;
    reg [2:0] count_reg;      //data bit counter
    reg [2:0] count_next;
    reg [7:0] data_reg;       //data register
    reg [7:0] data_next;
    reg tx_reg;               //output data reg
    reg tx_next;
  
//State Machine  
  always @(posedge clk, negedge resetn)
  begin
    if(!resetn)
      begin
        current_state <= idle_st;
        b_reg <= 0;
        count_reg <= 0;
        data_reg <= 0;
        tx_reg <= 1'b1;
      end
    else
      begin
        current_state <= next_state;
        b_reg <= b_next;
        count_reg <= count_next;
        data_reg <= data_next;
        tx_reg <= tx_next;
      end
  end


//Next State Logic  
  always @*
  begin
    next_state = current_state;
    tx_done = 1'b0;
    b_next = b_reg;
    count_next = count_reg;
    data_next = data_reg;
    tx_next = tx_reg;
    
    case(current_state)
      idle_st:
      begin
        tx_next = 1'b1;
        if(tx_start)
        begin
          next_state = start_st;
          b_next = 0;
          data_next = d_in;
        end
      end
      
      start_st: //send start bit
      begin
        tx_next = 1'b0;
        if(b_tick)
          if(b_reg==15)
            begin
              next_state = data_st;
              b_next = 0;
              count_next = 0;
            end
          else
            b_next = b_reg + 1;
      end
      
      data_st: //send data serially
      begin
        tx_next = data_reg[0];
        
        if(b_tick)
          if(b_reg == 15)
            begin
              b_next = 0;
              data_next = data_reg >> 1;
              if(count_reg == 7)    //8 data bits
                next_state = stop_st;
              else
                count_next = count_reg + 1;
            end
          else
            b_next = b_reg + 1;
      end
      
      stop_st: //send stop bit
      begin
        tx_next = 1'b1;
        if(b_tick)
          if(b_reg == 15)   //one stop bit
            begin
              next_state = idle_st;
              tx_done = 1'b1;
            end
          else
            b_next = b_reg + 1;
      end
    endcase
  end
  
  assign tx = tx_reg;
  
endmodule
*/

