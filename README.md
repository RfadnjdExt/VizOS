# MyShell OS 🐚

MyShell OS is a lightweight, 16-bit Operating System kernel built from scratch in Assembly (NASM). It was developed to bridge the gap between human logic and low-level machine language, featuring a unique real-time Transparent Tokenizer.

## 🌟 Key Features

### 1. Transparent Tokenizer (Innovation I)
Visualizes the OS command parsing logic in real-time.
- **Dual-Line Display**: Input on top, tokenizer visualization below.
- **Zero-Latency**: Updates instantly via direct Video Memory manipulation.
- **Visual Feedback**: Shows `CMD: [command] ARG: [argument]` as you type.

### 2. Auto-Guess Feature
Optimized command execution using Prefix Matching.
- Type `h` -> Executes `help`
- Type `r` -> Executes `reboot`
- Type `e` -> Executes `echo`

### 3. Hardware Pulse Monitor (Innovation II)
A bare-metal task manager alternative.
- Command: `pulse`
- Monitors:
  - CPU Mode (Real Mode 16-bit)
  - Memory Detection (Standard 640KB)
  - System Uptime (BIOS Ticks Hexdump)

### 4. Custom Bootloader
- **Multi-Stage Architecture**:
  - **Stage 1 (MBR)**: Loads Kernel from disk to memory `0x1000`.
  - **Stage 2 (Kernel)**: The main OS shell loop and logic.

## 🛠️ Tech Stack
- **Language**: Pure Assembly (NASM)
- **Architecture**: x86 Real Mode (16-bit)
- **Tools**: NASM, QEMU/VirtualBox
- **No External Libraries**: All I/O is handled via BIOS Interrupts.

## 🚀 How to Build & Run
Prerequisites: `nasm`, `qemu-system-x86_64`.

1. **Build**:
   ```bash
   .\build.bat
   ```
   This will compile `boot.asm` and `kernel.asm`, then pad them into a 1.44MB Floppy Image (`myshell.img`).

2. **Run**:
   ```bash
   qemu-system-x86_64 -flp bin\myshell.img
   ```

## 📂 Project Structure
- `boot/`: Bootloader source code.
- `kernel/`: Kernel source code (`kernel_main.asm`).
- `bin/`: Compiled binaries (Ignored by Git).

---
*Developed for Operating System Practicum Final Project.*
