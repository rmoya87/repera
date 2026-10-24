#!/usr/bin/env python3
"""Repair transparent enclosed details in the original Repera PNG mascot.

No regeneration, resizing or alteration of the outer transparent silhouette.
Only wholly enclosed alpha gaps (including larger eyes and mouth) may be
filled, using the majority colour of surrounding fully opaque pixels.
"""
from collections import Counter, deque
from pathlib import Path
import sys
from PIL import Image

ASSETS = [
    Path("Apps/Repera/Resources/Assets.xcassets/MascotWelcome.imageset/mascot-welcome.png"),
    Path("Apps/Repera/Resources/Assets.xcassets/MascotPermissions.imageset/mascot-permissions.png"),
    Path("Apps/Repera/Resources/Assets.xcassets/MascotHero.imageset/mascot-hero.png"),
    Path("Apps/Repera/Resources/Assets.xcassets/MascotWatch.imageset/mascot-watch.png"),
]


def repair(file_path: Path, write: bool) -> tuple[int, int]:
    image = Image.open(file_path).convert("RGBA")
    width, height = image.size
    rgba = bytearray(image.tobytes())
    total = width * height
    alpha = rgba[3::4]
    visited = bytearray(total)
    external = deque()

    def neighborhood(p: int):
        x, y = p % width, p // width
        if x: yield p - 1
        if x + 1 < width: yield p + 1
        if y: yield p - width
        if y + 1 < height: yield p + width

    def push_outer(p: int):
        if alpha[p] <= 24 and not visited[p]:
            visited[p] = 1
            external.append(p)

    # Alpha 0 at the frame is genuine exterior background: never paint it.
    for x in range(width):
        push_outer(x)
        push_outer((height - 1) * width + x)
    for y in range(height):
        push_outer(y * width)
        push_outer(y * width + width - 1)
    while external:
        p = external.popleft()
        for n in neighborhood(p):
            if alpha[n] <= 24 and not visited[n]:
                visited[n] = 1
                external.append(n)

    changed = 0
    features = 0
    max_area = max(25, total // 8)
    for start in range(total):
        if alpha[start] > 24 or visited[start]:
            continue
        pending = deque([start])
        visited[start] = 1
        component = []
        colors = Counter()
        left = right = start % width
        top = bottom = start // width
        while pending:
            p = pending.popleft()
            component.append(p)
            left = min(left, p % width)
            right = max(right, p % width)
            top = min(top, p // width)
            bottom = max(bottom, p // width)
            for n in neighborhood(p):
                if alpha[n] <= 24 and not visited[n]:
                    visited[n] = 1
                    pending.append(n)
                elif alpha[n] >= 225:
                    colors[tuple(rgba[4 * n:4 * n + 3])] += 1

        # Exterior-connected gaps remain transparent; enclosed facial features should be opaque.
        if not (3 <= len(component) <= max_area and
                right - left < width * .70 and bottom - top < height * .70 and colors):
            continue
        fill = colors.most_common(1)[0][0]
        # Avoid painting see-through gaps with arbitrary pale background hues.
        for p in component:
            rgba[4 * p:4 * p + 4] = bytes((*fill, 255))
        changed += len(component)
        features += 1
        print(f"  filled feature at ({left},{top})–({right},{bottom}), "
              f"{len(component)} px, colour={fill}")

    print(f"{file_path}: {features} enclosed features, {changed} opaque pixels")
    if write and changed:
        Image.frombytes("RGBA", image.size, bytes(rgba)).save(file_path, optimize=True)
    return features, changed


if __name__ == "__main__":
    run_write = "--write" in sys.argv
    total_features = 0
    for asset in ASSETS:
        count, pixels = repair(asset, run_write)
        total_features += count
    if total_features == 0:
        print("WARNING: no enclosed alpha holes found; inspect source graphics before claiming repair.")
