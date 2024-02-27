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

# 提示用户输入文件夹（可以输入多个，用空格分隔）
echo -ne "输入图片文件夹路径(多个文件夹用空格分隔)\n请输入: "
read -r -a folders
tput civis
startTime="$(date +%s)"

# 设置最大并行子进程数
max_processes=4
running_processes=0

# 遍历输入的文件夹
for folder in "${folders[@]}"; do
  # 检查文件夹是否存在
  if [ ! -d "$folder" ]; then
    echo -e "${red}文件夹 $folder 不存在${reset}"
    continue
  fi

  # 统计图片数量和大小(除 WebP 格式)
  non_webp_count=$(find "$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | wc -l)
  non_webp_size=$(find "$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -exec stat -c "%s" {} + 2>/dev/null | awk '{total += $1} END {print total}')
  # 近似，单位取 MB
  non_webp_size_format=$(find "$folder" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -exec stat -c "%s" {} + 2>/dev/null | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/ 1024; else print "0"}')

  imageNumber=$((imageNumber + non_webp_count))
  imageSize=$((imageSize + non_webp_size))

  # 输出每个文件夹的统计信息
  echo "文件夹名: $folder"
  echo "图片信息: $non_webp_count 张, $non_webp_size_format"

  current_count=0
  for image_file in "$folder"/*.{jpg,jpeg,png}; do
    if [ -f "$image_file" ]; then
      ((running_processes++))
      ((current_count++))
      echo -ne "\r转换进度: ["
      for ((i = 0; i < current_count * 50 / non_webp_count; i++)); do
        printf "="
      done
      printf "%s" "$([ "$current_count" -eq "$non_webp_count" ] && printf ">" || printf "=>")"
      for ((i = current_count * 50 / non_webp_count; i < 49; i++)); do
        printf " "
      done
      printf "] %s/%s" "$current_count" "$non_webp_count"
      timeStamp=$(date "+%3N")
      mkdir -p "./$folder/$(date '+%Y.%m.%d')_Compressed/"
      cwebp -quiet "$image_file" -o "./$folder/$(date '+%Y.%m.%d')_Compressed/$(basename "$image_file" | cut -d. -f1)_$timeStamp.webp" &
      if [ "$running_processes" -ge "$max_processes" ]; then
        wait -n
        ((running_processes--))
      fi
    fi
  done
  printf "\n"
done

wait # 等待所有子进程完成

tput cnorm
# 统计转换后的WebP图片总大小
webpSize=0
for folder in "${folders[@]}"; do
  webp_size=$(find "$folder" -type f \( -iname "*.webp" \) -exec stat -c "%s" {} + 2>/dev/null | awk '{total += $1} END {print total}')
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
