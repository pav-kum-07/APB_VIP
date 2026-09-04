// ==============================================================================
// File Name  : apb_scoreboard.sv
// Description: APB Scoreboard / Reference Model for APB UVM VIP.
//
// ROLE OF THE SCOREBOARD:
// Passive verification component that subscribes to transaction items sent by the
// APB Monitor via TLM analysis port. Maintains an internal reference memory model
// (associative array) to verify data integrity:
//   - APB_WRITE : Stores written data into reference memory: mem[addr] = data
//   - APB_READ  : Compares sampled read data against stored expected data in mem[addr]
// ==============================================================================

`ifndef APB_SCOREBOARD_SV
`define APB_SCOREBOARD_SV

// Include standard UVM macros header file
`include "uvm_macros.svh"

// Import official UVM package namespace
import uvm_pkg::*;

// Include sequence item payload dependency
`include "apb_seq_item.sv" 

// Parameterized Scoreboard Class extending uvm_scoreboard
class apb_scoreboard #(
    parameter int ADDR_WIDTH = 32,  // Configurable Address Width matching agent/driver
    parameter int DATA_WIDTH = 32   // Configurable Data Width matching agent/driver
) extends uvm_scoreboard;

    // --------------------------------------------------------------------------
    // Factory Registration for Parameterized Component
    // Enables creation via type_id::create() and factory overrides.
    // --------------------------------------------------------------------------
    `uvm_component_param_utils(apb_scoreboard #(ADDR_WIDTH, DATA_WIDTH))

    // --------------------------------------------------------------------------
    // TLM Analysis Export Implementation Port
    // Receives transaction items broadcasted by the APB Monitor.
    // --------------------------------------------------------------------------
    uvm_analysis_imp #(
        apb_seq_item #(ADDR_WIDTH, DATA_WIDTH), // Parameter 1: WHAT data is received (T)
        apb_scoreboard #(ADDR_WIDTH, DATA_WIDTH) // Parameter 2: WHO implements the write() method (IMP)
    ) item_collected_export;
    
    // --------------------------------------------------------------------------
    // Reference Memory Model
    // Associative array mapping memory addresses to expected data payloads.
    // Dynamic array lookup enables sparse memory testing without pre-allocating full 4GB space.
    // --------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] mem [logic [ADDR_WIDTH-1:0]];

    // --------------------------------------------------------------------------
    // Constructor
    // Required for all UVM components inheriting from uvm_component/uvm_scoreboard.
    // --------------------------------------------------------------------------
    function new(string name = "apb_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // --------------------------------------------------------------------------
    // Build Phase
    // Instantiates the TLM analysis export port using new().
    // --------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_collected_export = new("item_collected_export", this);
    endfunction

    // --------------------------------------------------------------------------
    // TLM Write Implementation Method
    // Automatically invoked whenever the APB Monitor calls item_collect_port.write(item).
    // Performs reference memory updates and data integrity checks.
    // --------------------------------------------------------------------------
    virtual function void write(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH) item);
        
        // Case 1: Handle Slave Error Response
        if (item.pslverr) begin
            `uvm_info("SCB_ERR", $sformatf("Slave Error response detected on Addr: 0x%08h | Op: %s", 
                      item.addr, item.op.name()), UVM_MEDIUM)
        end
        
        // Case 2: Handle Write Transaction
        else if (item.op == APB_WRITE) begin
            mem[item.addr] = item.data;
            `uvm_info("SCB_WRITE", $sformatf("WRITE STORED -> Addr: 0x%08h | Data: 0x%08h", 
                      item.addr, item.data), UVM_LOW)
        end
        
        // Case 3: Handle Read Transaction (Data Integrity Check)
        else if (item.op == APB_READ) begin
            if (mem.exists(item.addr)) begin
                // Compare hardware read data against expected value stored in reference memory
                if (item.data == mem[item.addr]) begin
                    `uvm_info("SCB_READ_PASS", $sformatf("READ MATCH [PASS] -> Addr: 0x%08h | Read Data: 0x%08h == Expected: 0x%08h", 
                              item.addr, item.data, mem[item.addr]), UVM_LOW)
                end else begin
                    `uvm_error("SCB_READ_FAIL", $sformatf("READ MISMATCH [FAIL] -> Addr: 0x%08h | Read Data: 0x%08h != Expected: 0x%08h", 
                               item.addr, item.data, mem[item.addr]))
                end
            end else begin
                `uvm_warning("SCB_READ_UNWRITTEN", $sformatf("Read from unwritten address 0x%08h | Read Data: 0x%08h", 
                             item.addr, item.data))
            end
        end

    endfunction

endclass

`endif // APB_SCOREBOARD_SV