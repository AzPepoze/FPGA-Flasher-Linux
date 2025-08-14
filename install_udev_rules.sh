echo 'ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666"' | sudo tee /etc/udev/rules.d/99-ftdi.rules

sudo udevadm control --reload-rules && sudo udevadm trigger

echo Please unplug and reconnect FPGA to make udev use new rules.