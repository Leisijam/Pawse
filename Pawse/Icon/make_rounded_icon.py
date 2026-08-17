#!/usr/bin/env python3
"""把方形图标处理成 macOS 圆角图标，输出圆角透明 PNG。

用法:
    python3 make_rounded_icon.py <输入图> <输出图> [边长] [圆角比例] [内容占比] [图标板占比]

- 边长：默认 1024
- 圆角比例：默认 0.2237（相对图标板尺寸，macOS Big Sur 标准图标圆角）
- 内容占比：猫图案占图标板的比例，默认 0.55（越小猫越小、板内留白越多）
- 图标板占比：白色圆角方块占整个画布的比例，默认 0.804（macOS 标准图标四周留白，
  即 1024 画布上图标板约为 824px，这样在 Dock/Launchpad 里才能跟系统图标一样大）
"""
import sys
from PIL import Image, ImageDraw


def main() -> None:
    src = sys.argv[1]
    dst = sys.argv[2]
    size = int(sys.argv[3]) if len(sys.argv) > 3 else 1024
    corner_ratio = float(sys.argv[4]) if len(sys.argv) > 4 else 0.2237
    content_ratio = float(sys.argv[5]) if len(sys.argv) > 5 else 0.55
    plate_ratio = float(sys.argv[6]) if len(sys.argv) > 6 else 0.804

    src_img = Image.open(src).convert("RGBA")

    # 定位猫图案（非白色区域）的边界框，裁掉多余白边
    fg_mask = src_img.convert("L").point(lambda p: 0 if p > 245 else 255)
    bbox = fg_mask.getbbox()
    cat = src_img.crop(bbox) if bbox else src_img

    # 图标板（白色圆角方块）尺寸：比整个画布小，四周留出透明边距
    plate_size = round(size * plate_ratio)

    # 按目标占比缩放（保持宽高比），相对图标板计算，而不是整个画布
    target = round(plate_size * content_ratio)
    cat.thumbnail((target, target), Image.LANCZOS)

    # 居中放到白色图标板上
    plate = Image.new("RGBA", (plate_size, plate_size), (255, 255, 255, 255))
    cx = (plate_size - cat.width) // 2
    cy = (plate_size - cat.height) // 2
    plate.paste(cat, (cx, cy), cat)

    # 圆角裁切：圆角内不透明、四角透明（半径相对图标板计算）
    radius = round(plate_size * corner_ratio)
    mask = Image.new("L", (plate_size, plate_size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, plate_size, plate_size], radius=radius, fill=255
    )
    plate.putalpha(mask)

    # 把图标板居中放到透明画布上，四周留白，跟其他系统图标大小一致
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = (size - plate_size) // 2
    y = (size - plate_size) // 2
    canvas.paste(plate, (x, y), plate)

    canvas.save(dst)
    print(
        f"rounded icon generated: {dst} "
        f"({size}x{size}, plate {plate_ratio:.0%}, content {content_ratio:.0%}, "
        f"corner radius {radius}px)"
    )


if __name__ == "__main__":
    main()
