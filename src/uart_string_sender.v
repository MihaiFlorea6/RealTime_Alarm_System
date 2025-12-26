/*------------------------------------------------------------------------
Project: FPGA Alarm System
Author: Mihai Florea
Design: uart_string_sender.v
Description: Converts system status codes into full ASCII string messages
             sent over UART (e.g., "OPEN", "LOCKED").
------------------------------------------------------------------------*/

module uart_string_sender(
    input wire i_clk,
    input wire i_rst,
    input wire [2:0] i_status,
    input wire i_trigger, // Pulse to start sending
    output wire o_tx,
    output wire o_busy
);

   // FSM States for the string sequencer
   localparam S_IDLE = 2'd0, S_SEND = 2'd1, S_WAIT = 2'd2;
   
   reg [1:0] r_state = S_IDLE;
   reg [3:0] r_char_idx = 4'd0;
   reg [7:0] r_data_to_send;
   reg r_uart_start;
   reg r_trigger_d1;
   wire w_uart_busy;
   wire w_trigger_pulse = i_trigger && !r_trigger_d1;
   
   // Physical layer instance
   uart_tx #(.CLK_FREQ(100000000), .BAUD_RATE(9600)) tx_inst(
       .i_clk(i_clk), .i_rst(i_rst),
       .i_start(r_uart_start), .i_data(r_data_to_send),
       .o_tx(o_tx), .o_busy(w_uart_busy)
   );
   
   assign o_busy = (r_state != S_IDLE);
   
   always @(posedge i_clk) begin
       r_trigger_d1 <= i_trigger;
       
       if (i_rst) begin
           r_state <= S_IDLE;
           r_uart_start <= 1'b0;
           r_char_idx <= 4'd0;
       end else begin
           case (r_state)
               S_IDLE: begin
                   r_uart_start <= 1'b0;
                   if (w_trigger_pulse) begin
                      r_char_idx <= 4'd0;
                      r_state <= S_SEND;
                   end
               end 
               
               S_SEND: begin
                   r_uart_start <= 1'b1;
                   // String selection based on Status
                   case (i_status)       
                       3'b001: begin // "OPEN"
                       if (r_char_idx <= 4'd11) begin
                           r_uart_start <= 1'b1;
                           case(r_char_idx)
                               4'd0: r_data_to_send <= "S"; 4'd1: r_data_to_send <= "T";
                               4'd2: r_data_to_send <= "A"; 4'd3: r_data_to_send <= "T";
                               4'd4: r_data_to_send <= "U"; 4'd5: r_data_to_send <= "S";
                               4'd6: r_data_to_send <= ":"; 4'd7: r_data_to_send <= "O";
                               4'd8: r_data_to_send <= "P"; 4'd9: r_data_to_send <= "E";
                               4'd10: r_data_to_send <= "N"; 4'd11: r_data_to_send <= ";";
                           endcase
                           r_state <= S_WAIT;
                       end else r_state <= S_IDLE;  
                       end
                       3'b010: begin // "WRONG"
                       if (r_char_idx <= 4'd12) begin
                           r_uart_start <= 1'b1;    
                           case(r_char_idx)
                               4'd0: r_data_to_send <= "S"; 4'd1: r_data_to_send <= "T";
                               4'd2: r_data_to_send <= "A"; 4'd3: r_data_to_send <= "T";
                               4'd4: r_data_to_send <= "U"; 4'd5: r_data_to_send <= "S";
                               4'd6: r_data_to_send <= ":"; 4'd7: r_data_to_send <= "W";
                               4'd8: r_data_to_send <= "R"; 4'd9: r_data_to_send <= "O";
                               4'd10: r_data_to_send <= "N"; 4'd11: r_data_to_send <= "G";
                               4'd12: r_data_to_send <= ";";
                           endcase
                           r_state <= S_WAIT;
                       end else r_state <= S_IDLE;    
                       end
                       3'b100: begin // "LOCK"
                       if (r_char_idx <= 4'd11) begin
                           r_uart_start <= 1'b1;
                           case(r_char_idx)
                               4'd0: r_data_to_send <= "S"; 4'd1: r_data_to_send <= "T";
                               4'd2: r_data_to_send <= "A"; 4'd3: r_data_to_send <= "T";
                               4'd4: r_data_to_send <= "U"; 4'd5: r_data_to_send <= "S";
                               4'd6: r_data_to_send <= ":"; 4'd7: r_data_to_send <= "L";
                               4'd8: r_data_to_send <= "O"; 4'd9: r_data_to_send <= "C";
                               4'd10: r_data_to_send <= "K"; 4'd11: r_data_to_send <= ";";
                               default: r_state <= S_IDLE;       
                           endcase
                           r_state <= S_WAIT;
                       end else r_state <= S_IDLE;     
                       end
                   default: r_state <= S_IDLE; 
                   endcase
               end
               
               S_WAIT: begin          
                   r_uart_start <= 1'b0;
                   if (!w_uart_busy && !r_uart_start) begin
                       r_char_idx <= r_char_idx + 1'b1;
                       r_state <= S_SEND;
                   end
               end    
           endcase
       end    
   end         
endmodule
