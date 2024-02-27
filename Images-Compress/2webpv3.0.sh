#!/bin/bash
# set -x
# setx "path" "E:\testnpm\libwebp-1.2.2\bin;%path%"
# 判断为空
if [ -z "$(cwebp)" ]; then
  echo -e "\n\033[1;31m                使用脚本，需要进行以下操作。\033[0m"
  echo -e "\033[31m=========================================================="
  echo " ● 将 libwebp/bin 路径加入系统环境变量后，才能使用该脚本。"
  echo -e " ● libwebp: \033[4;34mhttps://storage.googleapis.com/downloads.web\n\033[0m   \033[4;34mmproject.org/releases/webp/index.html\033[0m"
  echo -e " \033[31m● 备用地址: \033[0m\033[4;34mhttps://seeyue.lanzouw.com/iomKM05foeaj\033[0m"
  echo -e "\033[31m==========================================================\n\033[0m"
  # libwebp 地址: https://storage.googleapis.com/downloads.webmproject.org/releases/webp/index.html
  exit
fi

# 开启 glob 拓展
# shopt -s extglob
# totalFiles=$(ls -d -- */)
# i=0
# for folderName in $totalFiles; do
#   folderNameArr[i]="$folderName"
#   ((i++))
# done
# ls 命令详解：https://wangchujiang.com/linux-command/c/ls.html
files=$(ls -F)
i=0
for folderName in $files; do
  # -d：如果 filename为目录，则为真
  # 参考：https://www.jianshu.com/p/9bca2509e565
  if [ -d "$folderName" ]; then
    folderNameArr[i]="$folderName"
    ((i++))
  fi
done
# 当前目录下所有文件夹
totalFolderName="${folderNameArr[*]}"

echo -e "\n\033[1;47;30m 1 \033[0m 输入存放图片的文件夹名称"
echo -e "当前目录文件夹: "
echo -e "$totalFolderName"
echo -e "\n\033[33m文件夹: \033[0m\c"
read -r inputFolderName
echo -e "\n\n\033[1;47;30m 2 \033[0m 输入并发进程数"
# echo -e "================================="
echo -e " ● 进程数、图片转换速度、脚本"
echo -e "   占用系统资源，三者成正比。"
echo -e " ● 请根据自己的情况输入合适的数字。"
# echo -e "================================="
echo -e "\n\033[33m进程数: \033[0m\c"
read -r number

############ shell 多进程  https://www.jianshu.com/p/0ae013b64e3a ############
# 设置并发进程数
threadNum="$number"
# 定义管道文件路径
tempfifo="/tmp/$$.fifo"
# 创建管道文件
mkfifo ${tempfifo}
# 使文件描述符为非阻塞式
exec 6<>${tempfifo}
rm -rf ${tempfifo}
# 为文件描述符创建占位信息
for ((m = 1; m <= "${threadNum}"; m++)); do
  {
    echo >&6
  }
done >&6

startTime="$(date +%s -d "$(date "+%Y-%m-%d %H:%M:%S")")"
# 获取输入的文件夹名称
j=0
for item in $inputFolderName; do
  inputFolderNameArr[j]="$item"
  ((j++))
done
inputFolderNames="${inputFolderNameArr[*]}"
# echo "$inputFolderNames"
echo -e "\n\n\033[1;47;30m 3 \033[0m 转换中..."
# 遍历输入的文件夹
k=0
for item in $inputFolderNames; do
  cd "$item" || exit
  # pwd
  files=$(ls)
  imgNumbers=0
  num=0
  # 统计图片数量
  for i in $files; do
    if [ "${i##*.}" != "webp" ]; then
      ((imgNumbers++))
    fi
  done
  if [ "$k" -eq "0" ]; then
    echo -e "====================="
  else
    echo -e "\n====================="
  fi
  echo -e "    文件夹  :  \033[1;37m$item\033[0m"
  echo -e "    图片数量:  \033[33m$imgNumbers\033[0m "
  echo -n "    转换图片: "
  for i in $files; do
    if [ "${i##*.}" != "webp" ]; then
      filename=${i%.*}
      read -u6
      {
        # 转换命令
        # cwebp 文档：https://developers.google.com/speed/webp/docs/cwebp
        # dwebp 文档：https://developers.google.com/speed/webp/docs/dwebp
        # 数字：压缩系数
        cwebp -progress -quiet -q 80 "$i" -o "$filename".webp
        echo >&6
      } &
      ((num++))
      backSpaceNumber=""
      for ((j = 1; j <= "${#num}"; j++)); do
        backSpaceNumber="${backSpaceNumber}\b"
      done
      case $num in
      "$num")
        echo -e "\033[33m $num\033[0m\b$backSpaceNumber\033[?25l\c"
        if [ "$num" != "$imgNumbers" ]; then
          sleep 0.5
        fi
        ;;
      esac
    fi
    ((k++))
  done
  cd ..
done
echo -e "\n=====================\n"
# 显示光标
echo -e "\033[?25h"
echo -e "\033[1;47;30m 4 \033[0m 是否删除非 Webp 格式的图片？"
echo -e "\n     \033[1;33mY\033[0m ─── 是   \033[1;33mN\033[0m ─── 否"
echo -e "\n\033[33m选择: \033[0m\c"
read -r choice
if [ "$choice" == "Y" ] || [ "$choice" == "y" ]; then
  k=0
  for item in $inputFolderNames; do
    cd "$item" || exit
    files=$(ls)
    for i in $files; do
      if [ "${i##*.}" != "webp" ]; then
        rm -f "$i"
      fi
    done
    cd ..
  done
  echo -e "\n\033[1;32m删除完毕！ \033[0m"
elif [ "$choice" == "N" ] || [ "$choice" == "n" ]; then
  endTime="$(date +%s -d "$(date "+%Y-%m-%d %H:%M:%S")")"
  useTime=$((("$endTime" - "$startTime") / 1))
  echo -e "\n\n\033[1;47;30m 5 \033[0m 脚本运行完成，用时 \033[33m${useTime}s\033[0m\n"
  wait
  # 关闭fd6管道
  exec 6>&-
  exit
else
  echo -e "\n\033[1;31m输入错误，保持原样！\033[0m"
fi
endTime="$(date +%s -d "$(date "+%Y-%m-%d %H:%M:%S")")"
useTime=$((("$endTime" - "$startTime") / 1))
echo -e "\n\n\033[1;47;30m 5 \033[0m 脚本运行完成，用时 \033[33m${useTime}s\033[0m\n"
# 结束时间
endTime="$(date +%s -d "$(date "+%Y-%m-%d %H:%M:%S")")"
useTime=$((("$endTime" - "$startTime") / 1))
echo -e "\n\n\033[1;47;30m 5 \033[0m 脚本运行完成，用时 \033[33m${useTime}s\033[0m\n"
# 脚本运行完成后，不关闭界面。
exec /bin/bash
