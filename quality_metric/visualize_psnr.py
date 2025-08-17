import cv2
import numpy as np
import os
import math
import matplotlib.pyplot as plt

# 기본 설정
folder = "captures"
max_pairs = 10  # dirty_0000~0009.png / filtered_0000~0009.png

# PSNR 함수
def compute_psnr(img1, img2):
    mse = np.mean((img1.astype(np.float32) - img2.astype(np.float32))**2)
    if mse == 0: return 100
    return 20 * math.log10(255.0 / math.sqrt(mse))


# 데이터 읽고 PSNR 저장
psnrs = []
dirty_imgs = []
filtered_imgs = []
for i in range(max_pairs):
    d = cv2.imread(f"{folder}/dirty_{i:04d}.png")
    f = cv2.imread(f"{folder}/filtered_{i:04d}.png")
    if d is None or f is None:
        print(f"skip {i}")
        continue
    psnr = compute_psnr(d, f)
    psnrs.append(psnr)
    dirty_imgs.append(d)
    filtered_imgs.append(f)

# --------------------------- ① PSNR 라인 그래프
plt.figure(figsize=(6,4))
plt.plot(psnrs, marker='o')
plt.title("PSNR over samples")
plt.xlabel("Frame index")
plt.ylabel("PSNR (dB)")
plt.ylim([0, max(psnrs)+5])
plt.grid()
plt.show()

# --------------------------- ② 표 형태 출력
print("\n=== PSNR Table ===")
for idx, val in enumerate(psnrs):
    print(f"[{idx:02d}]  {val:.2f} dB")
print(f"Average : {np.mean(psnrs):.2f} dB")

# --------------------------- ③ 콜라주 (Dirty vs Filtered 썸네일 비교)
h, w, _ = dirty_imgs[0].shape
thumbs = []
for dimg, fimg, val in zip(dirty_imgs, filtered_imgs, psnrs):
    # resize thumbnail width=256
    scale = 256 / w
    dsm = cv2.resize(dimg, (256, int(h*scale)))
    fsm = cv2.resize(fimg, (256, int(h*scale)))
    cat = np.hstack([dsm, fsm])
    # put text of psnr
    cv2.putText(cat, f"PSNR:{val:.2f}dB", (10,30),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0,255,0), 2)
    thumbs.append(cat)
collage = cv2.vconcat(thumbs)
cv2.imshow("Dirty (left) vs Filtered (right)", collage)
cv2.waitKey(0)
cv2.destroyAllWindows()