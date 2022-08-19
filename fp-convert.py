import argparse

Q = 15
N = 32

parser = argparse.ArgumentParser()
parser.add_argument("type", type=str)
parser.add_argument("value", type=str)
args = parser.parse_args()

if args.type == "r":
    # Convert from real number to fixed-point number
    num = float(args.value)
    negFlag = False
    if (num < 0):
        negFlag = True
    num = abs(num)
    out = "0" if not negFlag else "1"
    for i in range(Q):
        bitPos = Q - i
        bitVal = pow(2, bitPos)
        if num >= bitVal:
            out += "1" if not negFlag else "0"
            num -= bitVal
        else:
            out += "0" if not negFlag else "1"
    for i in range(Q + 1):
        bitVal = 1 / pow(2, i)
        if num >= bitVal:
            out += "1" if not negFlag else "0"
            num -= bitVal
        else:
            out += "0" if not negFlag else "1"
    out = int(out, 2)
    if negFlag: out += 1
    print(format(out, '08x'))
elif args.type == "fp":
    # Convert fixed-point number to real number
    if len(args.value) != N / 4:
        print("Error: Incorrect argument length")
        quit()
    num = int(args.value, 16)
    numBinary = format(num, f'0{N}b')
    invBinary = ""
    negFlag = False
    if (numBinary[0] == "1"):
        negFlag = True
        for i in range(N):
            if numBinary[i] == "0":
                invBinary += "1"
            else:
                invBinary += "0"
        numBinary = format(int(invBinary, 2) + 1, f'0{N}b')
    out = int(numBinary[1:Q+2], 2) # Upper bound not inclusive
    for i in range(N - Q, N):
        bitVal = 1 / pow(2, i-Q-1)
        if numBinary[i] == "1":
            out += bitVal
    if negFlag: out = out * -1
    print(out)
else:
    print("Invalid type parameter")
