import cv2
"""
    主义写注释，每一步的、每个包的、每个函数的、
"""
img = cv2.imread("./res/1.jpg")
# 写入路径
"""
    :param 输出路径 + 文件名
    :param 哪张图片
"""
cv2.imwrite("./out/1_out.jpg", cv2.Canny(img, 192, 175))
# 图片展示
cv2.imshow('edge', cv2.imread("./out/1_out.jpg"))
