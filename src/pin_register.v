/*--------------------------------------------------------------------
Project: FPGA Alarm System
Author: Mihai Florea
Design: pin_register.v
Description: Storage element for the Master PIN. Updates only when
             load signal is pulsed.
--------------------------------------------------------------------*/

module pin_register(
    input wire i_clk,
    input wire i_rst,
    input wire i_load_en, // Load pulse
    input wire [3:0] i_sw_val, // Input from switches
    output reg [3:0] o_stored_pin // Registered output
);
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_stored_pin <= 4'b0000;
        end else if (i_load_en) begin
            o_stored_pin <= i_sw_val;
        end
    end
endmodule