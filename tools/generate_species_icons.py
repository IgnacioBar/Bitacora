from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "images" / "species"

SIZE = 512
SCALE = 4
CANVAS = SIZE * SCALE

TRANSPARENT = (0, 0, 0, 0)
STAMP = (234, 214, 167, 255)
STAMP_LIGHT = (255, 251, 240, 255)
INK = (109, 90, 49, 255)
INK_SOFT = (138, 111, 61, 255)
GOLD = (191, 148, 62, 255)


def scaled(points):
    return [(int(x * SCALE), int(y * SCALE)) for x, y in points]


def line(draw, points, fill=INK, width=10, joint="curve"):
    draw.line(scaled(points), fill=fill, width=width * SCALE, joint=joint)


def ellipse(draw, box, fill=None, outline=None, width=1):
    draw.ellipse(tuple(int(v * SCALE) for v in box), fill=fill, outline=outline, width=width * SCALE)


def polygon(draw, points, fill=None, outline=None):
    draw.polygon(scaled(points), fill=fill, outline=outline)


def arc(draw, box, start, end, fill=INK, width=8):
    draw.arc(tuple(int(v * SCALE) for v in box), start, end, fill=fill, width=width * SCALE)


def base():
    image = Image.new("RGBA", (CANVAS, CANVAS), TRANSPARENT)
    draw = ImageDraw.Draw(image)
    ellipse(draw, (42, 42, 470, 470), fill=STAMP, outline=INK_SOFT, width=8)
    ellipse(draw, (76, 76, 436, 436), fill=STAMP_LIGHT, outline=(216, 199, 163, 255), width=4)
    return image, draw


def fish_common(draw, *, body, tail, dorsal=None, pectoral=None, eye=(342, 235), mouth=None, spots=None, stripes=None):
    polygon(draw, tail, fill=INK_SOFT, outline=INK)
    ellipse(draw, body, fill=STAMP, outline=INK, width=11)
    if dorsal:
        polygon(draw, dorsal, fill=INK_SOFT, outline=INK)
    if pectoral:
        polygon(draw, pectoral, fill=INK_SOFT, outline=INK)
    ellipse(draw, (eye[0] - 7, eye[1] - 7, eye[0] + 7, eye[1] + 7), fill=INK)
    if mouth:
        line(draw, mouth, width=6)
    for spot in spots or []:
        ellipse(draw, (spot[0] - spot[2], spot[1] - spot[2], spot[0] + spot[2], spot[1] + spot[2]), fill=INK_SOFT)
    for stripe in stripes or []:
        line(draw, stripe, fill=INK_SOFT, width=7)


def draw_black_bass(draw):
    fish_common(
        draw,
        body=(128, 178, 386, 310),
        tail=[(111, 244), (55, 194), (70, 244), (55, 294)],
        dorsal=[(180, 181), (205, 136), (224, 178), (250, 134), (274, 178), (300, 150), (315, 185)],
        pectoral=[(242, 282), (288, 340), (278, 282)],
        mouth=[(345, 245), (408, 229), (378, 260)],
        spots=[(202, 238, 8), (232, 246, 7), (263, 238, 8), (294, 245, 7)],
    )


def draw_carp(draw):
    fish_common(
        draw,
        body=(122, 164, 386, 326),
        tail=[(115, 246), (58, 194), (78, 246), (58, 298)],
        dorsal=[(196, 169), (254, 116), (312, 174)],
        pectoral=[(238, 286), (296, 338), (280, 282)],
        mouth=[(346, 250), (398, 244), (346, 260)],
        spots=[(202, 230, 6), (229, 265, 5), (272, 224, 5)],
    )
    line(draw, [(376, 252), (430, 232)], width=5)
    line(draw, [(376, 258), (430, 278)], width=5)


def draw_pike(draw):
    polygon(draw, [(125, 224), (340, 178), (426, 220), (340, 264)], fill=STAMP, outline=INK)
    polygon(draw, [(126, 224), (63, 176), (86, 224), (63, 272)], fill=INK_SOFT, outline=INK)
    polygon(draw, [(256, 188), (324, 136), (330, 185)], fill=INK_SOFT, outline=INK)
    ellipse(draw, (355, 209, 369, 223), fill=INK)
    line(draw, [(392, 220), (438, 210), (398, 232)], width=6)
    for x in (185, 220, 258, 295):
        ellipse(draw, (x, 218, x + 13, 231), fill=INK_SOFT)


def draw_brown_trout(draw):
    fish_common(
        draw,
        body=(118, 174, 392, 314),
        tail=[(112, 244), (54, 195), (75, 244), (54, 293)],
        dorsal=[(206, 175), (250, 124), (292, 177)],
        pectoral=[(246, 284), (304, 330), (286, 278)],
        mouth=[(350, 244), (410, 232), (380, 258)],
        spots=[(176, 222, 7), (209, 252, 6), (244, 222, 7), (286, 252, 6), (320, 222, 6)],
    )
    line(draw, [(160, 258), (335, 258)], fill=GOLD, width=8)


def draw_wels_catfish(draw):
    fish_common(
        draw,
        body=(112, 180, 388, 316),
        tail=[(112, 248), (50, 206), (72, 248), (50, 290)],
        dorsal=[(178, 184), (234, 148), (292, 184)],
        pectoral=[(226, 286), (292, 338), (268, 282)],
        eye=(336, 235),
        mouth=[(346, 250), (402, 248), (346, 260)],
    )
    line(draw, [(365, 242), (442, 206)], width=5)
    line(draw, [(368, 250), (452, 250)], width=5)
    line(draw, [(365, 258), (442, 294)], width=5)


