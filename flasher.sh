#!/bin/bash

print_header() {
  echo ""
  echo "================================================="
  echo " $1"
  echo "================================================="
}

#-------------------------------------------------------
# Checks
#-------------------------------------------------------

if ! command -v xc3sprog &> /dev/null; then
  echo "Error: 'xc3sprog' command not found."
  echo "   Please install it first. On Arch: bash install_xc3sprog.sh, or use your package manager if it's available."
  exit 1
fi

if [ "$#" -ne 1 ]; then
  echo "Error: Missing file path argument."
  echo "   Usage: ./flasher.sh /path/to/your/firmware.bit"
  exit 1
fi

FIRMWARE_FILE=$1
FILE_EXT="${FIRMWARE_FILE##*.}"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SPI_FLASHER_BIT="spiflasherLX9.bit"

if [ ! -f "$FIRMWARE_FILE" ]; then
  echo "Error: Firmware file not found at '$FIRMWARE_FILE'"
  exit 1
fi

if [ "$FILE_EXT" != "bit" ]; then
    echo "Error: This script requires a .bit file for all operations."
    exit 1
fi

echo """
███████╗██████╗  ██████╗  █████╗               ███████╗██╗      █████╗ ███████╗██╗  ██╗███████╗██████╗ 
██╔════╝██╔══██╗██╔════╝ ██╔══██╗              ██╔════╝██║     ██╔══██╗██╔════╝██║  ██║██╔════╝██╔══██╗
█████╗  ██████╔╝██║  ███╗███████║    █████╗    █████╗  ██║     ███████║███████╗███████║█████╗  ██████╔╝
██╔══╝  ██╔═══╝ ██║   ██║██╔══██║    ╚════╝    ██╔══╝  ██║     ██╔══██║╚════██║██╔══██║██╔══╝  ██╔══██╗
██║     ██║     ╚██████╔╝██║  ██║              ██║     ███████╗██║  ██║███████║██║  ██║███████╗██║  ██║
╚═╝     ╚═╝      ╚═════╝ ╚═╝  ╚═╝              ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝                                                 
                                                                                                       
██████╗ ██╗   ██╗     █████╗ ███████╗██████╗ ███████╗██████╗  ██████╗ ███████╗███████╗
██╔══██╗╚██╗ ██╔╝    ██╔══██╗╚══███╔╝██╔══██╗██╔════╝██╔══██╗██╔═══██╗╚══███╔╝██╔════╝
██████╔╝ ╚████╔╝     ███████║  ███╔╝ ██████╔╝█████╗  ██████╔╝██║   ██║  ███╔╝ █████╗  
██╔══██╗  ╚██╔╝      ██╔══██║ ███╔╝  ██╔═══╝ ██╔══╝  ██╔═══╝ ██║   ██║ ███╔╝  ██╔══╝  
██████╔╝   ██║       ██║  ██║███████╗██║     ███████╗██║     ╚██████╔╝███████╗███████╗
╚═════╝    ╚═╝       ╚═╝  ╚═╝╚══════╝╚═╝     ╚══════╝╚═╝      ╚═════╝ ╚══════╝╚══════╝                              
"""

#-------------------------------------------------------
# Configuration
#-------------------------------------------------------

MAX_ATTEMPTS=2
RETRY_DELAY_SECONDS=5
DEVICE_FOUND=false

#-------------------------------------------------------
# Selection
#-------------------------------------------------------
print_header "Checking for FTDI Device"

for (( attempt=1; attempt<=$MAX_ATTEMPTS; attempt++ )); do
    if xc3sprog -c ftdi >& /dev/null; then
        echo "Found FTDI device. Good to go!"
        DEVICE_FOUND=true
        break
    fi

    if [ $attempt -lt $MAX_ATTEMPTS ]; then
        echo "Error: FTDI device not found. Retrying in $RETRY_DELAY_SECONDS seconds... (Attempt $attempt/$MAX_ATTEMPTS)"
        sleep $RETRY_DELAY_SECONDS
    fi
done

if [ "$DEVICE_FOUND" = false ]; then
    echo "Error: FTDI device still not found after $MAX_ATTEMPTS attempts. Please make sure it is connected."
    exit 1
fi

print_header "Select Flash Mode"
echo "Firmware File Selected: $(basename "$FIRMWARE_FILE")"
echo ""
echo "Please select a flash mode:"
echo "  1) Temporary Flash (Fast, for testing)"
echo "  2) Permanent Flash (Writes to SPI Memory)"
echo -n "Enter mode number: "
read -r MODE

#-------------------------------------------------------
# Execute Selected Mode
#-------------------------------------------------------
case $MODE in
  1)
    print_header "Executing Temporary Flash"
    echo "Programming FPGA SRAM with '$FIRMWARE_FILE'..."
    
    xc3sprog -c ftdi -L -v -p 0 "$FIRMWARE_FILE"
    ;;

  2)
    print_header "Executing Permanent Flash"

    if [ ! -f "$SCRIPT_DIR/$SPI_FLASHER_BIT" ]; then
        echo "Error: Helper file '$SPI_FLASHER_BIT' not found."
        echo "   Please make sure it is in the same directory as this script."
        exit 1
    fi

    print_header "Sub-step 1/2: Loading SPI flasher bitstream '$SPI_FLASHER_BIT'..."
    xc3sprog -c ftdi -L "$SCRIPT_DIR/$SPI_FLASHER_BIT"
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to load the SPI flasher bitstream."
        echo "   Aborting permanent flash."
        exit 1
    fi

    echo ""
    print_header "Sub-step 2/2: Writing '$FIRMWARE_FILE' to SPI flash via helper..."
    echo "This may take a moment. Please wait..."
    
    xc3sprog -c ftdi -L -v -R -p 0 -I "$FIRMWARE_FILE"
    ;;

  *)
    echo "Error: Invalid mode '$MODE' selected."
    exit 1
    ;;
esac

#-------------------------------------------------------
# Result
#-------------------------------------------------------
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  print_header "Success! Operation Completed"
else
  print_header "Error! Operation Failed"
fi

exit $EXIT_CODE