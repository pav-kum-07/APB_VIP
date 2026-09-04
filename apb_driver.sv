// ==============================================================================
// File Name  : apb_driver.sv
// Description: APB Master Driver Component for APB UVM VIP.
//              Inherits from uvm_driver #(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH)).
//
// ROLE OF THE DRIVER:
// Receives high-level transaction payloads (apb_seq_item) from the sequencer via
// TLM seq_item_port, and executes the exact 2-Phase AMBA APB timing protocol
// handshake on physical interface pins:
//
//   1. IDLE Phase   : PSEL = 0, PENABLE = 0
//   2. SETUP Phase  : PSEL = 1, PENABLE = 0 (Drives PADDR, PWRITE, PWDATA)
//   3. ACCESS Phase : PSEL = 1, PENABLE = 1 (Waits for PREADY = 1)
// ==============================================================================

`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV

// Include standard UVM macros header file
`include "uvm_macros.svh"

// Import official UVM package namespace
import uvm_pkg::*;

// Include Sequence Item payload
`include "apb_seq_item.sv"    

class apb_driver #(
    parameter int ADDR_WIDTH = 32,  // Configurable Address Width matching transaction
    parameter int DATA_WIDTH = 32   // Configurable Data Width matching transaction
) extends uvm_driver #(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH));

    // --------------------------------------------------------------------------
    // Virtual Interface Handle
    // Declared with `.DRIVER` modport to access clocking block (vif.cb_driver)
    // --------------------------------------------------------------------------
    virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif;

    // UVM Factory Registration Macro for Parameterized Component
    `uvm_component_param_utils(apb_driver #(ADDR_WIDTH, DATA_WIDTH))

    // --------------------------------------------------------------------------
    // Constructor
    // Required for all UVM components inheriting from uvm_driver
    // --------------------------------------------------------------------------
    function new (string name = "apb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // --------------------------------------------------------------------------
    // Build Phase
    // Retrieves the virtual interface handle from uvm_config_db using key "vif"
    // --------------------------------------------------------------------------
    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual apb_if #(ADDR_WIDTH, DATA_WIDTH))::get(this, "", "vif", vif))
            `uvm_fatal("DRV_BUILD", "Did NOT get interface handle 'vif' from config_db!")
        else
            `uvm_info("DRV_BUILD", "Successfully retrieved interface handle 'vif' from config_db", UVM_LOW)
    endfunction

    // --------------------------------------------------------------------------
    // Run Phase: Main Fetch-and-Execute Loop
    // Continuously fetches sequence items from sequencer and executes transfers.
    // --------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        // Initialize physical APB bus wires to IDLE state
        reset_bus();
        
        // Driver Loop
        forever begin
            // Fetch next item payload from sequencer
            seq_item_port.get_next_item(req);
            
            // Execute 2-Phase APB transfer on physical pins
            drive_transfer(req);
            
            // Handshake back to sequencer indicating transfer completion
            seq_item_port.item_done();
        end
    endtask

    // --------------------------------------------------------------------------
    // Helper Task: Resets APB Bus Wires to IDLE state (PSEL=0, PENABLE=0)
    // --------------------------------------------------------------------------
    virtual task reset_bus();
        @(vif.cb_driver);
        vif.cb_driver.paddr     <= '0;
        vif.cb_driver.psel      <= '0;
        vif.cb_driver.penable   <= '0;
        vif.cb_driver.pwrite    <= '0;
        vif.cb_driver.pwdata    <= '0;
    endtask 

    // --------------------------------------------------------------------------
    // Core Task: Executes 2-Phase APB Protocol Transfer Handshake
    // --------------------------------------------------------------------------
    virtual task drive_transfer(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH) req);
        
        // ----------------------------------------------------------------------
        // PHASE 1: SETUP PHASE (Cycle 1)
        // Assert PSEL=1, PENABLE=0, and drive Target Address, Operation & Write Data.
        // ----------------------------------------------------------------------
        @(vif.cb_driver);
        vif.cb_driver.paddr     <= req.addr;
        vif.cb_driver.psel      <= 1'b1;
        vif.cb_driver.penable   <= 1'b0;
        vif.cb_driver.pwrite    <= req.op;
        if (req.op == APB_WRITE) begin
            vif.cb_driver.pwdata <= req.data;
        end

        // ----------------------------------------------------------------------
        // PHASE 2: ACCESS PHASE (Cycle 2)
        // Assert PENABLE=1 strobe signal on the next clocking block edge.
        // ----------------------------------------------------------------------
        @(vif.cb_driver);
        vif.cb_driver.penable   <= 1'b1;

        // ----------------------------------------------------------------------
        // PHASE 3: WAIT STATE HANDSHAKE LOOP
        // Hold PENABLE=1 while the Slave asserts PREADY=0 (slave wait state).
        // ----------------------------------------------------------------------
        while (vif.cb_driver.pready === 1'b0) begin
            @(vif.cb_driver);
        end

        // ----------------------------------------------------------------------
        // PHASE 4: SAMPLE SLAVE OUTPUT RESPONSES
        // Capture PRDATA (if Read transaction) and PSLVERR before transfer ends.
        // ----------------------------------------------------------------------
        if (req.op == APB_READ) begin
            req.data = vif.cb_driver.prdata;
        end
        req.pslverr = vif.cb_driver.pslverr;        

        // ----------------------------------------------------------------------
        // PHASE 5: RETURN BUS TO IDLE STATE
        // Deassert PSEL=0 and PENABLE=0.
        // ----------------------------------------------------------------------
        vif.cb_driver.psel      <= 1'b0;
        vif.cb_driver.penable   <= 1'b0;

        if (vif.cb_driver.pslverr)
            `uvm_warning("DRV_TRANSFER", "Slave error response detected!")
    endtask 

endclass

`endif // APB_DRIVER_SV