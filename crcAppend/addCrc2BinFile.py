#!/usr/bin/env python3

import os
import sys
import subprocess
import struct
import crcmod.predefined

def ensure_module(module_name):
    try:
        __import__(module_name)
    except ImportError:
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', module_name])
        __import__(module_name)

# Ensure required modules are installed
ensure_module("crcmod")

def CalculateCRC(values):
    crcFunction = crcmod.predefined.mkPredefinedCrcFun("crc-32-bzip2")
    if sys.version_info[0] >= 3:
        valData = bytearray(values)
    else:
        valData = "".join(chr(v) for v in values)
    return crcFunction(valData)

def modify_file_with_length_and_crc32(filename):
    with open(filename, 'rb+') as f:
        data = f.read()

        # Calculate length of data
        file_length = len(data)
        print(f"Bin Size: {file_length} bytes")

        if file_length < 788:
            print("File is too small to write length at 788-byte offset")
            sys.exit(1)

        # Write length at 788-byte offset
        length_bytes = struct.pack('<I', file_length)
        data = data[:788] + length_bytes + data[788+4:]

        # Calculate CRC32 excluding the last 4 bytes
        data_without_last_4_bytes = data[:-4]
        crc32 = CalculateCRC(data_without_last_4_bytes)
        crc32_bytes = struct.pack('<I', crc32)

        # Replace the last 4 bytes with CRC32
        data = data[:-4] + crc32_bytes

        # Save the modified data back to the file
        f.seek(0)
        f.write(data)

        print(f"Calc CRC: 0x{crc32:08X}")

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python3 modify_file_with_length_and_crc32.py <filename>")
        sys.exit(1)

    modify_file_with_length_and_crc32(sys.argv[1])
    sys.exit(0)
