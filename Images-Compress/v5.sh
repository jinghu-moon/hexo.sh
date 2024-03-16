#!/bin/bash

# 颜色变量
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
reset="\e[0m"
strong="\e[1m"
# 压缩系数，0 ~ 100
compressibilityFactor=75
# 进度条长度
progressBarLength=50
# 同时转换图片数量
# 数值大小、转换速度、CPU 占用，三者成正比
maxProcessesCount=5
# 获取电脑处理器数量
processorCount=$(($(nproc) / 2))
# 动态调整并行处理的数量，不超过系统的逻辑处理器数量的一半
maxProcessesCount=$((processorCount > maxProcessesCount ? processorCount : maxProcessesCount))
checkEnv() {
  # 检查 yq 是否安装
  if ! command -v cwebp &>/dev/null; then
    echo -e "${red}使用该脚本需要安装 libwebp, 并将 libwebp/bin 路径加入系统环境变量"
    echo -e "libwebp: 处理 WebP 图像格式的开源图像编码和解码库,\n可将 PNG/JPG —> WebP 或 WebP —> PNG"
    echo -e "地址: https://developers.google.com/speed/webp/download"
    echo -e "Windows 配置环境变量: https://www.bilibili.com/video/BV1nS4y1o7LG${reset}"
    exit 1
  fi
}

checkEnv
echo -ne "输入图片文件夹路径(多个, 空格分隔; 回车, 默认所有子文件夹)\n请输入: "
read -ra folders
# 去重
onlyFolders=$(printf "%s\n" "${folders[@]}" | sort -u)
# 存储存在和不存在的文件夹
existFolders=()
noExistFolders=()
for folder in $onlyFolders; do
  if [ -d "$folder" ]; then
    existFolders+=("$folder")
  else
    noExistFolders+=("$folder")
  fi
done

if [ ${#folders[@]} -eq 0 ]; then
  mapfile -t existFolders < <(find ./ -mindepth 1 -maxdepth 1 -type d -exec sh -c 'for dir; do ls -1q "$dir"/*.jpg "$dir"/*.png "$dir"/*.jpeg 2>/dev/null | grep -q . && echo "$dir"; done' sh {} + | sed 's|^./||')
fi

if [ ${#existFolders[@]} -eq 0 ]; then
  echo -e "\n${red}文件夹 ${noExistFolders[*]} 不存在, 退出脚本${reset}"
  exit 1
fi

echo -e "${green}已有文件夹:${reset} ${existFolders[*]}"
echo -e "${red}未有文件夹:${reset} ${noExistFolders[*]}\n"
tput civis
startTime="$(date +%s)"

imageNumber=0
imageSize=0
runningProcesses=0
# 遍历输入的文件夹
for folder in "${existFolders[@]}"; do
  # 统计图片数量和大小(除 WebP 格式)
  nonWebpCount=$(find "$folder" -type f -regex '.*\.\(jpg\|jpeg\|png\)' ! -iname "*.webp" 2>/dev/null | wc -l)
  non_webp_size=$(find "$folder" -type f -regex '.*\.\(jpg\|jpeg\|png\)' ! -iname "*.webp" -exec stat -c "%s" {} + 2>/dev/null | awk '{total += $1} END {print total}')
  # 近似，单位取 MB
  non_webp_size_format=$(find "$folder" -type f -regex '.*\.\(jpg\|jpeg\|png\)' ! -iname "*.webp" -exec stat -c "%s" {} + 2>/dev/null | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/ 1024; else print "0"}')
  imageNumber=$((imageNumber + nonWebpCount))
  imageSize=$((imageSize + non_webp_size))

  # 同名图片
  sameFiles=$(find "$folder" -type f -name "*.*" | sed -E 's|.*/||; s/\.[^.]+$//' | sort | uniq -d | while read -r name; do find "$folder" -type f -name "$name.*" -exec basename {} \;; done | tr '\n' ' ')

  # 输出每个文件夹的统计信息
  echo "文件夹名: $folder"
  echo "图片信息: $nonWebpCount 张, $non_webp_size_format"
  echo "同名图片: $sameFiles"

  currentCount=0
  while IFS= read -r -d '' image_file; do
    if [ -f "$image_file" ]; then
      ((runningProcesses++))
      ((currentCount++))
      echo -ne "\r转换进度: ["
      for ((i = 0; i < currentCount * progressBarLength / nonWebpCount; i++)); do
        printf "="
      done
      printf "%s" "$([ "$currentCount " -eq "$nonWebpCount" ] && printf ">" || printf "=>")"
      for ((i = currentCount * progressBarLength / nonWebpCount; i < progressBarLength - 1; i++)); do
        printf " "
      done
      printf "] %s/%s" "$currentCount" "$nonWebpCount"
      # 三位毫秒
      timeStamp=$(date "+%3N")
      mkdir -p "./$folder/$(date '+%Y.%m.%d')_Compressed/"
      # 同名文件
      if [[ " $sameFiles" =~ $(basename "$image_file") ]]; then
        cwebp -q $compressibilityFactor -quiet "$image_file" -o "./$folder/$(date '+%Y.%m.%d')_Compressed/$(basename "$image_file" | sed 's/\.[^.]*$/.webp/')_$timeStamp.webp" &
      else
        cwebp -q $compressibilityFactor -quiet "$image_file" -o "./$folder/$(date '+%Y.%m.%d')_Compressed/$(basename "$image_file" | sed 's/\.[^.]*$/.webp/')" &
      fi
      if [ "$runningProcesses" -ge "$maxProcessesCount" ]; then
        wait -n
        ((runningProcesses--))
      fi
    fi
  done < <(find "$folder" -type f -regex '.*\.\(jpg\|jpeg\|png\)' -print0 2>/dev/null)
  printf "\n"
  if [ "$folder" != "${existFolders[-1]}" ]; then
    echo -e "${strong}${yellow}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
  fi
done

wait # 等待所有子进程完成

tput cnorm
# 统计转换后的 WebP 图片总大小
webpSize=0
for folder in "${existFolders[@]}"; do
  webp_size=$(find "./$folder/$(date '+%Y.%m.%d')_Compressed/" -type f -iname "*.webp" -exec stat -c "%s" {} + 2>/dev/null | awk '{total += $1} END {print total}')
  webpSize=$((webpSize + webp_size))
done

# 计算压缩率并四舍五入保留两位小数
compressRate=$(awk "BEGIN {printf \"%.2f\", 100 * ($imageSize - $webpSize) / $imageSize}")
imageSizeFormat=$(echo "$imageSize" | awk '{if ($1 > 1024*1024) printf "%.2fMB", $1/1024/1024; else if ($1 > 0) printf "%.0fKB", $1/1024; else print "0"}')
webpSizeFormat=$(echo "$webpSize" | awk '{if ($1 > 1024*1024) printf "%.2fMB", $1/1024/1024; else if ($1 > 0) printf "%.0fKB", $1/1024; else print "0"}')
# 输出累加值
echo -e "\n图片总数量: $imageNumber 张"
echo "图片总大小(压缩前): $imageSizeFormat"
echo "图片总大小(压缩后): $webpSizeFormat"
# 输出结果
echo "压缩率: ${compressRate}%"
endTime="$(date +%s)"
useTime=$((endTime - startTime))
echo -e "\n图片压缩用时: ${yellow}${useTime}s${reset}"