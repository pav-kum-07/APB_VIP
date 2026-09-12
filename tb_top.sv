// ==============================================================================
// File Name  : tb_top.sv
// Description: Top-level Testbench Module for APB UVM VIP Verification.
// ==============================================================================

`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

// Include Physical Interface (Outside Package)
`include "apb_if.sv"

// Include DUT
`include "apb_slave_dut.sv"

// --------------------------------------------------------------------------
// VIP Package Inclusion & Import
// ISSUE RESOLUTION (VRFC 10-2989 / VRFC 10-8530):
// When IDE background linters or single-file analyzers compile `tb_top.sv`
// in isolation, `apb_pkg` is undefined unless explicitly included.
// By including `apb_pkg.sv` (which is protected by header guards `ifndef APB_PKG_SV),
// both single-file linting and multi-file project elaboration work seamlessly.
// --------------------------------------------------------------------------
`include "apb_pkg.sv"
import apb_pkg::*;

module tb_top;

    // --------------------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------------------
    localparam int ADDR_WIDTH = 32;
    localparam int DATA_WIDTH = 32;

    // --------------------------------------------------------------------------
    // Clock & Reset Generation
    // --------------------------------------------------------------------------
    logic pclk;
    logic presetn;

    // 100 MHz Clock (10ns period)
    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk;
    end

    // Active-Low Reset Pulse (Asserted for 20ns)
    initial begin
        presetn = 0;
        #20 presetn = 1;
    end

    // --------------------------------------------------------------------------
    // Interface & DUT Instantiation
    // --------------------------------------------------------------------------
    apb_if #(ADDR_WIDTH, DATA_WIDTH) vif (
        .pclk    (pclk),
        .presetn (presetn)
    );

    apb_slave_dut #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) dut (
        .pclk    (vif.pclk),
        .presetn (vif.presetn),
        .paddr   (vif.paddr),
        .psel    (vif.psel),
        .penable (vif.penable),
        .pwrite  (vif.pwrite),
        .pwdata  (vif.pwdata),
        .prdata  (vif.prdata),
        .pready  (vif.pready),
        .pslverr (vif.pslverr)
    );

    // --------------------------------------------------------------------------
    // UVM Test Execution & Virtual Interface Registration
    // --------------------------------------------------------------------------
    initial begin
        string test_name;
        // Set virtual interface in UVM Config DB for the VIP
        uvm_config_db#(virtual apb_if #(ADDR_WIDTH, DATA_WIDTH))::set(
            null, "*", "vif", vif
        );

        // Run test from command line if specified, else run apb_random_test
        if ($value$plusargs("TESTNAME=%s", test_name)) begin
            run_test(test_name);
        end else begin
            run_test("apb_random_test");
        end
    end

endmodule
