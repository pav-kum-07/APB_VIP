// ==============================================================================
// File Name  : apb_coverage.sv
// Description: APB Functional Coverage Collector Component for APB UVM VIP.
//
// ROLE OF THE COVERAGE COLLECTOR:
// Passive verification component extending uvm_subscriber #(apb_seq_item).
// Connects to the APB Monitor via TLM analysis port. Automatically samples
// SystemVerilog covergroups on every bus transaction to measure functional coverage metrics:
//   1. Protocol Operation Coverage (APB_READ vs APB_WRITE)
//   2. Address Space Bins (Low, Mid, and High address ranges)
//   3. Slave Error Response Status (OK vs PSLVERR)
//   4. Cross Coverage (Operation Type x Address Range)
// ==============================================================================

`ifndef APB_COVERAGE_SV
`define APB_COVERAGE_SV

// Include standard UVM macros header file
`include "uvm_macros.svh"

// Import official UVM package namespace
import uvm_pkg::*;

// Include sequence item payload dependency
`include "apb_seq_item.sv"

// Parameterized Class Definition extending uvm_subscriber
class apb_coverage #(
    parameter int ADDR_WIDTH = 32,  // Configurable Address Bus Width (Default: 32-bit)
    parameter int DATA_WIDTH = 32   // Configurable Data Bus Width (Default: 32-bit)
) extends uvm_subscriber #(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH));

    // --------------------------------------------------------------------------
    // Factory Registration for Parameterized Component
    // Enables creation via type_id::create() and factory overrides.
    // --------------------------------------------------------------------------
    `uvm_component_param_utils(apb_coverage #(ADDR_WIDTH, DATA_WIDTH))

    // --------------------------------------------------------------------------
    // Transaction Handle for Covergroup Sampling
    // Holds the current sequence item payload passed to write().
    // --------------------------------------------------------------------------
    apb_seq_item #(ADDR_WIDTH, DATA_WIDTH) cov_item;

    // --------------------------------------------------------------------------
    // SystemVerilog Covergroup Definition
    // Defines explicit coverage goals (coverpoints, bins, cross-coverage).
    // --------------------------------------------------------------------------
    covergroup cg_apb;

        // Coverpoint 1: Protocol Operation Type (Read vs Write)
        cp_op: coverpoint cov_item.op {
            bins write = {APB_WRITE};  // Verifies APB Write operations were executed
            bins read  = {APB_READ};   // Verifies APB Read operations were executed
        }

        // Coverpoint 2: Target Address Space Partitioning
        cp_addr: coverpoint cov_item.addr {
            bins min_addr  = {32'h0000_0000};  // Base address boundary
            bins max_addr  = {32'h0000_03FC};  // Max address boundary
            bins inside_ram = {[32'h0000_0004 : 32'h0000_03F8]}; //Inside valid memory
            bins out_of_bound = {[32'h0000_0400 : 32'hFFFF_FFFF]}; //Illegal space (triggers PSLVERR)
        }

        // Coverpoint 3: Slave Response Error Status
        cp_pslverr: coverpoint cov_item.pslverr {
            bins ok_resp  = {1'b0};  // Normal OK response from Slave
            bins err_resp = {1'b1};  // Error response (PSLVERR=1) from Slave
        }

        // Cross Coverage 1: Verifies both Read and Write operations occurred across all address regions
        cr_op_addr: cross cp_op, cp_addr;

    endgroup

    // --------------------------------------------------------------------------
    // Constructor
    // Required for all UVM components inheriting from uvm_subscriber.
    // Instantiates the embedded covergroup cg_apb.
    // --------------------------------------------------------------------------
    function new(string name = "apb_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_apb = new();  // Instantiate covergroup instance
    endfunction

    // --------------------------------------------------------------------------
    // TLM Write Implementation Method
    // Automatically called whenever the APB Monitor broadcasts an item via analysis port.
    // Updates cov_item handle and triggers explicit covergroup sampling.
    // --------------------------------------------------------------------------
    virtual function void write(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH) t);
        cov_item = t;
        cg_apb.sample();  // Sample all coverpoints inside cg_apb
    endfunction

    // --------------------------------------------------------------------------
    // Report Phase
    // Prints functional coverage statistics at end of test.
    // --------------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COVERAGE", "==================================================", UVM_LOW)
        `uvm_info("COVERAGE", $sformatf("  TOTAL FUNCTIONAL COVERAGE = %0.2f%%", cg_apb.get_inst_coverage()), UVM_LOW)
        `uvm_info("COVERAGE", $sformatf("    * Operation (cp_op)      : %0.2f%%", cg_apb.cp_op.get_coverage()), UVM_LOW)
        `uvm_info("COVERAGE", $sformatf("    * Address (cp_addr)      : %0.2f%%", cg_apb.cp_addr.get_coverage()), UVM_LOW)
        `uvm_info("COVERAGE", $sformatf("    * Error Status (pslverr) : %0.2f%%", cg_apb.cp_pslverr.get_coverage()), UVM_LOW)
        `uvm_info("COVERAGE", $sformatf("    * Cross (op x addr)      : %0.2f%%", cg_apb.cr_op_addr.get_coverage()), UVM_LOW)
        `uvm_info("COVERAGE", "==================================================", UVM_LOW)
    endfunction

endclass

`endif // APB_COVERAGE_SV