// ==============================================================================
// File Name  : apb_agent.sv
// Description: APB Agent Component for APB UVM VIP.
//
// ROLE OF THE AGENT:
// Encapsulates the APB Sequencer, Driver, and Monitor components into a single,
// reusable verification unit. Manages component instantiation based on the
// Active/Passive mode setting (is_active).
//
// ACTIVE MODE  : Instantiates Sequencer, Driver, and Monitor.
// PASSIVE MODE : Instantiates Monitor ONLY (used for passive bus eavesdropping).
// ==============================================================================

`ifndef APB_AGENT_SV
`define APB_AGENT_SV

// Include standard UVM macros header file
`include "uvm_macros.svh"

// Import official UVM package namespace
import uvm_pkg::*;

// Include protocol definition dependencies
`include "apb_rw_e.sv"
`include "apb_seq_item.sv"
`include "apb_sequencer.sv"
`include "apb_driver.sv"
`include "apb_monitor.sv"

// Parameterized Class Definition extending uvm_agent
class apb_agent #(
    parameter int ADDR_WIDTH = 32,  // Configurable Address Bus Width (Default: 32-bit)
    parameter int DATA_WIDTH = 32   // Configurable Data Bus Width (Default: 32-bit)
) extends uvm_agent;

    // --------------------------------------------------------------------------
    // Factory Registration for Parameterized Component
    // Enables creation via type_id::create() and factory overrides.
    // --------------------------------------------------------------------------
    `uvm_component_param_utils(apb_agent #(ADDR_WIDTH, DATA_WIDTH))

    // --------------------------------------------------------------------------
    // Sub-Component Handles
    // --------------------------------------------------------------------------
    apb_driver    #(ADDR_WIDTH, DATA_WIDTH) drv;  // Master Driver handle
    apb_sequencer #(ADDR_WIDTH, DATA_WIDTH) sqr;  // Sequencer handle
    apb_monitor   #(ADDR_WIDTH, DATA_WIDTH) mon;  // Bus Monitor handle

    // --------------------------------------------------------------------------
    // TLM Analysis Port
    // Exported at the Agent boundary to pass monitored transactions to Scoreboard/Coverage.
    // --------------------------------------------------------------------------
    uvm_analysis_port #(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH)) item_collected_port;

    // --------------------------------------------------------------------------
    // Constructor
    // Required for all UVM components inheriting from uvm_component/uvm_agent.
    // --------------------------------------------------------------------------
    function new(string name = "apb_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // --------------------------------------------------------------------------
    // Build Phase
    // Instantiates sub-components using factory type_id::create().
    // - Monitor & Analysis Port are ALWAYS created.
    // - Driver & Sequencer are created ONLY if is_active == UVM_ACTIVE.
    // --------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Instantiate Agent-level TLM analysis port
        item_collected_port = new("item_collected_port", this);

        // Monitor is ALWAYS instantiated (Active and Passive modes)
        mon = apb_monitor #(ADDR_WIDTH, DATA_WIDTH)::type_id::create("mon", this);

        // Conditional instantiation based on is_active setting
        if (is_active == UVM_ACTIVE) begin
            `uvm_info("AGENT_BUILD", "Agent is active: creating sequencer and driver", UVM_LOW)
            sqr = apb_sequencer #(ADDR_WIDTH, DATA_WIDTH)::type_id::create("sqr", this);
            drv = apb_driver    #(ADDR_WIDTH, DATA_WIDTH)::type_id::create("drv", this);
        end
    endfunction

    // --------------------------------------------------------------------------
    // Connect Phase
    // Establishes TLM connections between sub-components:
    // 1. Driver TLM seq_item_port -> Sequencer seq_item_export (if Active)
    // 2. Monitor TLM item_collect_port -> Agent item_collected_port (always)
    // --------------------------------------------------------------------------
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect Driver to Sequencer if Active
        if (is_active == UVM_ACTIVE) begin
            `uvm_info("AGENT_CONNECT", "Agent is active: connecting sequencer and driver", UVM_LOW)
            drv.seq_item_port.connect(sqr.seq_item_export);
        end

        // Connect Monitor TLM output port to Agent TLM analysis port
        mon.item_collect_port.connect(item_collected_port);
    endfunction

endclass

`endif // APB_AGENT_SV


