# FPGA-Flasher-Linux.

FPGA-Flasher-Linux for XC6SLX9. using bit file to flash the FPGA board.

I've seen [FPGA-Flasher](https://github.com/thanatath/FPGA-Flasher) but it's for Windows users. So I decided to create a simple script for Linux users to flash their FPGA boards.

---

## Install Dependencies (if not already installed)

This project requires `xc3sprog` to flash the FPGA.
If you're on Arch Linux, you can run the following command to install it:

```bash
bash install_xc3sprog.sh
```

You can install `xc3sprog` by using Arch User Repository (AUR) but it's will fail due to missing `DCMAKE_POLICY_VERSION_MINIMUM` so I created a script that will edit PKGBUILD and add `DCMAKE_POLICY_VERSION_MINIMUM` automatically.

⚠️ If you are using a different Linux distribution, please use your package manager to install `xc3sprog`.

---

## Flash Firmware

1. Run the flasher script, providing the path to your `.bit` file.

     ```bash
     bash flasher.sh /path/to/your/firmware.bit
     ```

     or you can just type:

     ```bash
     bash flasher.sh
     ```

     then drag and drop your `.bit` file into the terminal.

2. Choose if you want to flash for `Temporary` or `Permanent`.
