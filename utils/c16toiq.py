#! /usr/bin/python3

import os
import sys
from struct import *
import zlib
import argparse
import time


def main():

    parser = argparse.ArgumentParser(description='Convert a portapack .C16 capture to SDRAngel .sdriq file format')

    parser.add_argument("filename", help=".C16 file to be converted", nargs=1, type=str)
    parser.add_argument("rate", help="Sample rate in S/s", nargs=1, type=int)
    parser.add_argument("frequency", help="Center frequency in Hz", nargs=1, type=int)
    parser.add_argument("-t", "--time", help="Unix Epoch Timestamp (in seconds, will use current time if omitted)", nargs=1, type=int)

    args = parser.parse_args()
    
    if args.time is None:
        time_arg = time.time()
    else:
        time_arg = args.time[0]

    crcpack = pack('<IqqII', args.rate[0], args.frequency[0], int(time_arg), 16, 0)
    crc = zlib.crc32(crcpack)
    header = pack('<IqqIII', args.rate[0], args.frequency[0], int(time_arg), 16, 0, crc)

    f = open(args.filename[0], 'rb')
    fread = f.read()

    n = open(args.filename[0].split('.')[0] + '.sdriq', 'wb')
    n.write(header)
    n.write(fread)

    f.close()
    n.close()

if __name__ == '__main__':
    main()
