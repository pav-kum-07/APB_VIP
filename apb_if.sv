// ==============================================================================
// File Name  : apb_if.sv
// Description: SystemVerilog Interface for AMBA APB Protocol (APB UVM VIP).
//              Encapsulates physical bus signals, race-free clocking blocks, and modports.
//
// WHY MODPORTS?
// Only components that touch physical wires (Driver, Monitor, Slave DUT) require
// modport connections. Transaction-level components (Sequencer, Scoreboard, Coverage)
// communicate using TLM items (apb_seq_item) and do NOT connect to the interface!
//
// WHY IS PRESETn NOT INSIDE THE CLOCKING BLOCKS?
// presetn is an ASYNCHRONOUS Active-Low Reset. It can drop to 0 at any nanosecond
// in the middle of a clock cycle. Clocking blocks trigger ONLY on `@(posedge pclk)`.
// By keeping presetn as an unclocked direct input in modports (input presetn), the
// Driver and Monitor can detect reset instantly (wait(!vif.presetn)) at any timestamp.
// ==============================================================================

`ifndef APB_IF_SV
`define APB_IF_SV

interface apb_if #(
    parameter int ADDR_WIDTH = 32,  // Address Bus Width (Default: 32-bit)
    parameter int DATA_WIDTH = 32   // Data Bus Width (Default: 32-bit)
)(
    input logic pclk,    // System Clock Reference (100MHz, driven by apb_tb_top)
    input logic presetn  // System Active-Low Reset (driven by apb_tb_top)
);

    // --------------------------------------------------------------------------
    // AMBA APB Physical Bus Wires
    // --------------------------------------------------------------------------
    logic [ADDR_WIDTH-1:0] paddr;    // Address Bus (Master -> Slave)
    logic                  psel;     // Select Signal (Master -> Slave)
    logic                  penable;  // Strobe Enable Signal (Master -> Slave)
    logic                  pwrite;   // Operation Type: 1=Write, 0=Read (Master -> Slave)
    logic [DATA_WIDTH-1:0] pwdata;   // Write Data Bus (Master -> Slave)
    logic [DATA_WIDTH-1:0] prdata;   // Read Data Bus (Slave -> Master)
    logic                  pready;   // Handshake Ready Signal (Slave -> Master)
    logic                  pslverr;  // Slave Error Response Signal (Slave -> Master)

    // --------------------------------------------------------------------------
    // Driver Clocking Block (cb_driver)
    // Synchronizes signal driving with rising clock edge (posedge pclk).
    // - input #1step  : Samples input signals (pready, prdata) right BEFORE posedge pclk.
    // - output #1ns   : Drives output signals (psel, penable) 1ns AFTER posedge pclk
    //                   to model physical wire setup delays and prevent race conditions.
    // --------------------------------------------------------------------------
    clocking cb_driver @(posedge pclk);
        default input #1step output #1ns;
        
        // Master Driver OUTPUTS to DUT
        output paddr, psel, penable, pwrite, pwdata;
        
        // Master Driver INPUTS from DUT
        input  prdata, pready, pslverr;
    endclocking

    // --------------------------------------------------------------------------
    // Monitor Clocking Block (cb_monitor)
    // Synchronizes passive sampling of ALL bus signals on posedge pclk.
    // --------------------------------------------------------------------------
    clocking cb_monitor @(posedge pclk);
        default input #1step output #1ns;
        
        // Monitor samples ALL bus signals passively
        input paddr, psel, penable, pwrite, pwdata, prdata, pready, pslverr;
    endclocking

    // --------------------------------------------------------------------------
    // Modports (Defines directional access per component)
    // --------------------------------------------------------------------------
    
    // 1. Driver Modport (Active Master Driver interface)
    modport DRIVER (
        clocking cb_driver,
        input    pclk,
        input    presetn     // Direct unclocked asynchronous reset wire
    );

    // 2. Monitor Modport (Passive Bus Monitor interface)
    modport MONITOR (
        clocking cb_monitor,
        input    pclk,
        input    presetn     // Direct unclocked asynchronous reset wire
    );

    // 3. Slave DUT Modport (RTL Slave Memory / Peripheral)
    modport SLAVE (
        input  pclk,
        input  presetn,
        input  paddr,
        input  psel,
        input  penable,
        input  pwrite,
        input  pwdata,
        output prdata,
        output pready,
        output pslverr
    );

    // ==========================================================================
    // SystemVerilog Protocol Assertions (SVA) - ARM AMBA APB3 (IHI 0024B)
    // ==========================================================================

    // 1. SETUP to ACCESS Phase: PENABLE must assert exactly 1 clock cycle after PSEL
    property p_setup_to_access;
        @(posedge pclk) disable iff (!presetn)
        (psel && !penable) |=> (psel && penable);
    endproperty
    assert_setup_to_access: assert property(p_setup_to_access)
        else $error("[SVA-ASSERT-FAIL] PENABLE did not assert 1 cycle after PSEL!");

    // 2. Control/Address Stability: PADDR & PWRITE must NOT change during transfer
    property p_addr_stable_during_transfer;
        @(posedge pclk) disable iff (!presetn)
        (psel && !penable) |=> $stable(paddr) && $stable(pwrite);
    endproperty
    assert_addr_stable_during_transfer: assert property(p_addr_stable_during_transfer)
        else $error("[SVA-ASSERT-FAIL] Address or Write signal did not remain stable during transfer!");

    // 3. Write Data Stability: PWDATA must remain stable during write transfer
    property p_wdata_stable_during_transfer;
        @(posedge pclk) disable iff (!presetn)
        (psel && !penable && pwrite) |=> $stable(pwdata);
    endproperty
    assert_wdata_stable_during_transfer: assert property(p_wdata_stable_during_transfer)
        else $error("[SVA-ASSERT-FAIL] Write data signal did not remain stable during transfer!");

    // 4. PENABLE Deassertion: PENABLE must drop 1 cycle after transfer finishes (PREADY=1)
    property p_enable_deassert;
        @(posedge pclk) disable iff (!presetn)
        (psel && penable && pready) |=> !penable;
    endproperty
    assert_enable_deassert: assert property(p_enable_deassert)
        else $error("[SVA-ASSERT-FAIL] PENABLE did not deassert 1 cycle after PREADY!");

    // 5. Reset Behavior: PSEL and PENABLE must not be driven HIGH during active Reset
    property p_reset_state;
        @(posedge pclk)
        !presetn |-> (psel !== 1'b1 && penable !== 1'b1);
    endproperty
    assert_reset_state: assert property(p_reset_state)
        else $error("[SVA-ASSERT-FAIL] PSEL or PENABLE was driven HIGH during Reset!");

    // 6. No Spurious Enable: PENABLE cannot be asserted if PSEL is LOW
    property p_no_spurious_enable;
        @(posedge pclk) disable iff (!presetn)
        !psel |-> !penable;
    endproperty
    assert_no_spurious_enable: assert property(p_no_spurious_enable)
        else $error("[SVA-ASSERT-FAIL] PENABLE was asserted while PSEL was LOW!");

    // 7. No X/Z on Address & Control during active transfer
    property p_no_x_on_ctrl;
        @(posedge pclk) disable iff (!presetn)
        psel |-> !$isunknown(paddr) && !$isunknown(pwrite) && !$isunknown(penable);
    endproperty
    assert_no_x_on_ctrl: assert property(p_no_x_on_ctrl)
        else $error("[SVA-ASSERT-FAIL] Unknown (X/Z) detected on PADDR, PWRITE, or PENABLE!");

    // 8. Wait-State Stability: Signals must hold stable when Slave inserts wait states
    property p_wait_state_stability;
        @(posedge pclk) disable iff (!presetn)
        (psel && penable && !pready) |=> (psel && penable && $stable(paddr) && $stable(pwrite));
    endproperty
    assert_wait_state_stability: assert property(p_wait_state_stability)
        else $error("[SVA-ASSERT-FAIL] Signals changed while Slave inserted wait states (PREADY=0)!");
endinterface

`endif // APB_IF_SV
