topColour = [0, 0, 15]
bottomColour = [15, 0, 0]

width = 32
height = 64

f = open("colour.data", 'w')

rowColours = []

for i in range(height):
    deltaY = [t - b for (t, b) in zip(topColour, bottomColour)]
    slope = [d / (height - 1) for d in deltaY]
    colour = [round(m * i + b) for (m, b) in zip(slope, bottomColour)]
    unicode = [(ord('0') + c if c < 10 else ord('A') + c - 10) for c in colour]
    concat = ''.join([chr(char) for char in unicode])
    rowColours += [concat + '\n'] * width # Duplicate for each column in row

f.writelines(rowColours[0:-1]) # Drop the trailing newline

f.close()
