#!/usr/bin/python3
#
# This software and the information contained therein is confidential and proprietary to UTC-Building & Industrial 
# Systems and shall not be used or disclosed to others, in whole or in part, without the written authorization of BIS.
#

"""

Calculate applications CRC-32 to be used by bootloader validation procedure

Example of script invocation: 

    python AddCrcToHexFile.py InputHex.run InputHex.map OutputHex.hex

This script has been tested with Python 2.7.12 (https://www.python.org/)

"""

try:
    import os
    import pip
    #os.environ["HTTP_PROXY"] = "159.82.13.242:80"
    #os.environ["HTTPS_PROXY"] = "159.82.13.242:80"
except:
    print("Consider installing pip module (package manager) or upgrading python to python 2.7.9 or latter")
    print("https://www.python.org/ftp/python/2.7.12/python-2.7.12.msi")
    sys.exit()

try:
    from intelhex import IntelHex 
except:
    import sys
    import subprocess
    print("Installing intelhex module...")
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'intelhex'])
    from intelhex import IntelHex 
    
try:
    import crcmod
except:
    import sys
    import subprocess
    print("Installing crcmod module...")
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'crcmod'])
    import crcmod
    
import sys
import struct

def AddCrcToHexFile(inputFilePath, outputFilePath):

    # Parse input file
    inputHex = IntelHex(inputFilePath)   
    
    # Calculate interesting addresses
    firstAddress = inputHex.minaddr()
    print ("First address : " + hex(firstAddress))
    lastAddress = inputHex.maxaddr()
    print ("Last address  : " + hex(lastAddress))
    headerAddress = firstAddress + 0x300
    print ("Header address: " + hex(headerAddress))
    crcAddress = lastAddress - 3    
    print ("CRC address   : " + hex(crcAddress))
    lengthAddress = headerAddress + 20
    print ("Length address: " + hex(lengthAddress))
    
    # Calculate, check and write length
    length = lastAddress - firstAddress + 1        
    lengthBytes = struct.pack("<L", length)
    for a in range(0, 4):
        if sys.version_info[0] >= 3:
            inputHex[lengthAddress + a] = lengthBytes[a]
        else:
            inputHex[lengthAddress + a] = ord(lengthBytes[a])

    # Pad unused locations with 0xFF
    for a in range(firstAddress, lastAddress + 1):
        if inputHex[a] == 0xFF:        
            inputHex[a] = 0xFF    
    
    # Calculate and write CRC
    data = []
    for addr in range(firstAddress, crcAddress):
        data.append(inputHex[addr])    
    crc = CalculateCRC(data)   
    print("CRC           : " + hex(crc))
    crcBytes = struct.pack("<L", crc)
    for a in range(0, 4):
        if sys.version_info[0] >= 3:
            inputHex[crcAddress + a] = crcBytes[a]
        else:
            inputHex[crcAddress + a] = ord(crcBytes[a])

    # Save to output file
    inputHex.tofile(outputFilePath, format="hex")  
    
    #f = open("dump.txt", "w")
    #inputHex.dump(f)
    #f.close()

def CalculateCRC(values):
    crcFunction = crcmod.predefined.mkPredefinedCrcFun("crc-32-bzip2")
    if sys.version_info[0] >= 3:
        valData = bytearray()
        for i in range(0, len(values)):
            valData.append(values[i])
    else:
        valData = ""
        for i in range(0, len(values)):
            valData = valData + chr(values[i])

    return crcFunction(valData)
        
# This only executes if this script has been directly from the command line (not imported from another script).
if __name__ == '__main__':

    if len(sys.argv) != 3:
        print("Invalid command line arguments")
        sys.exit(1)
    
    AddCrcToHexFile(sys.argv[1], sys.argv[2])

    print ("Output file generated successfully at " + sys.argv[2])
    
    sys.exit(0)
