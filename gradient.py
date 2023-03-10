import itertools

topColour = [0, 0, 15]
bottomColour = [15, 0, 0]

width = 32
height = 64

f = open("colour.data", 'w')

rowColours = [[0 for x in range(width)] for y in range(height)]

for i in range(height):
    deltaY = [t - b for (t, b) in zip(topColour, bottomColour)]
    slope = [d / (height - 1) for d in deltaY]
    colour = [round(m * i + b) for (m, b) in zip(slope, bottomColour)]
    unicode = [(ord('0') + c if c < 10 else ord('A') + c - 10) for c in colour]
    concat = ''.join([chr(char) for char in unicode])
    rowColours[i] = [concat + '\n'] * width # Duplicate for each column in row

# Transpose colour matrix so that colour values along the gradient axis are 
# written to the file in sequence (i.e., column by column). This corresponds 
# with the order that pixel values are read from the ROM in hardware
memFormat = list(zip(*rowColours))
flatData = list(itertools.chain(*memFormat)) # Unzip matrix and convert to list

f.writelines(flatData)

f.close()
