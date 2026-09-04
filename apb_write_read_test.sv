// ==============================================================================
// File Name  : apb_write_read_test.sv
// Description: APB Write-Read Verification Test for APB UVM VIP.
// ==============================================================================

`ifndef APB_WRITE_READ_TEST_SV
`define APB_WRITE_READ_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "apb_test.sv"
`include "apb_write_read_seq.sv"

class apb_write_read_test extends apb_test;

    // Factory Registration Macro
    `uvm_component_utils(apb_write_read_test)

    // Constructor
    function new(string name = "apb_write_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Run Phase: Launch Write-Read Sequence
    virtual task run_phase(uvm_phase phase);
        apb_write_read_seq #(ADDR_WIDTH, DATA_WIDTH) wr_rd_seq;

        // Raise objection to keep simulation alive
        phase.raise_objection(this, "Starting APB Write Read Test");

        `uvm_info("TEST", "Executing apb_write_read_test...", UVM_LOW)

        // Create and start sequence
        wr_rd_seq = apb_write_read_seq #(ADDR_WIDTH, DATA_WIDTH)::type_id::create("wr_rd_seq");
        wr_rd_seq.start(env.agent.sqr);

        // Drop objection after completion
        phase.drop_objection(this, "Completed APB Write Read Test");
    endtask

endclass

`endif // APB_WRITE_READ_TEST_SV
