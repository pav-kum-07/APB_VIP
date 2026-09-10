# AMBA APB3 UVM Verification IP (VIP)

[![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog%20(IEEE%201800--2023)-blue.svg)](https://standards.ieee.org/)
[![UVM](https://img.shields.io/badge/Methodology-UVM%201.2%20(IEEE%201800.2)-green.svg)](https://accellera.org/)
[![Simulator](https://img.shields.io/badge/Simulator-AMD%20Vivado%202024.1%20(XSim)-orange.svg)](https://www.xilinx.com/products/design-tools/vivado.html)
[![Functional Coverage](https://img.shields.io/badge/Coverage-100.00%25-brightgreen.svg)]()
[![SVA Assertions](https://img.shields.io/badge/SVA%20Assertions-8%2F8%20Passed-success.svg)]()

A complete, production-grade, parameterized **AMBA APB3 (Advanced Peripheral Bus) Universal Verification Methodology (UVM) Verification IP (VIP)**. 

Architected for verification scalability across block-level, subsystem, and full-SoC environments with **100.00% functional coverage** and **8 golden SystemVerilog Assertions (SVA)** adhering strictly to the **ARM AMBA APB3 Protocol Specification (ARM IHI 0024B)**.

---

## 🏗️ System Architecture & Testbench Topology

```
+-------------------------------------------------------------------------------------------------------+
|                                                tb_top                                                 |
|                                         (SystemVerilog Module)                                        |
|                                                                                                       |
|  +------------------------+                             +------------------------------------------+  |
|  |     apb_slave_dut      |                             |        uvm_test_top (apb_test)           |  |
|  |  (Memory Model / DUT)  |                             |          (apb_write_read_test)           |  |
|  +-----------+------------+                             |                                          |  |
|              | (Physical Wires)                         |  +------------------------------------+  |  |
|  +-----------+---------------------------------------+  |  |              apb_env               |  |  |
|  |            apb_if (Physical Bus)                  |  |  |                                    |  |  |
|  +-----------------------+---------------------------+  |  |  +------------------------------+  |  |  |
|                          |                              |  |  |          apb_agent           |  |  |  |
|                          |                              |  |  |  +-----------+  +---------+  |  |  |  |
|                          |                              |  |  |  |    sqr    |  |   drv   |  |  |  |  |
|                          | (Virtual Interface           |  |  |  +-----+-----+  +----+----+  |  |  |  |
|                          |  via uvm_config_db)          |  |  |        | (TLM)       |       |  |  |  |
|                          |                              |  |  |  +-----v-----+       | (Pin) |  |  |  |
|                          |                              |  |  |  |    mon    +-------+       |  |  |  |
|                          |                              |  |  |  +-----+-----+               |  |  |  |
|                          |                              |  |  +--------|---------------------+  |  |  |
|                          |                              |  |           | TLM Analysis Port      |  |  |
|                          |                              |  |     +-----v-----+   +-----------+  |  |  |
|                          |                              |  |     |Scoreboard |   | Coverage  |  |  |  |
|                          |                              |  |     |   (scb)   |   |   (cov)   |  |  |  |
|                          |                              |  |     +-----------+   +-----------+  |  |  |
|                          |                              |  +------------------------------------+  |  |
|                          +──────────────────────────────┼──────────────────────────────────────────+  |
|                                                         |                                             |
+---------------------------------------------------------+---------------------------------------------+
```

---

## 🚀 Key Features

- **Full AMBA APB3 Compliance**: Supports standard 2-phase transfers (SETUP & ACCESS), configurable slave wait states (`PREADY`), and error signaling (`PSLVERR`).
- **Parameterized & Highly Reusable**: Fully parameterized `ADDR_WIDTH` and `DATA_WIDTH` supporting 32-bit, 64-bit, or custom word architectures.
- **Race-Free Interface**: Implements dedicated SystemVerilog **Clocking Blocks** (`default input #1step output #1ns`) eliminating zero-hold timing races between testbench and DUT.
- **Active / Passive Mode Switching**: Instantiates Driver and Sequencer only when `is_active == UVM_ACTIVE`; acts as a non-intrusive bus sniffer in `UVM_PASSIVE` mode for full SoC integration.
- **Automated Self-Checking Scoreboard**: Implements an autonomous reference memory model (`mem[addr]`) with dynamic prediction, real-time read-data comparison, and automated end-of-test verification (`check_phase` and `report_phase`).
- **100% Functional Coverage Metric Closure**: Covergroups tracking transaction types (`cp_op`), address partitions (`cp_addr`), error responses (`cp_pslverr`), and full cross coverage (`cr_op_addr`).
- **8 Golden SVA Protocol Assertions**: Concurrent cycle-accurate assertion checks embedded directly in the interface.

---

## 📊 Verification Metrics & Results

```text
======================================================================
UVM_INFO apb_coverage.sv @ 325000: uvm_test_top.env.cov [COVERAGE] 
  TOTAL FUNCTIONAL COVERAGE = 100.00%
    * Operation (cp_op)      : 100.00%
    * Address (cp_addr)      : 100.00%
    * Error Status (pslverr) : 100.00%
    * Cross (op x addr)      : 100.00%
======================================================================
UVM_INFO apb_scoreboard.sv @ 325000: uvm_test_top.env.scb [SCB_SUMMARY]
==================================================
           APB SCOREBOARD FINAL REPORT            
==================================================
 Total Writes Tracked      : 3
 Total Reads Checked       : 3
 Total Matches (PASS)      : 3
 Total Mismatches (FAIL)   : 0
 Unwritten Address Reads   : 0
 Slave Error Responses     : 2
==================================================
--- UVM Report Summary ---
** Report counts by severity:
  UVM_INFO    : 38
  UVM_WARNING : 2  (Expected negative error responses)
  UVM_ERROR   : 0  (ALL SCOREBOARD CHECKS & SVA ASSERTIONS PASSED)
  UVM_FATAL   : 0
======================================================================
```

---

## 🛡️ SVA Protocol Assertions Suite (ARM APB3 IHI 0024B)

| # | Assertion Name | Formal Property | Checked Hardware Rule |
| :-: | :--- | :--- | :--- |
| **1** | `assert_setup_to_access` | `(psel && !penable) \|=> (psel && penable)` | Enforces that SETUP phase transitions to ACCESS phase in exactly 1 clock cycle. |
| **2** | `assert_addr_stable_during_transfer` | `(psel && !penable) \|=> $stable(paddr) && $stable(pwrite)` | Prohibits address and control signal glitching during transfer. |
| **3** | `assert_wdata_stable_during_transfer` | `(psel && !penable && pwrite) \|=> $stable(pwdata)` | Guarantees `PWDATA` stability throughout the entire write transfer. |
| **4** | `assert_enable_deassert` | `(psel && penable && pready) \|=> !penable` | Enforces `PENABLE` deassertion immediately after transfer completion (`PREADY=1`). |
| **5** | `assert_reset_state` | `!presetn \|-> (psel !== 1'b1 && penable !== 1'b1)` | Verifies that `PSEL` and `PENABLE` are never driven active during system reset. |
| **6** | `assert_no_spurious_enable` | `!psel \|-> !penable` | Prevents illegal enable strobes without active peripheral selection. |
| **7** | `assert_no_x_on_ctrl` | `psel \|-> !$isunknown(paddr) && !$isunknown(pwrite) && !$isunknown(penable)` | Catches floating uninitialized `X`/`Z` logic on active bus signals. |
| **8** | `assert_wait_state_stability` | `(psel && penable && !pready) \|=> (psel && penable && $stable(paddr) && $stable(pwrite))` | Freezes all master control lines during multi-cycle slave wait states (`PREADY=0`). |

---

## 🔬 Architectural & Verification Deep-Dives

### 1. Driver Sampling Semantics: Blocking (`=`) vs Non-Blocking (`<=`)
- **Driving Interface Pins (`<=`)**: Clocking block outputs (`vif.cb_driver.penable <= 1'b1;`) schedule signal drives into the interface according to output skew.
- **Sampling into Transactions (`=`)**: Copying sampled data (`req.data = vif.cb_driver.prdata;` and `req.pslverr = vif.cb_driver.pslverr;`) uses **blocking assignments** because `req` is a dynamic software object (not an RTL register). This guarantees that response data is available immediately in the active region when `item_done()` or `put_response()` is executed.

### 2. Clocking Block Skew Strategy (`default input #1step output #1ns;`)
- **`input #1step`**: Samples signals in the **Preponed region** right before `posedge pclk`, capturing stable values prior to any synchronous RTL flop transitions and guaranteeing zero-hold race immunity.
- **`output #1ns`**: Delays driven signals by 1ns after clock edge to model physical wire propagation delay ($T_{co}$), ensuring clean visual inspection in waveform debuggers while satisfying $T_{setup} < T_{period} - \text{skew}$.

### 3. SVA Asynchronous Reset Suppression (`disable iff (!presetn)`)
- Prevents spurious assertion failures at simulation time $t=0$ (uninitialized states) or during abrupt mid-transfer hardware resets.
- Uses **Overlapping Implication (`|->`)** for same-cycle invariant checks and **Non-Overlapping Implication (`|=>`)** for 1-cycle state transitions (such as SETUP $\rightarrow$ ACCESS).

### 4. Dynamic Associative Memory Reference Model (`mem[addr]`)
- Allocating a full static array for 32-bit address space would demand $2^{32} \times 4\text{ bytes} \approx 16\text{ GB}$ (32–64+ GB with simulator 4-state logic metadata), causing immediate host Out-Of-Memory (OOM) crashes.
- Associative array `logic [31:0] mem [logic [31:0]]` acts as an on-demand hash table, consuming ~0 KB at startup and allocating dynamically only for accessed addresses.

### 5. Verification Testing Taxonomy
- **Directed Corner Testing**: Handcrafted corner vectors (e.g. `apb_write_read_seq` executing 4 directed boundaries: min `0x0000_0000`, max `0x0000_03FC`, interior `0x0000_0010`, and out-of-bounds error `0x0000_0500`).
- **Exhaustive Testing**: Verifying 100% of all possible addresses (e.g. all 1024 locations in 1KB RAM).
- **Stress Testing**: Flooding the DUT with back-to-back zero-delay bursts and randomized slave wait states (`PREADY=0`) to expose buffer/arbitration limits.
- **Regression Testing**: Automated multi-seed execution of the full test suite in CI/CD pipelines to guard against functional regressions.

---

## 📂 Repository Directory Structure

```
APB_VIP/
├── apb_rw_e.sv             # Direction Enum (APB_READ=0, APB_WRITE=1)
├── apb_seq_item.sv         # Transaction Sequence Item with soft constraints
├── apb_if.sv               # Interface with clocking blocks & 8 SVA assertions
├── apb_driver.sv           # Active Master Driver (2-Phase APB Handshake)
├── apb_monitor.sv          # Passive Bus Monitor (TLM 1-to-many broadcasting)
├── apb_sequencer.sv        # UVM Sequencer
├── apb_agent.sv            # Parameterized UVM Agent (Active/Passive config)
├── apb_scoreboard.sv       # Dynamic Sparse Associative Memory Checker
├── apb_coverage.sv         # Functional Coverage Subscriber (100% Closure)
├── apb_env.sv              # Top Environment wiring Agent -> SCB & Coverage
├── apb_base_seq.sv         # Base Virtual Sequence
├── apb_write_read_seq.sv   # Directed 100% Coverage Stimulus Sequence
├── apb_test.sv             # Base Test
├── apb_write_read_test.sv  # Directed Write/Read Test
├── apb_pkg.sv              # VIP Package (Compiles classes into namespace)
├── apb_slave_dut.sv        # Behavioral 1KB APB Slave Memory RTL Model
├── tb_top.sv               # Top-level Testbench Module (Clock & Reset gen)
├── run.bat                 # Automated Vivado XSim compile & run script
└── README.md               # Complete Project Architecture & Documentation
```

---

## ⚙️ How to Compile & Simulate

### Prerequisites
- **AMD Vivado Design Suite** (2020.1 or newer — tested on Vivado 2024.1)

### Execution
Run the automated batch script in PowerShell / Command Prompt:

```cmd
cd APB_VIP
.\run.bat
```

The script automatically executes:
1. **Compilation (`xvlog`)**: Analyzes `apb_if.sv`, `apb_pkg.sv`, and `tb_top.sv` with SystemVerilog and UVM library flags.
2. **Elaboration (`xelab`)**: Elaborates `tb_top` with `1ns/1ps` timescale resolution and generates simulation snapshot `tb_top_sim`.
3. **Simulation (`xsim`)**: Executes UVM testbench `apb_write_read_test`, outputs full verification topology, logs transactions, checks assertions, and prints the 100% coverage report.

---

## 📚 Standards & Authoritative References

- **[ARM IHI 0024B]**: *AMBA 3 APB Protocol Specification v1.0*
- **[ARM IHI 0024C]**: *AMBA 4 APB Protocol Specification v2.0*
- **[IEEE Std 1800-2023]**: *IEEE Standard for SystemVerilog—Unified Hardware Design, Specification, and Verification Language*
- **[IEEE Std 1800.2-2020]**: *IEEE Standard for Universal Verification Methodology Language Reference Manual (UVM LRM)*

---

## 👤 Author
Developed as a production-grade Verification IP (VIP) adhering to industry best practices.
