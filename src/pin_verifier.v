/*--------------------------------------------------------------------
Project: FPGA Alarm System
Author: Mihai Florea
Design: pin_verifier.v
Description: Core logic FSM. Handles PIN comparison, attempt counting
             and system state (IDLE, ACCESS_GRANTED, LOCKED).
--------------------------------------------------------------------*/

module pin_verifier(
  input wire i_clk,
  input wire i_rst,
  input wire [3:0] i_user_pin, // Current switches value
  input wire [3:0] i_stored_pin, // Saved PIN in memory
  input wire i_valid_pulse, // Trigger from Confirm Button
  output reg [2:0] o_system_state // Status code for Display/UART
);

  localparam S_IDLE = 3'b000;
  localparam S_OPEN = 3'b001;
  localparam S_WRONG = 3'b010;
  localparam S_LOCKED = 3'b100;
  
  reg [1:0] r_fail_cnt;
  reg [2:0] r_state;
  
  always @(posedge i_clk) begin
      if (i_rst) begin
          r_state <= S_IDLE;
          r_fail_cnt <= 2'd0;
          o_system_state <= S_IDLE;
      end else begin
          case (r_state)
              S_IDLE: begin
                  if (i_valid_pulse) begin
                      if (i_user_pin == i_stored_pin) begin
                          r_state <= S_OPEN;
                          r_fail_cnt <= 2'd0;
                      end else begin
                          r_fail_cnt <= r_fail_cnt + 1'b1;
                          if (r_fail_cnt >= 2'd2) r_state <= S_LOCKED;
                          else r_state <= S_WRONG;
                      end
                  end
              end
              
              S_OPEN : o_system_state <= S_OPEN; // Access Granted
              S_WRONG: r_state <= S_IDLE; // Temporary wrong state, go back
              S_LOCKED: o_system_state <= S_LOCKED; // System bricked until Reset         
  
              default: r_state <= S_IDLE;
          endcase  
          
          if (r_state == S_WRONG) o_system_state <= (r_fail_cnt == 2'd1) ? 3'b010 : 3'b011;
      end
  end          
endmodule