/*--------------------------------------------------------------------
Project: FPGA Alarm System
Author: Mihai Florea
Design: uart_tx.v
Description: Serial transmitter (8N1). Converts parallel bytes to
             asynchronous serial data at 9600 Baud.
--------------------------------------------------------------------*/

module uart_tx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input wire i_clk,
    input wire i_rst,
    input wire i_start,
    input wire [7:0] i_data,
    output reg o_tx = 1'b1,
    output reg o_busy = 1'b0
);
    
    localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    
    reg [3:0] r_bit_index = 4'd0;
    reg [15:0] r_clk_cnt = 16'd0;
    reg [9:0] r_tx_shift = 10'b1111111111;  
    
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_tx <= 1'b1;
            o_busy <= 1'b0;
            r_bit_index <= 4'd0;
            r_clk_cnt <= 16'd0;
        end else begin
            if (i_start && !o_busy) begin
                r_tx_shift <= {1'b1, i_data, 1'b0};  // Stop, Data, Start
                o_busy <= 1'b1;
                r_bit_index <= 4'd0;
                r_clk_cnt <= 16'd0;
            end 
            else if (o_busy) begin
                if (r_clk_cnt < BIT_PERIOD - 1) begin
                    r_clk_cnt <= r_clk_cnt + 1'b1;
                end else begin
                    r_clk_cnt <= 16'd0;
                    if (r_bit_index < 10) begin
                        o_tx <= r_tx_shift[r_bit_index];
                        r_bit_index <= r_bit_index + 1'b1;
                    end else begin
                        o_busy <= 1'b0;
                        o_tx <= 1'b1;  
                    end
                end
            end
        end
    end
endmodule
