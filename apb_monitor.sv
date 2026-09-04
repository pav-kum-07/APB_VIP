// ==============================================================================
// File Name  : apb_monitor.sv
// Description: APB Bus Monitor Component for APB UVM VIP.
// ==============================================================================

`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "apb_seq_item.sv"

class apb_monitor #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) extends uvm_monitor;

    // Virtual Interface Handle with MONITOR modport access
    virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif;

    // TLM Analysis Port
    uvm_analysis_port #(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH)) item_collect_port;
    
    // Factory Macro
    `uvm_component_param_utils(apb_monitor #(ADDR_WIDTH, DATA_WIDTH))
    
    // Constructor
    function new(string name = "apb_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build Phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_collect_port = new("item_collect_port", this);
        if (!uvm_config_db #(virtual apb_if #(ADDR_WIDTH, DATA_WIDTH))::get(this, "", "vif", vif))
            `uvm_fatal("MON_BUILD", "Did NOT get interface handle from config_db!")
        else
            `uvm_info("MON_BUILD", "Successfully retrieved interface handle from config_db", UVM_LOW)
    endfunction
    
    // Run Phase: Passive Bus Sampling
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        forever @(vif.cb_monitor) begin
            if (vif.cb_monitor.psel == 1'b1 && 
                vif.cb_monitor.penable == 1'b1 && 
                vif.cb_monitor.pready == 1'b1) begin
                
                // Declare & Instantiate item handle using type_id::create
                apb_seq_item #(ADDR_WIDTH, DATA_WIDTH) item;
                item = apb_seq_item #(ADDR_WIDTH, DATA_WIDTH)::type_id::create("item");
                
                // Sample physical bus wires
                item.addr    = vif.cb_monitor.paddr;
                item.op      = (vif.cb_monitor.pwrite == 1'b1) ? APB_WRITE : APB_READ;
                item.data    = (item.op == APB_WRITE) ? vif.cb_monitor.pwdata : vif.cb_monitor.prdata;
                item.pslverr = vif.cb_monitor.pslverr; // or vif.cb_monitor.pslverr
                
                // Broadcast item payload out TLM analysis port
                item_collect_port.write(item);
            end
        end
    endtask

endclass

`endif // APB_MONITOR_SV