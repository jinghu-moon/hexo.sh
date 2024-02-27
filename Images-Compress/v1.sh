#!/bin/bash
# 颜色变量
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
reset="\e[0m"

checkEnv() {
  # 检查 yq 是否安装
  if ! command -v cwebp &>/dev/null; then
    echo -e "${red}使用该脚本需要安装 libwebp, 并将 libwebp/bin 加入系统环境变量"
    echo -e "libwebp: 处理 WebP 图像格式的开源图像编码和解码库,\n可将 PNG/JPG —> WebP、WebP —> PNG"
    echo -e "地址: https://developers.google.com/speed/webp/download${reset}"
    exit 1
  fi
}
checkEnv

# 初始化变量
imageNumber=0
imageSize=0

# 提示用户输入文件夹（可以输入多个，用空格分隔）
echo -ne "输入图片文件夹路径(多个文件夹用空格分隔)\n请输入: "
read -r -a folders
# 隐藏光标
tput civis
startTime="$(date +%s)"

# 遍历输入的文件夹
for folder in "${folders[@]}"; do
  # 检查文件夹是否存在
  if [ ! -d "$folder" ]; then
    echo "文件夹 $folder 不存在"
    continue
  fi

  # 统计图片数量和大小
  images_count=$(find "$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | wc -l)
  images_size=$(find "$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -exec stat -c "%s" {} + | awk '{total += $1} END {print total}')

  # 更新累加值
  imageNumber=$((imageNumber + images_count))
  imageSize=$((imageSize + images_size))

  # 输出每个文件夹的统计信息
  echo "文件夹 $folder 图片数量: $images_count"
  echo "文件夹 $folder 图片大小: $images_size 字节"

  # 获取该文件夹中除WebP格式图片之外的图片总数
  non_webp_count=$(find "$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | wc -l)

  # 使用cwebp工具将图片转换为WebP格式，并显示进度条
  current_count=0
  for image_file in "$folder"/*.{jpg,jpeg,png}; do
    if [ -f "$image_file" ]; then
      ((current_count++))
      echo -ne "\r文件夹 $folder 转换进度: $current_count/$non_webp_count ["
      for ((i = 0; i < current_count * 50 / non_webp_count; i++)); do
        printf "="
      done
      if [ "$current_count" -eq "$non_webp_count" ]; then
        printf ">"
      else
        printf "=>"
      fi
      for ((i = current_count * 50 / non_webp_count; i < 49; i++)); do
        printf " "
      done
      printf "]"
      cwebp -quiet "$image_file" -o "${image_file%.*}.webp"
    fi
  done
  printf "\n"
done

tput cnorm
# 统计转换后的WebP图片总大小
webpSize=0
for folder in "${folders[@]}"; do
  webp_size=$(find "$folder" -type f \( -iname "*.webp" \) -exec stat -c "%s" {} + | awk '{total += $1} END {print total}')
  webpSize=$((webpSize + webp_size))
done

# 计算压缩率
compressRate=$((100000 * (imageSize - webpSize) / imageSize))
# 将压缩率转换为五位数形式，并在第二位数字后添加小数点
compressRate="${compressRate:0:2}.${compressRate:2}"
# 将压缩率转换为小数形式，并四舍五入保留两位小数
compressRate=$(printf "%.2f" "$compressRate")
# 输出累加值
echo "所有文件夹中的图片总数量为: $imageNumber"
echo "所有文件夹中的图片总大小为: $imageSize 字节"
# 输出结果
echo "压缩率: ${compressRate}%"
endTime="$(date +%s)"
useTime=$((endTime - startTime))
echo -e "\n图片压缩用时: ${yellow}${useTime}s${reset}"