import math

mouse_x, mouse_y = mouseLocation()

dy = y - mouse_y
dx = mouse_x - x

if dx == 0:
    if dy >= 0:
        orientation = 90
    else:
        orientation = 270

else:
    orientation = math.atan(float(dy)/dx) / math.pi * 180
    if dx < 0 :
        orientation = orientation + 180

dx = 0
dy = 0
speed = 5

if keyPressed("A") and not keyPressed("D"):
    dy = 1
elif keyPressed("D") and not keyPressed("A"):
    dy = -1
else:
    dy = 0
if keyPressed("W") and not keyPressed("S"):
    dx = 1
elif keyPressed("S") and not keyPressed("W"):
    dx = -1
else:
    dx = 0

dx, dy = normalize((dx, dy))

dx = dx * speed
dy = dy * speed

dx, dy = rotate((dx, dy), orientation / 180 * math.pi)

x = int(x + dx)
y = int(y - dy)

clicked = leftClick()

if not last_clicked and clicked:
    playAudio("player_fire")
    addEntity("entity", 0, 1, x, y, True, orientation, "", "player_bullet", "player_collission", "bullet")
last_clicked = clicked

if lives <= 0:
    active = False
    redirect = "gameover"