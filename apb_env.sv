// ==============================================================================
// File Name  : apb_env.sv
// Description: APB UVM Environment – Top-Level Verification Container.
//
// ROLE OF THE ENVIRONMENT:
// The apb_env is the top-level UVM environment that instantiates and wires
// together the three core verification sub-components of this APB VIP:
//   1. apb_agent      – Active agent containing the Sequencer, Driver, and Monitor.
//   2. apb_scoreboard – Reference model that checks data integrity on reads.
//   3. apb_coverage   – Functional coverage collector driven by monitored transactions.
//
// The environment follows the standard UVM build–connect topology:
//   build_phase  : Creates all sub-components via the UVM factory.
//   connect_phase: Wires the Monitor's TLM analysis port to the Scoreboard and
//                  Coverage collector so every sampled bus transaction is
//                  automatically forwarded for checking and coverage collection.
//
// TOPOLOGY DIAGRAM:
//
//   ┌─────────────────────────────────────────────────────────┐
//   │                       apb_env                           │
//   │                                                         │
//   │  ┌────────────────────────────┐                         │
//   │  │        apb_agent           │                         │
//   │  │  ┌──────────┐ ┌─────────┐ │   TLM     ┌──────────┐ │
//   │  │  │ Sequencer│→│ Driver  │ │──────────→│Scoreboard│ │
//   │  │  └──────────┘ └─────────┘ │ analysis  └──────────┘ │
//   │  │  ┌──────────┐             │  port      ┌─────────┐ │
//   │  │  │ Monitor  │─────────────│──────────→│Coverage │ │
//   │  │  └──────────┘             │            └─────────┘ │
//   │  └────────────────────────────┘                         │
//   └─────────────────────────────────────────────────────────┘
// ==============================================================================

`ifndef APB_ENV_SV
`define APB_ENV_SV

// Include standard UVM macros header file
`include "uvm_macros.svh"

// Import official UVM package namespace
import uvm_pkg::*;

// Include sub-component dependencies
`include "apb_agent.sv"       // APB Agent (Sequencer + Driver + Monitor)
`include "apb_scoreboard.sv"  // APB Scoreboard (Reference Memory Model)
`include "apb_coverage.sv"    // APB Functional Coverage Collector

// --------------------------------------------------------------------------
// Parameterized Environment Class
// Parameters propagate down to all sub-components so the entire VIP can be
// re-configured for different APB bus widths without source-code changes.
// --------------------------------------------------------------------------
class apb_env #(
    parameter ADDR_WIDTH = 32,  // Configurable Address Bus Width (Default: 32-bit)
    parameter DATA_WIDTH = 32   // Configurable Data Bus Width    (Default: 32-bit)
) extends uvm_env;

    // --------------------------------------------------------------------------
    // Sub-Component Handles
    // Declared as parameterized types so widths stay consistent across the VIP.
    // --------------------------------------------------------------------------
    apb_agent      #(ADDR_WIDTH, DATA_WIDTH) agent;  // Active agent (Seq + Drv + Mon)
    apb_scoreboard #(ADDR_WIDTH, DATA_WIDTH) scb;    // Scoreboard reference model
    apb_coverage   #(ADDR_WIDTH, DATA_WIDTH) cov;    // Functional coverage collector

    // --------------------------------------------------------------------------
    // Factory Registration for Parameterized Component
    // Enables creation via type_id::create() and factory overrides.
    // --------------------------------------------------------------------------
    `uvm_component_param_utils(apb_env #(ADDR_WIDTH, DATA_WIDTH))

    // --------------------------------------------------------------------------
    // Constructor
    // Required for all UVM components inheriting from uvm_env / uvm_component.
    // --------------------------------------------------------------------------
    function new(string name = "apb_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // --------------------------------------------------------------------------
    // Build Phase
    // Instantiates all three sub-components using the UVM factory.
    // The factory allows any of these types to be overridden at test-level
    // without modifying this environment source.
    // --------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create active APB agent (contains Sequencer, Driver, and Monitor)
        agent = apb_agent #(ADDR_WIDTH, DATA_WIDTH)::type_id::create("agent", this);

        // Create scoreboard for data-integrity checking (write-store / read-compare)
        scb = apb_scoreboard #(ADDR_WIDTH, DATA_WIDTH)::type_id::create("scb", this);

        // Create functional coverage collector for protocol metric tracking
        cov = apb_coverage #(ADDR_WIDTH, DATA_WIDTH)::type_id::create("cov", this);
    endfunction

    // --------------------------------------------------------------------------
    // Connect Phase
    // Wires the Monitor's TLM analysis port to both the Scoreboard and Coverage
    // collector.  After this phase, every transaction sampled by the Monitor is
    // automatically broadcast to both subscribers for passive checking and
    // coverage collection.
    //
    // Connection Topology:
    //   Monitor.item_collected_port ──→ Scoreboard.item_collected_port  (analysis imp)
    //   Monitor.item_collected_port ──→ Coverage.item_collected_port    (analysis export)
    // --------------------------------------------------------------------------
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Forward monitored transactions to the scoreboard for data-integrity checks
        agent.item_collected_port.connect(scb.item_collected_export);

        // Forward monitored transactions to the coverage collector for metric sampling
        agent.item_collected_port.connect(cov.analysis_export);
    endfunction

endclass

`endif // APB_ENV_SV