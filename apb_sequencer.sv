// ==============================================================================
// File Name  : apb_sequencer.sv
// Description: APB Sequencer Component for APB UVM VIP.
//
// ROLE OF THE SEQUENCER:
// Acts as the middleman / traffic controller between UVM Sequences (generating
// transactions) and the APB Driver (driving physical pins). Manages sequence item
// arbitration and feeds items to the driver via TLM seq_item_port.
// ==============================================================================

`ifndef APB_SEQUENCER_SV
`define APB_SEQUENCER_SV

// Include standard UVM macros header file
`include "uvm_macros.svh"

// Import official UVM package namespace
import uvm_pkg::*;

// Include Sequence Item Payload definition
`include "apb_seq_item.sv"

// Parameterized Class Definition extending uvm_sequencer
class apb_sequencer #(
    parameter int ADDR_WIDTH = 32,  // Address Bus Width (matching sequence item)
    parameter int DATA_WIDTH = 32   // Data Bus Width (matching sequence item)
) extends uvm_sequencer #(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH));

    // UVM Factory Registration for Parameterized Component
    `uvm_component_param_utils(apb_sequencer #(ADDR_WIDTH, DATA_WIDTH))

    // Constructor: Passes instance name and parent component handle to uvm_component
    function new(string name = "apb_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

`endif // APB_SEQUENCER_SV