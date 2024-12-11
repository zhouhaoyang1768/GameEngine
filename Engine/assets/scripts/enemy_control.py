import math
import random
dx = 2
dy = 0

dx, dy = rotate((dx, dy), orientation / 180.0 * math.pi)

x = x + dx
y = y - dy

if x < -10 or y < -10:
    active = False
if x > 1024 or y > 768:
    active = False

if lives == 0:
    active = False

if not active:
    _x = random.random()
    _y = 0.1

    if random.random() > 0.5:
        _x, _y = _y, _x
    _x = _x * 1000
    _y = _y * 600

    cx = 500
    cy = 300

    dx = cx - _x
    dy = _y - cx

    if dx == 0:
        if dy >= 0:
            orientation = 90
        else:
            orientation = 270

    else:
        orientation = math.atan(float(dy)/dx) / math.pi * 180
        if dx < 0 :
            orientation = orientation + 180
    addEntity("enemy", 1, 1, int(_x), int(_y), True, orientation, "", "enemy_control", "enemy_collission", "ufo")