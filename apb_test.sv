// ==============================================================================
// File Name  : apb_test.sv
// Description: APB Base Test Component for APB UVM VIP.
//
// ROLE OF THE TEST:
// The apb_test is the top-level test component in the UVM hierarchy.
// Executed directly via +UVM_TESTNAME=apb_test from the simulator command line.
//
// Responsibilities:
//   1. Instantiates the verification environment (apb_env) during build_phase.
//   2. Prints the complete UVM component topology during end_of_elaboration_phase.
//   3. Controls simulation execution in run_phase using UVM objections (raise/drop).
//   4. Instantiates and launches the stimulus sequence on the APB sequencer (sqr).
// ==============================================================================

`ifndef APB_TEST_SV
`define APB_TEST_SV

// Include standard UVM macros header file
`include "uvm_macros.svh"

// Import official UVM package namespace
import uvm_pkg::*;

// Include verification environment and stimulus sequence dependencies
`include "apb_env.sv"
`include "apb_base_seq.sv"

// --------------------------------------------------------------------------
// APB Base Test Class Definition extending uvm_test
// --------------------------------------------------------------------------
class apb_test extends uvm_test;

    // --------------------------------------------------------------------------
    // Bus Width Parameters (Local to this test configuration)
    // --------------------------------------------------------------------------
    localparam int ADDR_WIDTH = 32;  // Address bus width (32-bit default)
    localparam int DATA_WIDTH = 32;  // Data bus width    (32-bit default)

    // --------------------------------------------------------------------------
    // Top-Level Environment Handle
    // --------------------------------------------------------------------------
    apb_env #(ADDR_WIDTH, DATA_WIDTH) env;

    // --------------------------------------------------------------------------
    // Factory Registration Macro
    // Registers apb_test with the UVM factory to allow +UVM_TESTNAME selection.
    // --------------------------------------------------------------------------
    `uvm_component_utils(apb_test)

    // --------------------------------------------------------------------------
    // Constructor
    // Required for all UVM components inheriting from uvm_component/uvm_test.
    // --------------------------------------------------------------------------
    function new(string name = "apb_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // --------------------------------------------------------------------------
    // Build Phase
    // Instantiates the top-level apb_env using the UVM factory.
    // --------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = apb_env #(ADDR_WIDTH, DATA_WIDTH)::type_id::create("env", this);
    endfunction

    // --------------------------------------------------------------------------
    // End of Elaboration Phase
    // Called after all components are built and connected.
    // Prints the full UVM component tree and port connections for debug verification.
    // --------------------------------------------------------------------------
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TEST", "Printing UVM Topology Hierarchy:", UVM_LOW)
        uvm_top.print_topology();
    endfunction

    // --------------------------------------------------------------------------
    // Run Phase: Test Stimulus Execution & Objection Management
    // --------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        apb_base_seq #(ADDR_WIDTH, DATA_WIDTH) seq;
        super.run_phase(phase);

        // Raise objection to prevent the simulation from terminating prematurely
        phase.raise_objection(this, "Starting APB Base Test");

        // Instantiate stimulus sequence via UVM factory (uvm_object: no parent argument)
        seq = apb_base_seq #(ADDR_WIDTH, DATA_WIDTH)::type_id::create("seq");

        // Start sequence execution targeted at the APB Agent's sequencer
        seq.start(env.agent.sqr);

        // Drop objection to allow UVM phase to complete and finish simulation
        phase.drop_objection(this, "Dropping objection after test completion");
    endtask

endclass

`endif // APB_TEST_SV
