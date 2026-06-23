from PIL import Image

# 角色尺寸: 32x48 像素, 手绘风格横版角色
# 生成 4 帧动画: idle / run1 / run2 / jump
# 颜色方案: 深色探险者服装 (后室幸存者风格)

W, H = 32, 48
FRAMES = 4
img = Image.new("RGBA", (W * FRAMES, H), (0, 0, 0, 0))
px = img.load()

# --- 调色板 ---
SKIN = (220, 180, 150, 255)      # 肤色
SKIN_D = (190, 150, 120, 255)    # 肤色暗面
HAIR = (60, 40, 30, 255)         # 深棕头发
JACKET = (40, 50, 60, 255)       # 深灰蓝外套
JACKET_D = (30, 38, 48, 255)     # 外套暗面
PANTS = (50, 55, 50, 255)        # 深绿裤
BOOTS = (35, 30, 25, 255)        # 深棕靴
BELT = (80, 70, 50, 255)         # 皮带
FLASHLIGHT = (200, 200, 180, 255) # 手电筒
LIGHT = (255, 255, 200, 200)     # 手电光
EYE = (255, 255, 255, 255)       # 眼白
PUPIL = (20, 20, 20, 255)        # 瞳孔
MASK = (100, 100, 110, 255)      # 防毒面具/口罩
STRAP = (60, 50, 40, 255)        # 背带

def draw_pixel(x, y, color):
    if 0 <= x < img.width and 0 <= y < H:
        px[x, y] = color

def draw_rect(ox, oy, w, h, color):
    for dy in range(h):
        for dx in range(w):
            draw_pixel(ox + dx, oy + dy, color)

def draw_frame(offset_x, pose):
    """pose: 'idle', 'run1', 'run2', 'jump'"""
    ox = offset_x
    # 头部 (8x10)
    draw_rect(ox + 12, 2, 8, 10, SKIN)
    # 头发
    draw_rect(ox + 11, 1, 10, 4, HAIR)
    draw_rect(ox + 12, 4, 2, 3, HAIR)
    draw_rect(ox + 18, 4, 2, 3, HAIR)
    # 眼睛 (面向右)
    draw_pixel(ox + 17, 5, EYE)
    draw_pixel(ox + 18, 5, PUPIL)
    # 口罩
    draw_rect(ox + 13, 9, 6, 3, MASK)
    draw_rect(ox + 14, 8, 4, 1, MASK)

    # 身体/外套 (12x14)
    body_top = 12
    draw_rect(ox + 10, body_top, 12, 14, JACKET)
    # 外套暗面
    draw_rect(ox + 10, body_top, 3, 14, JACKET_D)
    # 皮带
    draw_rect(ox + 10, body_top + 10, 12, 2, BELT)

    # 手臂和腿根据姿态不同
    if pose == "idle":
        # 左臂 (后方, 暗色)
        draw_rect(ox + 8, body_top + 2, 3, 10, JACKET_D)
        # 左手
        draw_rect(ox + 7, body_top + 10, 3, 3, SKIN)
        # 右臂 (前方, 持手电)
        draw_rect(ox + 21, body_top + 2, 3, 10, JACKET)
        # 右手 + 手电
        draw_rect(ox + 23, body_top + 9, 2, 4, SKIN)
        draw_rect(ox + 24, body_top + 7, 3, 5, FLASHLIGHT)
        # 手电光
        draw_rect(ox + 27, body_top + 8, 3, 3, LIGHT)
        # 左腿
        draw_rect(ox + 11, 26, 4, 14, PANTS)
        # 右腿
        draw_rect(ox + 17, 26, 4, 14, PANTS)
        # 左靴
        draw_rect(ox + 10, 40, 5, 5, BOOTS)
        # 右靴
        draw_rect(ox + 17, 40, 5, 5, BOOTS)

    elif pose == "run1":
        # 身体微前倾
        # 左臂后摆
        draw_rect(ox + 7, body_top + 1, 3, 8, JACKET_D)
        draw_rect(ox + 6, body_top + 7, 3, 3, SKIN)
        # 右臂前伸
        draw_rect(ox + 22, body_top + 1, 3, 8, JACKET)
        draw_rect(ox + 24, body_top + 6, 2, 4, SKIN)
        draw_rect(ox + 25, body_top + 4, 3, 5, FLASHLIGHT)
        draw_rect(ox + 28, body_top + 5, 3, 3, LIGHT)
        # 左腿前跨
        draw_rect(ox + 13, 26, 4, 12, PANTS)
        draw_rect(ox + 13, 38, 5, 5, BOOTS)
        # 右腿后蹬
        draw_rect(ox + 17, 26, 4, 10, PANTS)
        draw_rect(ox + 16, 36, 5, 5, BOOTS)

    elif pose == "run2":
        # 身体微前倾 (与run1交替)
        # 左臂前摆
        draw_rect(ox + 8, body_top + 1, 3, 8, JACKET_D)
        draw_rect(ox + 7, body_top + 6, 3, 3, SKIN)
        # 右臂后摆
        draw_rect(ox + 21, body_top + 1, 3, 8, JACKET)
        draw_rect(ox + 22, body_top + 7, 2, 4, SKIN)
        draw_rect(ox + 23, body_top + 5, 3, 5, FLASHLIGHT)
        draw_rect(ox + 26, body_top + 6, 3, 3, LIGHT)
        # 左腿后蹬
        draw_rect(ox + 11, 26, 4, 10, PANTS)
        draw_rect(ox + 10, 36, 5, 5, BOOTS)
        # 右腿前跨
        draw_rect(ox + 17, 26, 4, 12, PANTS)
        draw_rect(ox + 17, 38, 5, 5, BOOTS)

    elif pose == "jump":
        # 身体腾空
        # 左臂上举
        draw_rect(ox + 7, body_top - 2, 3, 8, JACKET_D)
        draw_rect(ox + 6, body_top - 4, 3, 3, SKIN)
        # 右臂上举持手电
        draw_rect(ox + 21, body_top - 2, 3, 8, JACKET)
        draw_rect(ox + 23, body_top - 4, 2, 4, SKIN)
        draw_rect(ox + 24, body_top - 6, 3, 5, FLASHLIGHT)
        draw_rect(ox + 27, body_top - 5, 3, 3, LIGHT)
        # 双腿收起
        draw_rect(ox + 11, 28, 4, 8, PANTS)
        draw_rect(ox + 17, 28, 4, 8, PANTS)
        # 靴子
        draw_rect(ox + 10, 36, 5, 4, BOOTS)
        draw_rect(ox + 17, 36, 5, 4, BOOTS)

# 生成4帧
draw_frame(0, "idle")
draw_frame(W, "run1")
draw_frame(W * 2, "run2")
draw_frame(W * 3, "jump")

# 放大4倍便于查看 (128x192 per frame)
scale = 4
big = Image.new("RGBA", (W * FRAMES * scale, H * scale), (0, 0, 0, 0))
for fy in range(H):
    for fx in range(img.width):
        c = px[fx, fy]
        if c[3] > 0:
            for dy in range(scale):
                for dx in range(scale):
                    big.putpixel((fx * scale + dx, fy * scale + dy), c)

out_path = "C:\\Users\\34407\\Documents\\my film\\backrooms_roguelite\\assets\\sprites\\player.png"
big.save(out_path)
print(f"Saved: {out_path} ({big.width}x{big.height})")
