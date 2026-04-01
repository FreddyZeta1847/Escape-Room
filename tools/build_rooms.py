"""
Room Background Builder — LimeZu Modern Interiors tileset
Tile coordinates verified via labeled tile maps and alpha analysis.
"""

from PIL import Image
import os

TILE = 16
WIDTH, HEIGHT = 320, 180

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rb = Image.open(os.path.join(BASE, "Modern tiles_Free", "Interiors_free", "16x16", "Room_Builder_free_16x16.png")).convert("RGBA")
inter = Image.open(os.path.join(BASE, "Modern tiles_Free", "Interiors_free", "16x16", "Interiors_free_16x16.png")).convert("RGBA")


def t(sheet, col, row, w=1, h=1):
    return sheet.crop((col*TILE, row*TILE, (col+w)*TILE, (row+h)*TILE))


def place(canvas, sprite, px, py):
    canvas.paste(sprite, (px, py), sprite)


# ============================================================
# WALLS — col 5 has seamless fill tiles (no frame borders)
# Odd rows only are solid (even rows are transparent)
# Row 5=salmon, 7=yellow, 9=mint, 11=light wood, 13=dark wood,
# 15=orange wood, 17=blue-grey, 19=beige
# For baseboard: cols 0-3 have bordered tiles with baseboard built in
# ============================================================

# Salmon wall fill + baseboard from framed version
W_SAL_FILL = t(rb, 5, 5)    # seamless salmon fill
W_SAL_FRAME_T = t(rb, 0, 5) # framed top (has dark border line)
W_SAL_FRAME_B = t(rb, 0, 7) # framed baseboard (cream/yellow)

# Brown wood wall
W_BRN_FILL = t(rb, 5, 11)   # light wood fill
W_BRN_FRAME_T = t(rb, 0, 11)
W_BRN_FRAME_B = t(rb, 0, 11) # reuse as base

# Dark brown wood wall
W_DK_FILL = t(rb, 5, 13)
W_DK_FRAME_T = t(rb, 0, 13)

# Blue-grey wall
W_BLU_FILL = t(rb, 5, 17)
W_BLU_FRAME_T = t(rb, 0, 17)
W_BLU_FRAME_B = t(rb, 0, 19)  # beige baseboard for contrast

# ============================================================
# FLOORS — cols 11-13 have patterned tiles
# Rows 13-14: herringbone wood (perfect for mansion)
# Rows 11-12: grey stone (good for study)
# ============================================================

F_HERRING_A = t(rb, 11, 13)  # herringbone wood variant A
F_HERRING_B = t(rb, 12, 13)  # variant B
F_HERRING_C = t(rb, 13, 13)  # variant C
F_HERRING_D = t(rb, 11, 14)  # row 2 variant A
F_HERRING_E = t(rb, 12, 14)  # row 2 variant B

F_GREY_A = t(rb, 11, 11)     # grey stone A
F_GREY_B = t(rb, 12, 11)     # grey stone B
F_GREY_C = t(rb, 11, 12)     # grey stone row 2
F_GREY_D = t(rb, 12, 12)     # grey stone row 2 B

# ============================================================
# INTERIORS FURNITURE (verified coordinates)
# ============================================================

# Rug (red/gold Victorian) — cols 7-10, rows 15-17
RUG_TL = t(inter, 7, 15)
RUG_TC = t(inter, 8, 15)
RUG_TR = t(inter, 10, 15)
RUG_ML = t(inter, 7, 16)
RUG_MC = t(inter, 8, 16)
RUG_MR = t(inter, 10, 16)
RUG_BL = t(inter, 7, 17)
RUG_BC = t(inter, 8, 17)
RUG_BR = t(inter, 10, 17)

# Bookshelf with books — cols 5-6, rows 14-15 (2w x 2h)
BOOKSHELF = t(inter, 5, 14, 2, 2)

# Paintings/frames on wall
FRAME_A = t(inter, 0, 20, 2, 1)   # small framed art
FRAME_B = t(inter, 2, 20, 2, 1)
PAINTING = t(inter, 2, 12, 2, 1)  # landscape painting

# Curtain window — cols 3-5, rows 24-25 (3w x 2h)
CURTAIN_WIN = t(inter, 3, 24, 3, 2)


# ============================================================
# HELPERS
# ============================================================

def fill_herringbone(canvas, start_y=0, rows=12):
    """Fill with 2-row repeating herringbone wood pattern."""
    tiles_row1 = [F_HERRING_A, F_HERRING_B, F_HERRING_C]
    tiles_row2 = [F_HERRING_D, F_HERRING_E, F_HERRING_A]
    for r in range(rows):
        row_tiles = tiles_row1 if r % 2 == 0 else tiles_row2
        for c in range(20):
            place(canvas, row_tiles[c % len(row_tiles)], c*TILE, start_y + r*TILE)


