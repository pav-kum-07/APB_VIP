// ==============================================================================
// File Name  : apb_rw_e.sv
// Description: APB Transfer Type Enumeration for APB UVM VIP.
//
// WHY STEP 1 IS ENUMS:
// Every component in the VIP (Sequence Item, Driver, Monitor, Coverage) needs a
// clean, human-readable way to specify transfer direction without using raw numbers.
//
// HARDWARE MAPPING:
// - APB_READ  = 1'b0 -> Maps directly to hardware PWRITE = 0 (Read from Slave)
// - APB_WRITE = 1'b1 -> Maps directly to hardware PWRITE = 1 (Write to Slave)
// ==============================================================================

`ifndef APB_RW_E_SV
`define APB_RW_E_SV

// Include Guard (`ifndef / `define): Prevents multiple redefinition compiler errors
// if apb_rw_e.sv is included by multiple files in the testbench.

typedef enum logic {
    APB_READ  = 1'b0,  // Deasserts PWRITE pin (Read transaction payload)
    APB_WRITE = 1'b1   // Asserts PWRITE pin (Write transaction payload)
} apb_rw_e;

`endif // APB_RW_E_SV
