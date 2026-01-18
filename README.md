# VizOS 👁️

VizOS adalah kernel Sistem Operasi 16-bit yang ringan, dibangun dari nol menggunakan Assembly (NASM). OS ini dikembangkan untuk menjembatani logika manusia dengan bahasa mesin tingkat rendah, menampilkan Tokenizer Transparan real-time yang unik.

## 🌟 Fitur Utama

### 1. Tokenizer Transparan (Inovasi I)
Memvisualisasikan logika parsing perintah OS secara real-time.
- **Tampilan Baris Ganda**: Input di atas, visualisasi tokenizer di bawah.
- **Tanpa Latensi**: Memperbarui secara instan melalui manipulasi Memori Video langsung.
- **Umpan Balik Visual**: Menampilkan `CMD: [perintah] ARG: [argumen]` saat Anda mengetik.

### 2. Fitur Auto-Guess
Eksekusi perintah yang dioptimalkan menggunakan Pencocokan Awalan (Prefix Matching).
- Ketik `h` -> Menjalankan `help`
- Ketik `r` -> Menjalankan `reboot`
- Ketik `e` -> Menjalankan `echo`
- Ketik `c` -> Menjalankan `cls` (Bersihkan Layar)

### 3. Monitor Denyut Perangkat Keras (Inovasi II)
Alternatif task manager bare-metal.
- Perintah: `pulse`
- Memantau:
  - Mode CPU (Real Mode 16-bit)
  - Deteksi Memori (Standar 640KB)
  - Waktu Nyala Sistem (BIOS Ticks Hexdump)

### 4. Bootloader Kustom
- **Arsitektur Multi-Tahap**:
  - **Tahap 1 (MBR)**: Memuat Kernel dari disk ke memori `0x1000`.
  - **Tahap 2 (Kernel)**: Loop shell utama dan logika OS.

## 🛠️ Stack Teknologi
- **Bahasa**: Assembly Murni (NASM)
- **Arsitektur**: x86 Real Mode (16-bit)
- **Alat**: NASM, VirtualBox
- **Tanpa Pustaka Eksternal**: Semua I/O ditangani melalui BIOS Interrupts.

## 🚀 Cara Build & Jalankan
Prasyarat: `nasm`, `VirtualBox`.

1. **Build**:
   ```batch
   .\build.bat
   ```
   Ini akan mengompilasi `boot.asm` dan `kernel.asm`, lalu menggabungkannya menjadi Image Floppy 1.44MB (`bin\myshell.img`).

2. **Jalankan di VirtualBox**:
   - Buat Virtual Machine baru:
     - **Type**: Other
     - **Version**: Other/Unknown
     - **Memory**: 64 MB (Cukup)
   - Masuk ke **Settings** -> **Storage**.
   - Tambahkan **Floppy Controller** (I82078).
   - Tambahkan Floppy Device dan pilih file disk `bin\myshell.img`.
   - Jalankan VM (Start).

## 📂 Struktur Proyek
- `boot/`: Kode sumber Bootloader.
- `kernel/`: Kode sumber Kernel (`kernel_main.asm`).
- `bin/`: Binary hasil kompilasi (Diabaikan oleh Git).

---
*Dikembangkan untuk Tugas Akhir Praktikum Sistem Operasi.*
