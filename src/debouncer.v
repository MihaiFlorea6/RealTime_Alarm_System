/*-------------------------------------------------------------------
Project: FPGA Alarm System
Author: Mihai Florea
Design: debouncer.v
Description: Filters mechanical bounce from physical buttons using a
             stable counter-based approach.
-------------------------------------------------------------------*/

module debouncer #(
    parameter COUNT_MAX = 16'hFFFF // ~0.65ms at 100MHz, adjustable for hardware
)(
    input wire i_clk,
    input wire i_btn,
    output reg o_stable_btn = 1'b0
);
    reg [15:0] r_cnt = 16'd0;
    reg r_state = 1'b0;

    always @(posedge i_clk) begin
        if (i_btn == r_state)
            r_cnt <= 16'd0;
        else begin
            r_cnt <= r_cnt + 1'b1;
            if (r_cnt == COUNT_MAX) begin
                r_state <= i_btn;
                o_stable_btn <= i_btn;
            end
        end
    end
endmodule