def fill_grey(canvas, start_y=0, rows=12):
    """Fill with 2-row repeating grey stone pattern."""
    for r in range(rows):
        for c in range(20):
            if r % 2 == 0:
                tile = F_GREY_A if c % 2 == 0 else F_GREY_B
            else:
                tile = F_GREY_C if c % 2 == 0 else F_GREY_D
            place(canvas, tile, c*TILE, start_y + r*TILE)


def draw_wall_3row(canvas, frame_top, fill, frame_base):
    """Draw 3-row wall: framed top, seamless fill mid, framed baseboard."""
    for c in range(20):
        place(canvas, frame_top, c*TILE, 0)
        place(canvas, fill, c*TILE, TILE)
        place(canvas, frame_base, c*TILE, 2*TILE)


def clear_doorway_herring(canvas, col_start, col_end):
    """Replace wall rows with herringbone floor to create doorway."""
    tiles_row1 = [F_HERRING_A, F_HERRING_B, F_HERRING_C]
    tiles_row2 = [F_HERRING_D, F_HERRING_E, F_HERRING_A]
    for row in range(3):
        row_tiles = tiles_row1 if row % 2 == 0 else tiles_row2
        for col in range(col_start, col_end):
            place(canvas, row_tiles[col % len(row_tiles)], col*TILE, row*TILE)


def clear_doorway_grey(canvas, col_start, col_end):
    for row in range(3):
        for col in range(col_start, col_end):
            if row % 2 == 0:
                tile = F_GREY_A if col % 2 == 0 else F_GREY_B
            else:
                tile = F_GREY_C if col % 2 == 0 else F_GREY_D
            place(canvas, tile, col*TILE, row*TILE)


def draw_rug(canvas, px, py, w, h):
    place(canvas, RUG_TL, px, py)
    for c in range(1, w-1):
        place(canvas, RUG_TC, px + c*TILE, py)
    place(canvas, RUG_TR, px + (w-1)*TILE, py)
    for r in range(1, h-1):
        place(canvas, RUG_ML, px, py + r*TILE)
        for c in range(1, w-1):
            place(canvas, RUG_MC, px + c*TILE, py + r*TILE)
        place(canvas, RUG_MR, px + (w-1)*TILE, py + r*TILE)
    place(canvas, RUG_BL, px, py + (h-1)*TILE)
    for c in range(1, w-1):
        place(canvas, RUG_BC, px + c*TILE, py + (h-1)*TILE)
    place(canvas, RUG_BR, px + (w-1)*TILE, py + (h-1)*TILE)


# ============================================================
# ENTRANCE HALL — salmon walls, herringbone wood floor
# ============================================================
def build_entrance_hall():
    c = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 255))
    fill_herringbone(c)
    draw_wall_3row(c, W_SAL_FRAME_T, W_SAL_FILL, W_SAL_FRAME_B)

    # Doorways
    clear_doorway_herring(c, 1, 3)     # left → Living Room
    clear_doorway_herring(c, 17, 19)   # right → Study

    # Front door center
    door = Image.new("RGBA", (2*TILE, 3*TILE), (50, 32, 22, 255))
    place(c, door, 9*TILE, 0)
    frame = Image.new("RGBA", (2, 3*TILE), (90, 65, 40, 255))
    place(c, frame, 9*TILE-2, 0)
    place(c, frame, 11*TILE, 0)
    frame_h = Image.new("RGBA", (2*TILE+4, 2), (90, 65, 40, 255))
    place(c, frame_h, 9*TILE-2, 0)

    # Rug
    draw_rug(c, 7*TILE, 5*TILE, 6, 3)

    return c.crop((0, 0, WIDTH, HEIGHT))


# ============================================================
# LIVING ROOM — brown wood walls, herringbone floor
# ============================================================
def build_living_room():
    c = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 255))
    fill_herringbone(c)
    draw_wall_3row(c, W_DK_FRAME_T, W_DK_FILL, W_SAL_FRAME_B)

    # Doorway right
    clear_doorway_herring(c, 17, 19)

    # Large rug
    draw_rug(c, 5*TILE, 5*TILE, 8, 4)

    return c.crop((0, 0, WIDTH, HEIGHT))


# ============================================================
# STUDY — blue-grey walls, grey stone floor
# ============================================================
def build_study():
    c = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 255))
    fill_grey(c)
    draw_wall_3row(c, W_BLU_FRAME_T, W_BLU_FILL, W_BLU_FRAME_B)

    # Doorway right
    clear_doorway_grey(c, 17, 19)

    # Rug
    draw_rug(c, 6*TILE, 5*TILE, 5, 3)

    return c.crop((0, 0, WIDTH, HEIGHT))


if __name__ == "__main__":
    for name, fn in [("entrance_hall", build_entrance_hall),
                     ("living_room", build_living_room),
                     ("study", build_study)]:
        img = fn()
        path = os.path.join(BASE, "game", "rooms", name, f"bg_{name}.png")
        img.save(path)
        print(f"[OK] {name}")
    print("Done!")
