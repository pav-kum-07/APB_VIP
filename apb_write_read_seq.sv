`ifndef APB_WRITE_READ_SEQ_SV
`define APB_WRITE_READ_SEQ_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "apb_rw_e.sv"
`include "apb_seq_item.sv"
`include "apb_base_seq.sv"

class apb_write_read_seq #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) extends apb_base_seq #(ADDR_WIDTH,DATA_WIDTH);
    
    `uvm_object_param_utils(apb_write_read_seq #(ADDR_WIDTH, DATA_WIDTH))

    function new(string name="apb_write_read_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [ADDR_WIDTH-1:0] test_addrs[4] = '{
            32'h0000_0000,  // 1. min_addr boundary
            32'h0000_0010,  // 2. inside_ram
            32'h0000_03FC,  // 3. max_addr boundary
            32'h0000_0500   // 4. out_of_bound (triggers PSLVERR=1)
        };
        logic [DATA_WIDTH-1:0] test_data[4] = '{
            32'hAAAA_1111,
            32'hBBBB_2222,
            32'hCCCC_3333,
            32'hDDDD_4444
        };

        `uvm_info("SEQ", "Starting 100% Coverage APB Write/Read Sequence...", UVM_LOW)

        req = apb_seq_item#(ADDR_WIDTH, DATA_WIDTH)::type_id::create("req");

        for (int i = 0; i < 4; i++) begin
            // 1. Write Transaction
            start_item(req);
            if (!req.randomize() with { 
                op   == APB_WRITE; 
                addr == test_addrs[i]; 
                data == test_data[i]; 
            }) begin
                `uvm_error("SEQ", $sformatf("Failed to randomize Write for addr 0x%08h", test_addrs[i]))
            end
            finish_item(req);

            // 2. Read Back from same Address
            start_item(req);
            if (!req.randomize() with { 
                op   == APB_READ; 
                addr == test_addrs[i]; 
            }) begin
                `uvm_error("SEQ", $sformatf("Failed to randomize Read for addr 0x%08h", test_addrs[i]))
            end
            finish_item(req);

            `uvm_info("SEQ", $sformatf("Completed Txn Pair [%0d/4]: addr=0x%08h, pslverr=%0b", 
                      i+1, req.addr, req.pslverr), UVM_LOW)
        end
        
    endtask

endclass

`endif