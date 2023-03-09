
/*
 * This is the control path for the Keccak design, it was translated manually from control_path.vhd,
 * which was developed by Bernhard Jungk <bernhard@projectstarfire.de>
 * 
 * Copyright (C): 2019
 * Author:        Bernhard Jungk <bernhard@projectstarfire.de>
 *                Xiayuan Wen <xiayuan.wen@yale.edu>
 *                Shanquan Tian <shanquan.tian@yale.edu>
 * Updated:       2023-01-21
 *          
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
*/



`include "clog2.v"
`include "keccak_pkg.v"


module control_path 
(
  input  wire                        clk, 
  input  wire                        rst,
  // external interface
  input  wire                        din_valid,
  output wire                        din_ready, 
  input  wire [`WIN-1:0]             din,
  output reg                         dout_valid,
  input  wire                        dout_ready,
  // internal interface
  output reg                         computation_en,
  output wire [`COUNTER_WIDTH-1:0]   counter_fwd,
  output reg  [`PARALLEL_SLICES-1:0] din_padded,
  output wire                        absorb_cust_fwd,
  output wire                        absorb_data_fwd,
  output reg                         squeeze_output,
  output wire                        bof,
  output reg                         reset_ram,
  output wire                        mux256  
);

localparam [47:0] cshake_prefix_128         =   `CSHAKE_PREFIX_128;
localparam [47:0] cshake_prefix_256         =   `CSHAKE_PREFIX_256;
localparam [31:0] PARALLEL_SLICES_div_48  = 48 >> `DIVCLOG2(`PARALLEL_SLICES) ;

// SUB_READS_COUNT_WIDTH should be 0 for 32 parallel slices, the value 1 is a place holder and will not be used
localparam sub_reads_count_width_larger_than_0 = (`SUB_READS_COUNT_WIDTH > 0) ? `SUB_READS_COUNT_WIDTH : 1;

// Blow are states
localparam s_command_header      =   3'b000;//0 first data block
localparam s_read_length         =   3'b001;//1
localparam s_absorb_cust         =   3'b010;//2 absorb customed string, cstm
localparam s_absorb_data         =   3'b011;//3
localparam s_absorb_pad_block    =   3'b100;//4
localparam s_process             =   3'b101;//5
localparam s_squeeze             =   3'b110;//6


reg         [2:0]                     current_state=0;
reg         [2:0]                     next_state = 0;

reg         [`COUNTER_WIDTH-1:0]      counter = 0;
reg         [1:0]                     counter_ctrl = 0;

reg                                   din_ready_internal = 0;

reg                                   bof_internal = 0;
reg                                   bof_internal_reg = 0;
reg                                   eof_internal = 0;
reg                                   eof_internal_reg = 0;

reg                                   absorb_cust = 0;
reg                                   absorb_cust_reg = 0;
reg                                   absorb_data = 0;
reg                                   absorb_data_reg = 0;
reg                                   extra_pad = 0;
reg                                   extra_pad_reg = 0;

reg         [`WIN-3:0]                requested_bytes = 0;
reg         [`WIN-3:0]                requested_bytes_reg = 0;
  
reg         [`RATE_WIDTH-1:0]         data_length = 0;
reg         [`RATE_WIDTH-1:0]         data_length_reg = 0;            
reg         [`RATE_WIDTH-1:0]         to_be_read = 0;
reg         [`RATE_WIDTH-1:0]         to_be_read_reg = 0;
reg         [`RATE_WIDTH-1:0]         to_be_absorbed = 0;
reg         [`RATE_WIDTH-1:0]         to_be_absorbed_reg = 0;

reg                                   cshake = 0;
reg                                   cshake_reg = 0;

reg         [31:0]                    din_save = 0;
reg         [31:0]                    din_save_reg = 0;
// Added new registers 20190924
reg         [10:0]                    rate = 0;
reg         [10:0]                    rate_reg = 0;
reg         [10:0]                    max_reads_count = 0;
reg         [10:0]                    max_reads_count_reg = 0;//=1087 when PARALLEL_SLICES=1
// reg         [47:0]                    cshake_prefix;
// reg         [47:0]                    cshake_prefix_reg;
reg                                   mux256_internal = 0;
reg                                   mux256_reg = 0;

// wire [63:0] debug;
// assign debug = `MAX_READS_COUNT_128;//671
// wire [63:0] debug2;
// assign debug2 = `MAX_READS_COUNT_256;//543

assign absorb_cust_fwd            =   absorb_cust;
assign absorb_data_fwd            =   absorb_data;
assign counter_fwd                =   counter;
assign mux256                     =   mux256_internal;

assign bof                        =   bof_internal;
assign din_ready                  =   din_ready_internal;


// general counter, reused in different states
always @ (posedge clk) //Dff
begin: COUNTER_CTRL_PROC
  if(rst == 1'b1)
    counter <= 0;
  else
  begin 
  if(counter_ctrl == 2'b11)
    counter <= counter + 1;
  else if(counter_ctrl == 2'b00)
    counter <= 0;
  else
    counter <= counter;
  end
end

always @ (posedge clk) //Dff
begin: DIN_SAVE_REG_PROC
  if ((din_valid == 1'b1) && (din_ready_internal == 1'b1))
    din_save_reg <= din_save;
  else
    din_save_reg <= din_save_reg;
end

always @ (posedge clk) //Dff
begin: REGS_PROC
  eof_internal_reg <= eof_internal;
  bof_internal_reg <= bof_internal;
  to_be_read_reg <= to_be_read;
  to_be_absorbed_reg <= to_be_absorbed;
  data_length_reg <= data_length;
  cshake_reg <= cshake;
  extra_pad_reg <= extra_pad;
  requested_bytes_reg <= requested_bytes;
  
  rate_reg <= rate;
  max_reads_count_reg <= max_reads_count;
  // cshake_prefix_reg <= cshake_prefix;
  mux256_reg <= mux256_internal;
end

// State registers
always @ (posedge clk) //Dff
begin: FSM_SWITCH_STATE_PROC
  if (rst == 1'b1)
    current_state <= s_command_header;
  else
    current_state <= next_state;
end

// Next-state logic
// always @ (*)
always @ (current_state or din_valid or dout_ready or cshake
          or counter or eof_internal_reg or to_be_read_reg 
          or requested_bytes_reg or extra_pad_reg or max_reads_count_reg
          or absorb_data)
begin: FSM
  next_state = current_state;
  case (current_state)
    s_command_header:
    begin
      if((din_valid == 1'b1) && (cshake == 1'b0))
        next_state = s_read_length;
      else if ((din_valid == 1'b1) && (cshake == 1'b1))
        next_state = s_absorb_cust;
      else
        next_state = s_command_header;
    end
    s_read_length:
    begin
      if(din_valid == 1'b1)
        next_state = s_absorb_data;
      else
        next_state = s_read_length;
    end
    s_absorb_cust:
    begin
      if(counter == `MAX_SUB_ROUNDS)
        next_state = s_process;
      else
        next_state = s_absorb_cust;
    end
    s_absorb_data://after absorbing rate bits, we switch to the processing state
    begin
      if((counter == max_reads_count_reg) && (to_be_read_reg <= `PARALLEL_SLICES) && (absorb_data == 1'b1))
        next_state = s_process;
      else
        next_state = s_absorb_data;
    end
    s_absorb_pad_block:
    begin
      if(counter == max_reads_count_reg)
        next_state = s_process;
      else
        next_state = s_absorb_pad_block;
    end
    s_process:
    begin
      if(counter == `MAX_ROUND_COUNT)
        begin
          if(eof_internal_reg == 1'b0)
            next_state = s_read_length;
            // another block has to be absorbed
          else if((eof_internal_reg == 1'b1) && (extra_pad_reg == 1'b1))
            next_state = s_absorb_pad_block;
            // another pad block has to be absorbed
          else
            // we are finished
            next_state = s_squeeze;
        end
      else
        next_state = s_process;
    end
    s_squeeze:
    begin
      if((requested_bytes_reg < `PARALLEL_SLICES) && (dout_ready == 1'b1))
        // this was the last squeeze
        next_state = s_command_header;
      else if((requested_bytes_reg >= `PARALLEL_SLICES) && (counter == max_reads_count_reg) && (dout_ready == 1'b1))
        // process next squeeze
        next_state = s_process;
      else
        next_state = s_squeeze;
    end
    default:
    begin
      next_state = s_command_header;
    end
  endcase
end

reg din_ready_variable = 1'b0;
reg absorb_data_variable = 1'b0;

always @ (current_state or din_valid or dout_ready or din 
  or absorb_data or counter or bof_internal_reg 
  or eof_internal_reg or to_be_read_reg or to_be_absorbed_reg or data_length_reg 
  or requested_bytes_reg or cshake_reg or extra_pad_reg or din_save_reg 
  or max_reads_count_reg or mux256_reg or rate_reg)
begin: FSM_BEHAVIOR
  reset_ram = 1'b0;


  case(current_state)
    
    s_command_header:
    begin
        din_ready_internal  = 1'b1;
        dout_valid = 1'b0; // no output, yet

        // cshake/shake multiplexer
        cshake = din[`WIN-1];
        mux256_internal = din[`WIN-2];  
        if (din[`WIN-2] == 1'b0) begin
          rate = `RATE_128;
          max_reads_count = `MAX_READS_COUNT_128;
        end else begin
          rate = `RATE_256;
          max_reads_count = `MAX_READS_COUNT_256;
        end


        
        // bof/eof signaling
        bof_internal = 1'b1;
        eof_internal = 1'b0;
        
        // absorption control
        absorb_cust = 1'b0;
        absorb_data = 1'b0;
        
        // pad control
        extra_pad = 1'b0;

        // disable round computation
        computation_en = 1'b0;

        // squeeze write control
        squeeze_output = 1'b0;

        // counter controls
        counter_ctrl = 2'b00;
        
        // the rest of the command header specifies how many bytes have been requested from the XOF
        requested_bytes = din[`WIN-3:0];
        
        // no data to be read from AXI-lite interface
        to_be_read = {`RATE_WIDTH{1'b0}}; //width: `RATE_WIDTH

        to_be_absorbed = {`RATE_WIDTH{1'b0}}; //width: `RATE_WIDTH
        data_length = {`RATE_WIDTH{1'b0}}; //width: `RATE_WIDTH
        
        // no data to absorb
        din_padded = {`PARALLEL_SLICES{1'b0}}; //width: `PARALLEL_SLICES
        din_save = din_save_reg;
        
        // reset RAM
        reset_ram = 1'b1;
    end
    
    s_read_length:
    begin
        // AXI-lite signals
        din_ready_internal = 1'b1;
        //AXI-lite master not ready to transmit data
        dout_valid = 1'b0;

        // keep values
        cshake = cshake_reg;

        mux256_internal = mux256_reg;
        rate = rate_reg;
        max_reads_count = max_reads_count_reg;


        // bof/eof signaling
        bof_internal = bof_internal_reg;
        eof_internal = din[`WIN-1]; // first bit signals eof

        // absorption control signals
        absorb_cust = 1'b0;
        absorb_data = 1'b0;

        // extra pad control
        if((cshake_reg == 1'b0) 
          && (din[`RATE_WIDTH-1:0] > (rate_reg-6))) begin
          extra_pad = 1'b1;
        end else if((cshake_reg == 1'b1) 
          && (din[`RATE_WIDTH-1:0] > (rate_reg-4))) begin
          extra_pad = 1'b1;
        end else begin
          extra_pad = 1'b0;
        end
        // disable round computation
        computation_en = 1'b0;

        // squeeze write control signals
        squeeze_output = 1'b0;
        
        // counter controls
        counter_ctrl = 2'b00;
        
        // keep the requested bytes in the register
        requested_bytes = requested_bytes_reg;

        // initialize the two registers from din signal
        to_be_read = din[`RATE_WIDTH-1:0]; // counts down to 0
        to_be_absorbed = din[`RATE_WIDTH-1:0];
        data_length = din[`RATE_WIDTH-1:0]; // stores the value permanently

        // no data to absorb, yet
        din_padded = {`PARALLEL_SLICES{1'b0}};
        din_save = din_save_reg;
        
        // don't reset RAM
        reset_ram = 1'b0;
    end
    
    s_absorb_cust:
    begin
        // AXI-lite ready signal for the absorption of one din block
        if(counter == 0) 
          din_ready_internal = 1'b1;
        else
          din_ready_internal = 1'b0;
          
        dout_valid = 1'b0; // no output, yet

        // keep values
        cshake = cshake_reg;
        mux256_internal = mux256_reg;  
        rate = rate_reg;
        max_reads_count = max_reads_count_reg;




        
        // bof/eof signaling
        bof_internal = bof_internal_reg;
        eof_internal = 1'b0;
        
        // absorption control
        if(((din_valid == 1'b1)) || (counter > 0))
          absorb_cust = 1'b1;
        else
          absorb_cust = 1'b0;
          
        absorb_data = 1'b0;
        
        // pad control
        extra_pad = extra_pad_reg;
        
        // disable round computation
        computation_en = 1'b0;
        
        // squeeze write control
        squeeze_output = 1'b0;

        // counter controls
        if(((counter == 0) && (din_valid == 1'b1)) || ((counter > 0) && (counter < `MAX_SUB_ROUNDS)))
          counter_ctrl = 2'b11;
        else
          counter_ctrl = 2'b00;

        // keep values in the following registers
        requested_bytes = requested_bytes_reg;
        to_be_read = to_be_read_reg;
        to_be_absorbed = to_be_absorbed_reg;
        data_length = data_length_reg;        
        


        if(counter < (PARALLEL_SLICES_div_48)) begin
          //-- absorb customization string from input data directly
          if (mux256_reg == 1'b0) begin
            din_padded[`PARALLEL_SLICES-1:0] 
            = cshake_prefix_128[((counter+1) * `PARALLEL_SLICES-1)-:`PARALLEL_SLICES]; 
          end else begin
            din_padded[`PARALLEL_SLICES-1:0] 
            = cshake_prefix_256[((counter+1) * `PARALLEL_SLICES-1)-:`PARALLEL_SLICES]; 
          end
        end else begin
          if(`PARALLEL_SLICES < 32) begin
          //-- absorb customization string only for parallel_slice < 32, since the complete prefix is already absorbed
            din_padded[`PARALLEL_SLICES-1:0]
            = din_save_reg[(((counter-PARALLEL_SLICES_div_48)+1) * `PARALLEL_SLICES - 1) -: `PARALLEL_SLICES];            
          end else if (`PARALLEL_SLICES == 32) begin
            //-- absrb 16 bit from the prefix and 16 bit of the customization prefix for parallel_slices = 32
            //-- the mod is there, because somehow Vivado simulation complains for parallel_slices < 32 
            din_padded[31:16] = din_save_reg[15:0];
            din_padded[15:0] = cshake_prefix_128[47:32];
          end
        end

        if(counter == 0) 
          din_save = din;
        else
          din_save = din_save_reg;

        // don't reset RAM
        reset_ram = 1'b0;
    end
    
    s_absorb_data:
    begin
        // AXI-lite signals
        if((`SUB_READS_COUNT_WIDTH == 0) && (to_be_read_reg >= `PARALLEL_SLICES)) 
        //-- this only happens for parallel_slices = 32
          din_ready_variable = 1'b1;
        else if((counter[sub_reads_count_width_larger_than_0-1:0] == 0) && (to_be_read_reg >= `PARALLEL_SLICES))
        //-- this only happens for parallel_slices < 32 
          din_ready_variable = 1'b1;
        else
          din_ready_variable = 1'b0;

        din_ready_internal = din_ready_variable;

        dout_valid = 1'b0;

        // cshake/shake multiplexer
        cshake = cshake_reg;
        mux256_internal = mux256_reg;  
        rate = rate_reg;
        max_reads_count = max_reads_count_reg;


        
        // bof/eof signaling
        bof_internal = bof_internal_reg;
        eof_internal = eof_internal_reg;

        // absorption control
        absorb_cust  = 1'b0;
        if((din_valid == 1'b0) && (din_ready_variable == 1'b1)) 
          absorb_data_variable = 1'b0;
        else        
          absorb_data_variable = 1'b1;

        absorb_data = absorb_data_variable;
        
        // pad control
        extra_pad = extra_pad_reg;
                
        // disable round computation
        computation_en = 1'b0;
        
        // squeeze write control
        squeeze_output = 1'b0;
        
        // counter controls
        if((counter == max_reads_count_reg) && (to_be_read_reg <= `PARALLEL_SLICES) && (absorb_data == 1'b1)) 
          counter_ctrl = 2'b00;
        else if((counter == max_reads_count_reg) && (to_be_read_reg > `PARALLEL_SLICES)) 
          counter_ctrl = 2'b10;
        else if((din_valid == 1'b0) && (din_ready_variable == 1'b1))
          counter_ctrl = 2'b10;
        else
          counter_ctrl = 2'b11;

        // keep the requested bytes in the register
        requested_bytes = requested_bytes_reg;

        if(absorb_data_variable == 1'b1) 
          begin
          if(to_be_absorbed_reg > `PARALLEL_SLICES) 
            to_be_absorbed = to_be_absorbed_reg - `PARALLEL_SLICES;
          else
            to_be_absorbed = {`RATE_WIDTH{1'b0}};
          end
        else
          to_be_absorbed = to_be_absorbed_reg;
                
        if((absorb_data_variable == 1'b1)) 
          begin
          if(to_be_read_reg > `PARALLEL_SLICES) 
            to_be_read = to_be_read_reg - `PARALLEL_SLICES;
          else
            to_be_read = {`RATE_WIDTH{1'b0}};
          end
        else
          to_be_read = to_be_read_reg;
        
        // no data to be read (maximum is the rate), if to_be_read is > rate, 
        // then the state machine will be stuck.
        if((counter == max_reads_count_reg) && (absorb_data == 1'b1))
          // this is a hack to ease the padding of the extra block
          data_length = data_length_reg + (2048 - rate_reg);
        else
          data_length = data_length_reg;

        din_padded = {`PARALLEL_SLICES{1'b0}}; 

        if (`SUB_READS_COUNT_WIDTH == 0) begin
          // For 32 parallel slices
          if((din_ready_variable == 1'b1) && (to_be_absorbed_reg > 0)) 
            din_padded = din[((0+1)*`PARALLEL_SLICES-1)-:`PARALLEL_SLICES];  //Questions: 1. Overflow 2. width
          else if((din_ready_variable == 1'b0) && (to_be_absorbed_reg > 0))
            din_padded = din_save_reg[((0+1)*`PARALLEL_SLICES-1)-:`PARALLEL_SLICES]; 
        end else begin
          // For < 32 parallel slices
          if((din_ready_variable == 1'b1) && (to_be_absorbed_reg > 0)) 
            din_padded = din[((counter[sub_reads_count_width_larger_than_0-1:0]+1)*`PARALLEL_SLICES-1)-:`PARALLEL_SLICES];  //Questions: 1. Overflow 2. width
          else if((din_ready_variable == 1'b0) && (to_be_absorbed_reg > 0))
            din_padded = din_save_reg[((counter[sub_reads_count_width_larger_than_0-1:0]+1)*`PARALLEL_SLICES-1)-:`PARALLEL_SLICES];  
        end

        if((eof_internal_reg == 1'b1) && (to_be_absorbed_reg < `PARALLEL_SLICES) && (cshake_reg == 1'b1))
          begin
          if(`PARALLEL_SLICES == 1) 
            begin
            if(counter == data_length_reg)
              din_padded[0] = 1'b0;
            else if(counter == (data_length_reg + 1))
              din_padded[0] = 1'b0;
            else if(counter == (data_length_reg + 2))
              din_padded[0] = 1'b1;
            else if((counter == (rate_reg - 1)) && (extra_pad_reg == 1'b0))
              din_padded[0] = 1'b1;
            end
          else if(`PARALLEL_SLICES > 1) 
            begin
            if(counter == (data_length_reg>> `CLOG2(`PARALLEL_SLICES))) 
              din_padded[data_length_reg & (`PARALLEL_SLICES-1)] = 1'b0;
            if(counter == ((data_length_reg+1)>> `CLOG2(`PARALLEL_SLICES))) 
              din_padded[(data_length_reg+1) & (`PARALLEL_SLICES-1)] = 1'b0;
            if(counter == ((data_length_reg+2)>> `CLOG2(`PARALLEL_SLICES)))
              din_padded[(data_length_reg+2) & (`PARALLEL_SLICES-1)] = 1'b1;            
            if((counter == ((rate_reg >> `CLOG2(`PARALLEL_SLICES)) - 1)) && (extra_pad_reg == 1'b0))
              din_padded[`PARALLEL_SLICES-1] = 1'b1;
            end
          end
        else if((eof_internal_reg == 1'b1) && (to_be_absorbed_reg < `PARALLEL_SLICES) && (cshake_reg == 1'b0))
          begin
          if(`PARALLEL_SLICES == 1) 
            begin
            if(counter == data_length_reg) 
              din_padded[0] = 1'b1;
            else if(counter == (data_length_reg + 1))
              din_padded[0] = 1'b1;
            else if(counter == (data_length_reg + 2))
              din_padded[0] = 1'b1;
            else if(counter == (data_length_reg + 3)) 
              din_padded[0] = 1'b1;
            else if(counter == (data_length_reg + 4))
              din_padded[0] = 1'b1;
            else if((counter == rate_reg - 1) && (extra_pad == 1'b0))
              din_padded[0] = 1'b1;
            end
          else if(`PARALLEL_SLICES > 1) 
            begin
            if(counter == (data_length_reg>> `CLOG2(`PARALLEL_SLICES))) 
              din_padded[data_length_reg & (`PARALLEL_SLICES-1)] = 1'b1;
            if(counter == ((data_length_reg+1)>> `CLOG2(`PARALLEL_SLICES))) 
              din_padded[(data_length_reg+1) & (`PARALLEL_SLICES-1)] = 1'b1;      
            if(counter == ((data_length_reg+2)>> `CLOG2(`PARALLEL_SLICES)))
              din_padded[(data_length_reg+2) & (`PARALLEL_SLICES-1)] = 1'b1;
            if(counter == ((data_length_reg+3)>> `CLOG2(`PARALLEL_SLICES)))
              din_padded[(data_length_reg+3) & (`PARALLEL_SLICES-1)] = 1'b1;
            if(counter == ((data_length_reg+4)>> `CLOG2(`PARALLEL_SLICES)))
              din_padded[(data_length_reg+4) & (`PARALLEL_SLICES-1)] = 1'b1;
            if((counter == ((rate_reg >> `CLOG2(`PARALLEL_SLICES)) - 1)) && (extra_pad_reg == 1'b0))
              din_padded[`PARALLEL_SLICES-1] = 1'b1;
            end
          end
        if((`PARALLEL_SLICES <= 32) && (din_ready_variable == 1'b1) && (din_valid == 1'b1)) 
          din_save = din;
        // else if(`PARALLEL_SLICES == 64) 
        else 
          din_save = din_save_reg;// FIXME DEBUG TO ELIMINATE LATCH 
        
        // don't reset RAM
        reset_ram = 1'b0;
    end
    
    s_absorb_pad_block:
    begin
        //AXI-lite signals
        din_ready_internal = 1'b0;
        dout_valid = 1'b0; // no output, yet

        cshake = cshake_reg;
        mux256_internal = mux256_reg;  
        rate = rate_reg;
        max_reads_count = max_reads_count_reg;
        
        bof_internal = 1'b0;
        eof_internal = 1'b1;

        absorb_cust = 1'b0;
        absorb_data = 1'b1;
        
        // pad control
        extra_pad = 1'b0;
        
        // disable round computation
        computation_en = 1'b0;
        
        // squeeze write control signals
        squeeze_output = 1'b0;
 
        if(counter == max_reads_count_reg)
          counter_ctrl = 2'b00;
        else
          counter_ctrl = 2'b11;
        
        // keep the requested bytes in the register
        requested_bytes = requested_bytes_reg;
        to_be_read = to_be_read_reg;
        to_be_absorbed = to_be_absorbed_reg;
        data_length = data_length_reg;      
        
        din_padded = {`PARALLEL_SLICES{1'b0}};
        
        if(cshake_reg == 1'b1) 
          begin
          if(`PARALLEL_SLICES == 1) 
            begin
            if(counter == data_length_reg)
              din_padded[0] = 1'b0;
            else if(counter == (data_length_reg + 1))
              din_padded[0] = 1'b0;
            else if(counter == (data_length_reg + 2))
              din_padded[0] = 1'b1;
            else if(counter == (rate_reg - 1))
              din_padded[0] = 1'b1;
            end
          else if(`PARALLEL_SLICES > 1) 
            begin
            if(counter == (data_length_reg>> `CLOG2(`PARALLEL_SLICES))) 
              din_padded[data_length_reg & (`PARALLEL_SLICES-1)] = 1'b0;            
            if(counter == ((data_length_reg+1)>> `CLOG2(`PARALLEL_SLICES)))  
              din_padded[(data_length_reg+1) & (`PARALLEL_SLICES-1)] = 1'b0;
            if(counter == ((data_length_reg+2)>> `CLOG2(`PARALLEL_SLICES)))
              din_padded[(data_length_reg+2) & (`PARALLEL_SLICES-1)] = 1'b1;
            if(counter == ((rate_reg >> `CLOG2(`PARALLEL_SLICES)) - 1))
              din_padded[`PARALLEL_SLICES-1] = 1'b1;
            end
          end
        else
          begin
          if(`PARALLEL_SLICES == 1) 
            begin
            if(counter == data_length_reg)
              din_padded[0] = 1'b1;
            else if(counter == (data_length_reg + 1))
              din_padded[0] = 1'b1;
            else if(counter == (data_length_reg + 2))
              din_padded[0] = 1'b1;
            else if(counter == (data_length_reg + 3))
              din_padded[0] = 1'b1;
            else if(counter == (data_length_reg + 4))
              din_padded[0] = 1'b1;
            else if(counter == (rate_reg - 1))
              din_padded[0] = 1'b1;
            end
          else if(`PARALLEL_SLICES > 1)
            begin
            if(counter == (data_length_reg>> `CLOG2(`PARALLEL_SLICES))) 
              din_padded[data_length_reg & (`PARALLEL_SLICES-1)] = 1'b1;
            if(counter == ((data_length_reg+1)>> `CLOG2(`PARALLEL_SLICES))) 
              din_padded[(data_length_reg+1) & (`PARALLEL_SLICES-1)] = 1'b1;
            if(counter == ((data_length_reg+2)>> `CLOG2(`PARALLEL_SLICES)))
              din_padded[(data_length_reg+2) & (`PARALLEL_SLICES-1)] = 1'b1;
            if(counter == ((data_length_reg+3)>> `CLOG2(`PARALLEL_SLICES)))
              din_padded[(data_length_reg+3) & (`PARALLEL_SLICES-1)] = 1'b1;            
            if(counter == ((data_length_reg+4)>> `CLOG2(`PARALLEL_SLICES)))
              din_padded[(data_length_reg+4) & (`PARALLEL_SLICES-1)] = 1'b1;
            if(counter == ((rate_reg >> `CLOG2(`PARALLEL_SLICES)) - 1))
              din_padded[`PARALLEL_SLICES-1] = 1'b1;
            end
          end
          
        din_save = din_save_reg;
        
        // don't reset RAM
        reset_ram = 1'b0;
    end
    
    s_process:
    begin
        // FIFO signals
        din_ready_internal = 1'b0;
        dout_valid = 1'b0;
        
        cshake = cshake_reg;
        mux256_internal = mux256_reg;  
        rate = rate_reg;
        max_reads_count = max_reads_count_reg;
        
        // internal eof and bof flags
        if(counter == `MAX_SUB_ROUNDS)
          bof_internal = 1'b0;
        else
          bof_internal = bof_internal_reg;
          
        eof_internal = eof_internal_reg;

        absorb_cust = 1'b0;
        absorb_data = 1'b0;

        extra_pad = extra_pad_reg;
        
        // start computation
        computation_en = 1'b1;
        
        squeeze_output = 1'b0;
        
        // counter controls
        if(counter == `MAX_ROUND_COUNT)
          counter_ctrl = 2'b00;
        else
          counter_ctrl = 2'b11;
        
        if((counter == `MAX_ROUND_COUNT) && (eof_internal_reg == 1'b1) && (extra_pad_reg == 1'b0))
          requested_bytes = requested_bytes_reg - `PARALLEL_SLICES;
        else
          requested_bytes = requested_bytes_reg;
        
        to_be_read = {`RATE_WIDTH{1'b0}};
        to_be_absorbed = to_be_absorbed_reg;
        data_length = data_length_reg;
        
        din_padded = {`PARALLEL_SLICES{1'b0}};
        din_save = din_save_reg;
        
        // don't reset RAM
        reset_ram = 1'b0;
    end

    s_squeeze:
    begin
        // TODO fix errors with multiple squeezes:
        // -> requested_bytes seems to be not properly tracked
        // -> read addresses for second processing are wrong in the beginning
      
        // FIFO signals
        din_ready_internal = 1'b0;
        if((counter & (`NUM_SUB_READS_COUNT-1)) == (`NUM_SUB_READS_COUNT-1))
          dout_valid = 1'b1;
        else
          dout_valid = 1'b0;
        
        cshake = cshake_reg;
        mux256_internal = mux256_reg;  
        rate = rate_reg;
        max_reads_count = max_reads_count_reg;

        bof_internal = 1'b0;
        eof_internal = 1'b1;
        
        absorb_cust = 1'b0;
        absorb_data = 1'b0;

        extra_pad = extra_pad_reg;
        
        computation_en = 1'b0;        

        if(((counter & (`NUM_SUB_READS_COUNT-1)) == (`NUM_SUB_READS_COUNT-1)) && 
           (dout_ready != 1'b1))
          begin
          counter_ctrl = 2'b10;
          squeeze_output = 1'b0; // check
          requested_bytes = requested_bytes_reg;
          end
        else if((counter == max_reads_count_reg) || (requested_bytes_reg < `PARALLEL_SLICES))
          begin
          counter_ctrl = 2'b00;
          squeeze_output = 1'b1; // check
          requested_bytes = requested_bytes_reg;
          end
        else
          begin
          counter_ctrl = 2'b11;
          squeeze_output = 1'b1; // check

          if(requested_bytes_reg >= `PARALLEL_SLICES)
            requested_bytes = requested_bytes_reg - `PARALLEL_SLICES;
          else if(requested_bytes_reg < `PARALLEL_SLICES)
            requested_bytes = {(`WIN-1){1'b0}};
          else
            requested_bytes = requested_bytes_reg;
          end
        
        to_be_read = {`RATE_WIDTH{1'b0}};
        to_be_absorbed = to_be_absorbed_reg;
        data_length = data_length_reg;
        
        din_padded = {`PARALLEL_SLICES{1'b0}};
        din_save = din_save_reg;
        
        // don't reset RAM
        if((counter == max_reads_count_reg) && (dout_ready == 1'b1))
          reset_ram = 1'b0;
        else
          reset_ram = 1'b0;
    end

    default:
    begin
      //  Value for default
      mux256_internal=0;
      rate=0;
      din_save=0;
      to_be_absorbed=0;
      max_reads_count=0;

      din_ready_internal  = 1'b0;
      dout_valid = 1'b0; 

      cshake = 1'b0;
          
      bof_internal = 1'b0;
      eof_internal = 1'b0;
      
      absorb_cust = 1'b0;
      absorb_data = 1'b0;
            
      extra_pad = 1'b0;

      computation_en = 1'b0;

      squeeze_output = 1'b0;

      counter_ctrl = 2'b00;
            
      requested_bytes = {(`WIN-1){1'b0}};
            
      to_be_read = {`RATE_WIDTH{1'b0}}; //width: `RATE_WIDTH
      data_length = {`RATE_WIDTH{1'b0}}; //width: `RATE_WIDTH
            
      din_padded = {`PARALLEL_SLICES{1'b0}}; //width: `PARALLEL_SLICES
    end

  endcase

end

endmodule
