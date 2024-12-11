import math
dx = 2
dy = 0

dx, dy = rotate((dx, dy), orientation / 180 * math.pi)

x = int(x + dx)
y = int(y - dy)

if x < -10 or y < -10:
    active = False
if x > 1024 or y > 768:
    active = False

if lives == 0:
    active = False