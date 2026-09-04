// ==============================================================================
// File Name  : apb_seq_item.sv
// Description: APB Transaction Sequence Item Payload Object for APB UVM VIP.
//
// TRANSACTION-LEVEL MODELING (TLM) ARCHITECTURE:
// This object represents "WHAT to do" (High-Level Intent: Address, Data, Read/Write).
//
// WHY ARE PENABLE AND PSEL NOT DEFINED HERE?
// PENABLE and PSEL are low-level physical protocol control wires. They are managed
// 100% automatically by the APB Driver (apb_driver.sv) during the 2-phase APB timing
// state machine (SETUP Phase -> ACCESS Phase). Sequences never need to manually
// set PENABLE or PSEL!
// ==============================================================================

`ifndef APB_SEQ_ITEM_SV
`define APB_SEQ_ITEM_SV

// Include standard UVM macros header file
`include "uvm_macros.svh"

// Import official UVM package namespace
import uvm_pkg::*;

// Include Protocol Operation Enum (defines APB_READ=0, APB_WRITE=1)
`include "apb_rw_e.sv"

// Parameterized Class Definition extending uvm_sequence_item
class apb_seq_item #(
    parameter int ADDR_WIDTH = 32,  // Configurable Address Bus Width (Default: 32-bit)
    parameter int DATA_WIDTH = 32   // Configurable Data Bus Width (Default: 32-bit)
) extends uvm_sequence_item;

    // --------------------------------------------------------------------------
    // Transaction Control & Data Fields
    // --------------------------------------------------------------------------
    // `rand`: Allows UVM sequence to generate random values during item.randomize()
    rand logic [ADDR_WIDTH-1:0] addr;     // APB Target Memory Address Bus (32-bit)
    rand logic [DATA_WIDTH-1:0] data;     // APB Write Data payload OR Read Data result payload (32-bit)
    rand apb_rw_e               op;       // Transfer Direction: APB_READ (0) or APB_WRITE (1)
    
    // Non-`rand` response field: Populated by Driver AFTER sampling Slave output pins
    logic                       pslverr;  // APB Slave Error Response Status (1 = Error, 0 = OK)

    // --------------------------------------------------------------------------
    // UVM Field Automation Macros
    // Registers fields with the UVM Factory to enable built-in copy(), compare(),
    // print(), and pack()/unpack() methods.
    // --------------------------------------------------------------------------
    `uvm_object_param_utils_begin(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH))
        // `UVM_HEX`: Formats address in Hexadecimal ('ha0) in log files instead of decimal
        `uvm_field_int (addr,    UVM_DEFAULT | UVM_HEX)
        
        // `UVM_HEX`: Formats data payload in Hexadecimal ('hdeadbeef) for easy memory debugging
        `uvm_field_int (data,    UVM_DEFAULT | UVM_HEX)
        
        // `uvm_field_enum`: Dedicated macro for enum types (apb_rw_e).
        // Prints text labels "APB_WRITE" / "APB_READ" in logs instead of raw numbers.
        `uvm_field_enum(apb_rw_e, op, UVM_DEFAULT)
        
        // `pslverr`: Registered as standard UVM integer field
        `uvm_field_int (pslverr, UVM_DEFAULT)
    `uvm_object_utils_end

    // --------------------------------------------------------------------------
    // Hardware Protocol Alignment Constraints
    // --------------------------------------------------------------------------
    
    // Constraint 1: 32-bit Word Alignment (Lowest 2 bits of address MUST be 00)
    constraint c_word_aligned {
        addr[1:0] == 2'b00;
    }

    // Constraint 2: Restrict address range to valid RAM space (0x0000_0000 to 0x0000_03FF)
    constraint c_addr_range {
        soft addr inside {[32'h0000_0000 : 32'h0000_03FF]};
    }

    // --------------------------------------------------------------------------
    // Constructor
    // Required for all UVM objects inheriting from uvm_sequence_item.
    // --------------------------------------------------------------------------
    function new(string name = "apb_seq_item");
        super.new(name);
    endfunction

    // --------------------------------------------------------------------------
    // Custom String Formatting Helper for Log Messages
    // Formats transaction payload into clean text when printed in uvm_info logs.
    // --------------------------------------------------------------------------
    virtual function string convert2string();
        return $sformatf("op=%s | addr=0x%08h | data=0x%08h | pslverr=%0b",
                         op.name(), addr, data, pslverr);
    endfunction

endclass

`endif // APB_SEQ_ITEM_SV
