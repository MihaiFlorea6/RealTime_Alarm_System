/*--------------------------------------------------------------------
Project: FPGA Alarm System
Author: Mihai Florea
Design: display_driver.v
Description: Handles 4-digit 7-segment multiplexing. Uses an internal
             prescaler for a stable refresh rate (~760Hz).
             Decodes system states into alphanumeric messages.
--------------------------------------------------------------------*/

module display_driver(
  input wire i_clk,
  input wire i_rst,
  input wire [2:0] i_status,        
  output reg [3:0] o_anode,     
  output reg [6:0] o_seg        
);

  // Internal Registers
  reg [17:0] r_refresh_cnt = 18'd0;
  reg [3:0] r_char_code;
  wire [1:0] w_digit_sel = r_refresh_cnt[17:16];

  // Refresh Counter for Multiplexing
  always @(posedge i_clk) begin
    if (i_rst) r_refresh_cnt <= 18'd0;
    else r_refresh_cnt <= r_refresh_cnt + 1'b1;
  end

  // Anode Switching Logic
  always @(*) begin
    case (w_digit_sel)
      2'b00: o_anode = 4'b1110;  // digit 0
      2'b01: o_anode = 4'b1101;  // digit 1
      2'b10: o_anode = 4'b1011;  // digit 2
      2'b11: o_anode = 4'b0111;  // digit 3
      default: o_anode = 4'b1111;
    endcase
  end

  // Character Selector based on System Status
  always @(*) begin
    case (i_status)
      3'b001: begin  // "OPEN"
        case (w_digit_sel)
          2'd0: r_char_code = 4'd3; // n
          2'd1: r_char_code = 4'd2; // E
          2'd2: r_char_code = 4'd1; // P
          2'd3: r_char_code = 4'd0; // O
        endcase
      end
      3'b100: begin  // "OUT"
        case (w_digit_sel)
          2'd0: r_char_code = 4'hF; // Blank
          2'd1: r_char_code = 4'd5; // T
          2'd2: r_char_code = 4'd8; // U
          2'd3: r_char_code = 4'd7; // O
        endcase
      end
      default: r_char_code = 4'hE; // Dash "----"
    endcase
  end

  // Segment Decoder (Active LOW)
  always @(*) begin
    case (r_char_code)
      4'd0: o_seg = 7'b1000000; // O
      4'd1: o_seg = 7'b0001100; // P
      4'd2: o_seg = 7'b0000110; // E
      4'd3: o_seg = 7'b0101011; // n
      4'd5: o_seg = 7'b1001110; // T
      4'd7: o_seg = 7'b1000000; // O
      4'd8: o_seg = 7'b1000001; // U
      4'hE: o_seg = 7'b0111111; // -
      4'hF: o_seg = 7'b1111111; // Blank
      default: o_seg = 7'b1111111; 
    endcase
  end
endmodule
