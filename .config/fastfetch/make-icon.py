from PIL import Image

N = 32
img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
px = img.load()

# palette
OUT = (122, 74, 21, 255)      # dark outline
GOLD = (224, 166, 58, 255)    # body
HI = (243, 202, 108, 255)     # highlight
SH = (193, 129, 29, 255)      # shadow gold
STEM = (92, 51, 22, 255)
LEAF = (84, 171, 44, 255)
LEAFD = (58, 122, 28, 255)
FACE = (90, 58, 22, 255)
PINK = (214, 138, 120, 255)   # inner ear

def ell(x, y, cx, cy, rx, ry):
    return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0

def tri(x, y, ax, ay, bx, by, cx, cy):
    def sign(px, py, qx, qy, rx, ry):
        return (px - rx) * (qy - ry) - (qx - rx) * (py - ry)
    d1 = sign(x, y, ax, ay, bx, by)
    d2 = sign(x, y, bx, by, cx, cy)
    d3 = sign(x, y, cx, cy, ax, ay)
    neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
    return not (neg and pos)

def body(x, y):
    lobeL = ell(x, y, 11, 13, 7.5, 8)
    lobeR = ell(x, y, 20, 13, 7.5, 8)
    lower = ell(x, y, 15.5, 19, 11, 12)
    earL = tri(x, y, 9, 2, 4, 11, 14, 10)
    earR = tri(x, y, 22, 2, 17, 10, 27, 11)
    return lobeL or lobeR or lower or earL or earR

def inner_ear(x, y):
    return tri(x, y, 9, 5, 6, 10, 12, 9) or tri(x, y, 22, 5, 19, 9, 25, 10)

# fill body
for y in range(N):
    for x in range(N):
        if body(x, y):
            # default gold
            c = GOLD
            # highlight upper-left
            if ((x - 11) ** 2 + (y - 15) ** 2) < 6:
                c = HI
            # shadow lower-right
            if (x - 15.5) + (y - 19) > 12:
                c = SH
            px[x, y] = c

# inner ear
for y in range(N):
    for x in range(N):
        if body(x, y) and inner_ear(x, y):
            px[x, y] = PINK

# outline: any body pixel adjacent to non-body
base = [[body(x, y) for x in range(N)] for y in range(N)]
for y in range(N):
    for x in range(N):
        if base[y][x]:
            edge = False
            for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                nx, ny = x+dx, y+dy
                if nx<0 or ny<0 or nx>=N or ny>=N or not base[ny][nx]:
                    edge = True
            if edge:
                px[x, y] = OUT

# stem (center dip)
for y in range(0, 7):
    px[15, y] = STEM
    px[16, y] = STEM
px[17, 5] = STEM

# leaf to the right of stem
leaf_pts = [(18,3),(19,3),(20,3),(19,2),(20,2),(21,3),(18,4),(19,4),(20,4),(21,4)]
for (x, y) in leaf_pts:
    px[x, y] = LEAF
px[21, 4] = LEAFD
px[18, 4] = LEAFD

# face: eyes + whisker dots
px[12, 17] = FACE
px[13, 17] = FACE
px[18, 17] = FACE
px[19, 17] = FACE
# mouth / whisker dots row
for x in [11, 13, 15, 17, 20]:
    px[x, 20] = FACE
px[16, 21] = FACE

scale = 16
big = img.resize((N*scale, N*scale), Image.NEAREST)
big.save("/private/tmp/claude-501/-Users-dylanwax--dotfiles/154d6e9e-1576-4b24-8983-1276b85032d5/scratchpad/apple_preview.png")
img.resize((256,256), Image.NEAREST).save("/private/tmp/claude-501/-Users-dylanwax--dotfiles/154d6e9e-1576-4b24-8983-1276b85032d5/scratchpad/apple_256.png")
print("done")
