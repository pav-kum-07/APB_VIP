// ==============================================================================
// File Name  : apb_pkg.sv
// Description: APB UVM Verification IP Package.
// ==============================================================================

`ifndef APB_PKG_SV
`define APB_PKG_SV

// Include standard UVM macros before package declaration
`include "uvm_macros.svh"

package apb_pkg;

    // Import UVM base class library namespace
    import uvm_pkg::*;

    // --------------------------------------------------------------------------
    // 1. Types & Transactions
    // --------------------------------------------------------------------------
    `include "apb_rw_e.sv"
    `include "apb_seq_item.sv"

    // --------------------------------------------------------------------------
    // 2. Verification Components (Agent Level)
    // --------------------------------------------------------------------------
    `include "apb_sequencer.sv"
    `include "apb_driver.sv"
    `include "apb_monitor.sv"
    `include "apb_agent.sv"

    // --------------------------------------------------------------------------
    // 3. Analysis & Environment Components
    // --------------------------------------------------------------------------
    `include "apb_scoreboard.sv"
    `include "apb_coverage.sv"
    `include "apb_env.sv"

    // --------------------------------------------------------------------------
    // 4. Stimulus Sequences
    // --------------------------------------------------------------------------
    `include "apb_base_seq.sv"
    `include "apb_write_read_seq.sv"

    // --------------------------------------------------------------------------
    // 5. Test Library
    // --------------------------------------------------------------------------
    `include "apb_test.sv"
    `include "apb_write_read_test.sv"

endpackage : apb_pkg

`endif // APB_PKG_SV
