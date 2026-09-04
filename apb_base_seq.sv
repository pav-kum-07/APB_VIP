// ==============================================================================
// File Name  : apb_base_seq.sv
// Description: APB Base Sequence Object for APB UVM VIP.
//
// ROLE OF THE BASE SEQUENCE:
// Base class for all APB UVM Sequences. Extends uvm_sequence #(apb_seq_item).
// Provides reusable helper tasks (write() and read()) so child test sequences can
// easily drive APB transfers without repeating low-level start_item/finish_item boilerplate.
// ==============================================================================

`ifndef APB_BASE_SEQ_SV
`define APB_BASE_SEQ_SV

// Include standard UVM macros header file
`include "uvm_macros.svh"

// Import official UVM package namespace
import uvm_pkg::*;

// Include sequence item and enum dependencies
`include "apb_rw_e.sv"
`include "apb_seq_item.sv"

// Parameterized Base Sequence Class
class apb_base_seq #(
    parameter int ADDR_WIDTH = 32,  // Configurable Address Width matching agent/driver
    parameter int DATA_WIDTH = 32   // Configurable Data Width matching agent/driver
) extends uvm_sequence #(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH));

    // --------------------------------------------------------------------------
    // UVM Factory Registration Macro for Parameterized Object
    // Enables creation via type_id::create() and UVM factory overrides.
    // --------------------------------------------------------------------------
    `uvm_object_param_utils(apb_base_seq #(ADDR_WIDTH, DATA_WIDTH))

    // --------------------------------------------------------------------------
    // Constructor
    // Note: uvm_sequence inherits from uvm_object, which takes ONLY 'name'.
    // --------------------------------------------------------------------------
    function new(string name = "apb_base_seq");
        super.new(name);
    endfunction

    // --------------------------------------------------------------------------
    // Main Body Task
    // Automatically executed by UVM when seq.start(sequencer) is called.
    // Base implementation provides log message; child sequences override this.
    // --------------------------------------------------------------------------
    virtual task body();
        `uvm_info("BASE_SEQ", "Executing Base APB Sequence body", UVM_LOW)
    endtask

    // --------------------------------------------------------------------------
    // Helper Task: Perform APB Write Operation
    // Encapsulates standard UVM 4-step sequence-driver handshake:
    // 1. type_id::create() -> Instantiate new sequence item payload
    // 2. start_item()      -> Request driver availability from sequencer
    // 3. Populate payload   -> Set op = APB_WRITE, addr, and data
    // 4. finish_item()     -> Send item to driver and wait for execution completion
    // --------------------------------------------------------------------------
    virtual task write(
        input logic [ADDR_WIDTH-1:0] wr_addr, 
        input logic [DATA_WIDTH-1:0] wr_data
    );
        req = apb_seq_item #(ADDR_WIDTH, DATA_WIDTH)::type_id::create("req");
        start_item(req);
        req.op   = APB_WRITE;
        req.addr = wr_addr;
        req.data = wr_data;  // Payload data field (matching apb_seq_item.sv)
        finish_item(req);
    endtask

    // --------------------------------------------------------------------------
    // Helper Task: Perform APB Read Operation
    // Encapsulates standard UVM sequence-driver handshake for Read:
    // 1. type_id::create() -> Instantiate sequence item
    // 2. start_item()      -> Block until driver requests item
    // 3. Populate payload   -> Set op = APB_READ and target addr
    // 4. finish_item()     -> Wait for driver to sample bus prdata
    // 5. Sample result      -> Copy sampled req.data out to rd_data
    // --------------------------------------------------------------------------
    virtual task read(
        input logic [ADDR_WIDTH-1:0] rd_addr, 
        output logic [DATA_WIDTH-1:0] rd_data
    );
        req = apb_seq_item #(ADDR_WIDTH, DATA_WIDTH)::type_id::create("req");
        start_item(req);
        req.op   = APB_READ;
        req.addr = rd_addr;
        finish_item(req);
        rd_data  = req.data; // Capture read data sampled by driver
    endtask

endclass

`endif // APB_BASE_SEQ_SV
