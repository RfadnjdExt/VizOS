@echo off
if not exist "bin" mkdir bin

echo [1/3] Compiling Bootloader (Stage 1)...
nasm -f bin kernel\boot.asm -o bin\boot.bin
if %errorlevel% neq 0 ( exit /b %errorlevel% )

echo [2/3] Compiling Main Kernel (Stage 2)...
nasm -f bin kernel\kernel_main.asm -o bin\kernel.bin
if %errorlevel% neq 0 ( exit /b %errorlevel% )

echo [3/3] Creating Disk Image...
REM Combine bootloader (512 bytes) + kernel
copy /b bin\boot.bin + bin\kernel.bin bin\myshell.img

echo Build successful!
echo Load bin\myshell.img in VirtualBox to run.
