/*----------------------------------------------------------------------
Project: FPGA Alarm System
Author: Mihai Florea
Design: one_pulse.v
Description: Detects the rising edge of a signal and generates a single
             clock cycle pulse. Essential for FSM triggers.
----------------------------------------------------------------------*/

module one_pulse(
    input wire i_clk,
    input wire i_signal,
    output wire o_pulse
);
    reg r_signal_dly = 1'b0;

    always @(posedge i_clk) begin
       r_signal_dly <= i_signal;
    end
    
    assign o_pulse = i_signal & ~r_signal_dly;
endmodule
