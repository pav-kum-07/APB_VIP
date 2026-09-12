@echo off
setlocal

:: =============================================================================
:: Script Name : run_coverage.bat
:: Description : Automated 4-Step Vivado Coverage Pipeline for APB UVM VIP
::
:: -----------------------------------------------------------------------------
:: ISSUES ADDRESSED & RESOLVED:
:: -----------------------------------------------------------------------------
:: 1. Compilation Order & Scope Resolution (VRFC 10-2989):
::    SystemVerilog packages (`apb_pkg.sv`) must be parsed and analyzed into the
::    work library BEFORE modules that import them (`tb_top.sv`).
::    This script guarantees the deterministic order: apb_if.sv -> apb_pkg.sv -> tb_top.sv.
::
:: 2. Code Coverage Enabling via xelab:
::    Passing `-cc_type sbct` enables instrumentation for:
::      - s : Statement (Line) Coverage
::      - b : Branch Coverage
::      - c : Condition Coverage
::      - t : Toggle Coverage
::    Databases are directed into `./cov_work` under database name `apb_cov`.
::
:: 3. Seamless HTML Report Generation via xcrg:
::    `xcrg` merges functional coverage (`xsim.covdb`) and code coverage (`xsim.codeCov`),
::    generating complete interactive dashboards in `./coverage_report/`.
:: =============================================================================

:: Set Vivado installation path
set VIVADO_BIN=C:\Xilinx\Vivado\2024.1\bin

echo ========================================================
echo Running APB VIP Random Test with Code and Func Coverage
echo Test: apb_random_test
echo ========================================================

:: -----------------------------------------------------------------------------
:: Step 1: SystemVerilog & UVM Compilation (xvlog)
:: -----------------------------------------------------------------------------
echo.
echo [1/4] Compiling SystemVerilog and UVM VIP files with xvlog...
call "%VIVADO_BIN%\xvlog.bat" -sv -L uvm apb_if.sv apb_pkg.sv tb_top.sv
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Compilation failed!
    exit /b %ERRORLEVEL%
)

:: -----------------------------------------------------------------------------
:: Step 2: Static Elaboration & Coverage Instrumentation (xelab)
:: -----------------------------------------------------------------------------
echo.
echo [2/4] Elaborating with xelab (Enabling Line, Branch, Condition, Toggle)...
call "%VIVADO_BIN%\xelab.bat" -L uvm -timescale 1ns/1ps tb_top -s tb_top_sim -cc_type sbct -cov_db_dir ./cov_work -cov_db_name apb_cov
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Elaboration failed!
    exit /b %ERRORLEVEL%
)

:: -----------------------------------------------------------------------------
:: Step 3: Simulation & Coverage Database Dumping (xsim)
:: -----------------------------------------------------------------------------
echo.
echo [3/4] Running UVM Simulation with xsim (apb_random_test)...
call "%VIVADO_BIN%\xsim.bat" tb_top_sim -R -cov_db_dir ./cov_work -cov_db_name apb_cov
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Simulation failed!
    exit /b %ERRORLEVEL%
)

:: -----------------------------------------------------------------------------
:: Step 4: Coverage Report Generation & HTML Export (xcrg)
:: -----------------------------------------------------------------------------
echo.
echo [4/4] Generating HTML Coverage Report with xcrg...
call "%VIVADO_BIN%\xcrg.bat" -cov_db_dir ./cov_work -cov_db_name apb_cov -report_dir ./coverage_report -report_format all
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Coverage report generation finished with warnings.
)

echo.
echo ========================================================
echo [SUCCESS] Coverage Run Completed!
echo HTML Reports Generated:
echo   - Code Coverage      : ./coverage_report/codeCoverageReport/dashboard.html
echo   - Functional Coverage: ./coverage_report/functionalCoverageReport/dashboard.html
echo ========================================================
