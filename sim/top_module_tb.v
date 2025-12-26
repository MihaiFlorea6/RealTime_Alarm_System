/*--------------------------------------------------------------------
Project: FPGA Alarm System
Author: Mihai Florea
Design: top_module_tb.v
Description: Testbench for the complete Alarm System.
             Simulates: Power-on reset, PIN storage,
             failed attempts and successful access.
--------------------------------------------------------------------*/

`timescale 1ns / 1ps

module top_module_tb();

   // 1. Clock and Signal Definitions
   reg r_clk;
   reg r_btnR, r_btnL, r_btnD;
   reg [3:0] r_sw;
   wire [3:0] w_an;
   wire [6:0] w_seg;
   wire w_uart_tx;

   // Internal State Monitor (Hierarchy Access)
   // We access the internal FSM state to verifiy logic accuracy
   wire [2:0] w_fsm_state = dut.core_logic.o_system_state;
   
   // 2. DUT Instantiation
   top_module dut(
       .clk(r_clk),
       .btnR(r_btnR),
       .btnL(r_btnL),
       .btnD(r_btnD),
       .sw(r_sw),
       .an(w_an),
       .seg(w_seg),
       .uart_tx_out(w_uart_tx));
       
   // 3. Clock Generation (100MHz -> 10ns period)
   always #5 r_clk = ~r_clk;
   
   // 4. Verification Task
   task check_status(input [2:0] expected_val, input [127:0] test_name);
       begin
         #50; // Wait for logic and debouncers to settle
         if (w_fsm_state === expected_val) begin
             $display("[PASS] %s | State: %b" , test_name, w_fsm_state);
         end else begin
             $display("[FAIL] %s | Expected: %b, Got: %b", test_name, expected_val, w_fsm_state);    
             $finish; // Stop simulation on critical failure
         end
       end
   endtask          
   
   // 5. Stimulus Procedure
   initial begin
       // Initialize Inputs
       r_clk = 0;
       r_btnR = 0; r_btnL = 0; r_btnD = 0;
       r_sw = 4'b0000;
       
       $display("STARTING AUTOMATED VERIFICATION...");
       
       // Step 1: System Reset
       $display("Starting Reset");
       r_btnR = 1; #100; r_btnR = 0; 
       #200;
       check_status(3'b000, "Initial Reset Check");
       
       // Step 2: Set Master PIN to 4'b1010 (10)
       r_sw = 4'b1010;
       r_btnL = 1; #100; r_btnL = 0; 
       #200;
       $display("[INFO] Setting Master PIN to 1010");
       
       // Step 3: Attempt Wrong PIN (4'b0001)
       r_sw = 4'b0001;
       r_btnD = 1; #100; r_btnD = 0; 
       #200;
       check_status(3'b010, "First Wrong Pin Check");
       
       // Step 4: Attempt Correct PIN (4'b1010)
       r_sw = 4'b1010;
       r_btnD = 1; #100; r_btnD = 0; 
       #200;
       check_status(3'b001, "Correct PIN Access Check");
       
       $display("VERIFICATION COMPLETE: ALL TESTS PASSED");
       $finish;
   end                
       

endmodule