def draw_barbel(draw):
    fish_common(
        draw,
        body=(116, 184, 388, 306),
        tail=[(111, 245), (54, 198), (74, 245), (54, 292)],
        dorsal=[(214, 185), (262, 142), (308, 187)],
        pectoral=[(236, 275), (294, 320), (276, 274)],
        mouth=[(348, 248), (408, 246)],
        spots=[(210, 242, 5), (254, 242, 5)],
    )
    line(draw, [(378, 252), (430, 232)], width=5)
    line(draw, [(378, 258), (430, 276)], width=5)


def draw_european_seabass(draw):
    fish_common(
        draw,
        body=(114, 182, 400, 310),
        tail=[(108, 246), (50, 198), (72, 246), (50, 294)],
        dorsal=[(190, 183), (224, 132), (246, 180), (272, 136), (300, 182)],
        pectoral=[(242, 280), (302, 324), (282, 276)],
        mouth=[(356, 246), (416, 237), (386, 257)],
        stripes=[[(164, 224), (344, 224)], [(168, 252), (338, 252)]],
    )


def draw_gilthead_bream(draw):
    fish_common(
        draw,
        body=(128, 148, 382, 342),
        tail=[(126, 246), (58, 194), (78, 246), (58, 298)],
        dorsal=[(194, 154), (256, 106), (320, 156)],
        pectoral=[(238, 286), (302, 342), (282, 282)],
        mouth=[(342, 246), (402, 238), (374, 258)],
    )
    line(draw, [(309, 184), (348, 184)], fill=GOLD, width=14)


def draw_white_seabream(draw):
    fish_common(
        draw,
        body=(126, 150, 382, 340),
        tail=[(124, 246), (58, 196), (80, 246), (58, 296)],
        dorsal=[(194, 156), (256, 110), (318, 158)],
        pectoral=[(236, 286), (300, 340), (278, 282)],
        mouth=[(342, 246), (400, 240), (374, 258)],
        stripes=[
            [(188, 168), (178, 326)],
            [(238, 154), (232, 340)],
            [(292, 164), (302, 326)],
        ],
    )


def draw_atlantic_bluefin_tuna(draw):
    polygon(draw, [(118, 248), (214, 174), (352, 188), (432, 236), (348, 292), (216, 322)], fill=STAMP, outline=INK)
    polygon(draw, [(120, 248), (52, 188), (78, 248), (52, 308)], fill=INK_SOFT, outline=INK)
    polygon(draw, [(246, 177), (308, 116), (316, 184)], fill=INK_SOFT, outline=INK)
    polygon(draw, [(248, 317), (318, 384), (312, 306)], fill=INK_SOFT, outline=INK)
    ellipse(draw, (357, 221, 373, 237), fill=INK)
    line(draw, [(168, 250), (356, 240)], fill=INK_SOFT, width=8)


def draw_common_dentex(draw):
    fish_common(
        draw,
        body=(126, 160, 388, 330),
        tail=[(120, 246), (56, 196), (78, 246), (56, 296)],
        dorsal=[(192, 164), (252, 112), (314, 166)],
        pectoral=[(240, 288), (306, 340), (282, 282)],
        mouth=[(348, 248), (414, 238), (382, 262)],
        spots=[(214, 232, 6), (268, 248, 5)],
    )
    polygon(draw, [(389, 258), (404, 282), (411, 255)], fill=STAMP_LIGHT, outline=INK)


def draw_cuttlefish_squid(draw):
    ellipse(draw, (160, 116, 338, 304), fill=STAMP, outline=INK, width=11)
    polygon(draw, [(164, 210), (95, 168), (118, 236)], fill=INK_SOFT, outline=INK)
    polygon(draw, [(334, 210), (404, 168), (380, 236)], fill=INK_SOFT, outline=INK)
    ellipse(draw, (216, 188, 230, 202), fill=INK)
    ellipse(draw, (266, 188, 280, 202), fill=INK)
    for i, x in enumerate((186, 214, 242, 270, 298)):
        line(draw, [(x, 292), (x - 34 + i * 17, 398)], width=8)
    arc(draw, (202, 210, 296, 258), 20, 160, width=6)


DRAWERS = {
    "black_bass": draw_black_bass,
    "carp": draw_carp,
    "pike": draw_pike,
    "brown_trout": draw_brown_trout,
    "wels_catfish": draw_wels_catfish,
    "barbel": draw_barbel,
    "european_seabass": draw_european_seabass,
    "gilthead_bream": draw_gilthead_bream,
    "white_seabream": draw_white_seabream,
    "atlantic_bluefin_tuna": draw_atlantic_bluefin_tuna,
    "common_dentex": draw_common_dentex,
    "cuttlefish_squid": draw_cuttlefish_squid,
}


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for species_id, drawer in DRAWERS.items():
        image, draw = base()
        drawer(draw)
        image = image.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
        image.save(OUT_DIR / f"{species_id}.png")
    print(f"Generated {len(DRAWERS)} species icons in {OUT_DIR}")


if __name__ == "__main__":
    main()
