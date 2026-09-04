// ==============================================================================
// File Name  : apb_slave_dut.sv
// Description: Behavioral APB Slave Memory DUT with configurable wait states.
// ==============================================================================

`ifndef APB_SLAVE_DUT_SV
`define APB_SLAVE_DUT_SV

module apb_slave_dut #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MEM_DEPTH  = 256  // 256 words (1KB RAM space: 0x000 to 0x3FC)
)(
    input  logic                  pclk,
    input  logic                  presetn,
    input  logic [ADDR_WIDTH-1:0] paddr,
    input  logic                  psel,
    input  logic                  penable,
    input  logic                  pwrite,
    input  logic [DATA_WIDTH-1:0] pwdata,
    output logic [DATA_WIDTH-1:0] prdata,
    output logic                  pready,
    output logic                  pslverr
);

    // --------------------------------------------------------------------------
    // Internal Memory Storage (Word-addressed: paddr[ADDR_WIDTH-1:2])
    // --------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    logic [$clog2(MEM_DEPTH)-1:0] word_addr;

    assign word_addr = paddr[9:2]; // Word offset within 1KB

    // --------------------------------------------------------------------------
    // Protocol State Machine & Bus Driving
    // --------------------------------------------------------------------------
    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            prdata  <= '0;
            pready  <= 1'b0;
            pslverr <= 1'b0;
            for (int i = 0; i < MEM_DEPTH; i++) begin
                mem[i] <= '0;
            end
        end
        else begin
            // Default inactive state
            pready  <= 1'b0;
            pslverr <= 1'b0;

            // SETUP -> ACCESS Phase Transition (psel & penable active)
            if (psel && penable) begin
                pready <= 1'b1; // Ready with 0 wait-states

                // Check Address Bounds (0x000 to 0x3FF)
                if (paddr > 32'h0000_03FF) begin
                    pslverr <= 1'b1; // Out of bounds error response
                end
                else if (pwrite) begin
                    // Write operation
                    mem[word_addr] <= pwdata;
                end
                else begin
                    // Read operation
                    prdata <= mem[word_addr];
                end
            end
        end
    end

endmodule

`endif // APB_SLAVE_DUT_SV
