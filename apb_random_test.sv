`ifndef APB_RANDOM_TEST_SV
`define APB_RANDOM_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "apb_test.sv"
`include "apb_random_seq.sv"

class apb_random_test extends apb_test;

    `uvm_component_utils(apb_random_test)

    function new(string name = "apb_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_random_seq #(ADDR_WIDTH, DATA_WIDTH) seq;
        
        phase.raise_objection(this, "starting random test");

        seq = apb_random_seq #(ADDR_WIDTH, DATA_WIDTH)::type_id::create("seq");
        `uvm_info("RANDOM_TEST", $sformatf("Starting random test, NUM_TRANS: %0d", seq.num_transactions), UVM_LOW);
        seq.start(env.agent.sqr);

        phase.drop_objection(this, "completed random test");
    endtask

endclass
`endif
