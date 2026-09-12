@echo off
setlocal

:: =============================================================================
:: Script Name : run_regression.bat
:: Description : Full APB VIP Multi-Test Regression Suite with Merged Coverage
::
:: Tests Executed:
::   1. Directed Test          : apb_write_read_test (Corner, boundary & error vectors)
::   2. Constrained-Random Test: apb_random_test     (100 CRV randomized transfers)
::
:: Coverage Merged via xcrg:
::   - Functional Coverage (Covergroups, Bins, Cross-Coverage)
::   - Code Coverage (Statement, Branch, Condition, Toggle)
:: =============================================================================

set VIVADO_BIN=C:\Xilinx\Vivado\2024.1\bin

echo ========================================================
echo [APB VIP] Launching Full Verification Regression Suite
echo ========================================================

:: Clean previous coverage databases
if exist cov_work rmdir /s /q cov_work
if exist coverage_report rmdir /s /q coverage_report

:: -----------------------------------------------------------------------------
:: Step 1: Compile all VIP & Testbench Sources
:: -----------------------------------------------------------------------------
echo.
echo [1/5] Compiling SystemVerilog and UVM files with xvlog...
call "%VIVADO_BIN%\xvlog.bat" -sv -L uvm apb_if.sv apb_pkg.sv tb_top.sv
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Compilation failed!
    exit /b %ERRORLEVEL%
)

:: -----------------------------------------------------------------------------
:: Step 2: Elaborate with Full Coverage Instrumentation
:: -----------------------------------------------------------------------------
echo.
echo [2/5] Elaborating simulation snapshot with xelab...
call "%VIVADO_BIN%\xelab.bat" -L uvm -timescale 1ns/1ps tb_top -s tb_top_sim -cc_type sbct -cov_db_dir ./cov_work -cov_db_name apb_cov
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Elaboration failed!
    exit /b %ERRORLEVEL%
)

:: -----------------------------------------------------------------------------
:: Step 3: Run Directed Test (apb_write_read_test)
:: -----------------------------------------------------------------------------
echo.
echo [3/5] Running Regression Test 1: apb_write_read_test...
call "%VIVADO_BIN%\xsim.bat" -f directed_args.txt
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Test 1 failed!
    exit /b %ERRORLEVEL%
)

:: -----------------------------------------------------------------------------
:: Step 4: Run Constrained-Random Test (apb_random_test)
:: -----------------------------------------------------------------------------
echo.
echo [4/5] Running Regression Test 2: apb_random_test...
call "%VIVADO_BIN%\xsim.bat" -f random_args.txt
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Test 2 failed!
    exit /b %ERRORLEVEL%
)

:: -----------------------------------------------------------------------------
:: Step 5: Merge Coverage Databases & Generate Unified Report
:: -----------------------------------------------------------------------------
echo.
echo [5/5] Generating Unified Regression Coverage Report with xcrg...
call "%VIVADO_BIN%\xcrg.bat" -cov_db_dir ./cov_work -cov_db_name apb_cov -report_dir ./coverage_report -report_format all
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Coverage reporting generated warnings.
)

echo.
echo ========================================================
echo [SUCCESS] Full Regression Completed! Both Tests Passed!
echo Merged Coverage Reports:
echo   - Functional Coverage: ./coverage_report/functionalCoverageReport/dashboard.html
echo   - Code Coverage      : ./coverage_report/codeCoverageReport/dashboard.html
echo ========================================================
