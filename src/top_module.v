/*-----------------------------------------------------------------------------------------------
Project: FPGA Alarm System
Author: Mihai Florea
Design: top_module.v
Description: Top-level integration. Features modular RTL design, Connects Debouncers, PIN Logic, 
             Display Driver and UART Transmitter.
-----------------------------------------------------------------------------------------------*/

module top_module(
    input wire clk,
    input wire btnR, btnL, btnD, // Reset, Set, Confirm
    input wire [3:0] sw,
    output wire [3:0] an,
    output wire [6:0] seg,
    output wire uart_tx_out
);
    
    // Timing Parameter 
    parameter DEBOUNCE_LIMIT = 16'hFFFF;

    // Internal Wires
    wire [3:0] w_stored_pin;
    wire [2:0] w_system_status;
    wire w_deb_L, w_deb_D, w_deb_R;
    wire w_pulse_L, w_pulse_R, w_pulse_D;
    
    reg r_uart_trigger;
    
    // 1. Input Conditioning ( Debounce + Edge Detect )
    debouncer #(.COUNT_MAX(DEBOUNCE_LIMIT)) dbL(.i_clk(clk), .i_btn(btnL), .o_stable_btn(w_deb_L));
    one_pulse opL(.i_clk(clk), .i_signal(w_deb_L), .o_pulse(w_pulse_L));
    
    debouncer #(.COUNT_MAX(DEBOUNCE_LIMIT)) dbD(.i_clk(clk), .i_btn(btnD), .o_stable_btn(w_deb_D));
    one_pulse opD(.i_clk(clk), .i_signal(w_deb_D), .o_pulse(w_pulse_D));
    
    debouncer #(.COUNT_MAX(DEBOUNCE_LIMIT)) dbR(.i_clk(clk), .i_btn(btnR), .o_stable_btn(w_deb_R));
    one_pulse opR(.i_clk(clk), .i_signal(w_deb_R), .o_pulse(w_pulse_R));
    
    // 2. Logic Modules
    pin_register master_pin_reg(
         .i_clk(clk), 
         .i_rst(w_pulse_R), 
         .i_load_en(w_pulse_L), 
         .i_sw_val(sw), 
         .o_stored_pin(w_stored_pin));
         
    pin_verifier core_logic(
         .i_clk(clk), 
         .i_rst(w_pulse_R), 
         .i_user_pin(sw), 
         .i_stored_pin(w_stored_pin), 
         .i_valid_pulse(w_pulse_D), 
         .o_system_state(w_system_status)); 
    
    // 3. Output Peripherals
    display_driver display_unit(
         .i_clk(clk), 
         .i_rst(w_pulse_R), 
         .i_status(w_system_status), 
         .o_anode(an), 
         .o_seg(seg));
    
    always @(posedge clk) r_uart_trigger <= w_pulse_D;
    
    uart_string_sender uart_logger(
         .i_clk(clk),
         .i_rst(w_pulse_R), 
         .i_status(w_system_status),
         .i_trigger(r_uart_trigger),
         .o_tx(uart_tx_out),
         .o_busy());
    
endmodule