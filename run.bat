@echo off
setlocal

:: Set Vivado installation path
set VIVADO_BIN=C:\Xilinx\Vivado\2024.1\bin

echo ===================================================
echo [1/3] Compiling APB VIP and Testbench with xvlog...
echo ===================================================
call "%VIVADO_BIN%\xvlog.bat" -sv -L uvm apb_if.sv apb_pkg.sv tb_top.sv
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Compilation failed!
    exit /b %ERRORLEVEL%
)

echo.
echo ===================================================
echo [2/3] Elaborating with xelab...
echo ===================================================
call "%VIVADO_BIN%\xelab.bat" -L uvm -timescale 1ns/1ps tb_top -s tb_top_sim
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Elaboration failed!
    exit /b %ERRORLEVEL%
)

echo.
echo ===================================================
echo [3/3] Running UVM Simulation with xsim...
echo ===================================================
call "%VIVADO_BIN%\xsim.bat" tb_top_sim -R
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Simulation failed!
    exit /b %ERRORLEVEL%
)

echo.
echo ===================================================
echo [SUCCESS] Simulation Completed!
echo ===================================================
