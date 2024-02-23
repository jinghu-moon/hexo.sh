#!/bin/bash
# set -x
# 开始时间
startTime="$(date +%s -d "$(date "+%Y-%m-%d %H:%M:%S")")"
echo -e
echo -e "\033[1;33m请按照界面提示，输入相应内容。\033[0m"
echo " ● 请勿双击运行该脚本"
echo " ● 文件、文件夹命名请勿含有空格"

# 判断是否已安装 derscore-cli。
if [ -z "$(underscore)" ]; then
  echo -e "\n使用该脚本，需要下载 underscore-cli。"
  echo "一个解析 JSON 的工具，仅 1.6MB 大小。"
  echo -e "\n\033[47;1;30m Y \033[0m ─── 全局安装，\033[1;47;30m N \033[0m ─── 退出脚本。"
  echo -e "\n\033[33m选择: \033[0m\c"
  read -r choice
  if [ "$choice" == "y" ]; then
    npm install -g underscore-cli
  fi
  if [ "$choice" == "n" ]; then
    exit
  fi
fi

# 获取 package.json 的 name、version（推送前）。
packageName=$(cat package.json | underscore select .name --outfmt text)
prePackageVersion=$(cat package.json | underscore select .version --outfmt text)

# 开启 glob 拓展
shopt -s extglob
# 遍历目录下所有文件夹
files=$(ls -d -- */)
# 示例：1/  2/  3/  img/  123/
i=0
for folderName in $files; do
  folderNameArr[i]="$folderName"
  ((i++))
done
# 当前目录下所有文件夹
totalFolderNames="${folderNameArr[*]}"
echo -e "\n"

# echo "============================================================="
echo "==================== Step 1 推送 NPM 包 ====================="
# echo "============================================================="

# 暂存文件夹、生成 information.txt
i=0
# rm -rf tempFolders/
# mkdir tempFolders/
for folderName in $totalFolderNames; do

  # 暂存文件夹
  cp -r "${folderNameArr[$i]}" tempFolders/"${folderNameArr[$i]}"
  # 清空 information.txt
  rm -rf tempFolders/"${folderNameArr[$i]}"information.txt
  {
    echo "文章链接："
    echo "发布时间："
  } >>tempFolders/"${folderNameArr[$i]}"information.txt
  echo -e >>tempFolders/"${folderNameArr[$i]}"information.txt
  # 获取文件夹大小
  folderSize=$(du -sh "${folderNameArr[$i]}")
  j=0
  for folderSize in $folderSize; do
    folderSizeArr[$j]=$folderSize
    ((j++))
  done
  echo "文件夹：${folderNameArr[$i]}" >>tempFolders/"${folderNameArr[$i]}"information.txt
  # 获取当前目录下文件数量
  cd tempFolders/"${folderNameArr[$i]}" || exit
  # 字符转数字，减 2，不统计 information.txt 文件、文件夹本身。
  fileNumbers=$(($(find . -maxdepth 1 | wc -l) - 2))
  echo "文件数量：$fileNumbers" >>information.txt
  cd ../../
  # 获取 folderSizeArr 第二个元素（）
  echo "文件夹大小：${folderSizeArr[$1]}B" >>tempFolders/"${folderNameArr[$i]}"information.txt
  ((i++))
done

# 函数 1 —— 保留文件夹名为当前版本号的文件夹
function delFolder() {
  k=0
  for nowFolderName in $totalFolderNames; do
    folderNameArr[$k]=$nowFolderName
    # 仅保留文件夹名为当前版本号的文件夹
    if [ "${folderNameArr[$k]}" != "$curPackageVersion" ]; then
      rm -rf "${folderNameArr[$k]}"
    fi
    ((k++))
  done
}

# 函数 2 —— 推送 NPM 包
function npmPublish() {
  echo -e "\n发布 NPM 包..."
  echo "======================================"
  # npm publish
  echo "======================================"
  if [ "$prePackageVersion" == "0.0.1" ] && [ "$answer" == "y" ]; then
    echo -e "\n文件夹 $curPackageVersion 发布完成！"
  else
    echo -e "\n文件夹 $curPackageVersion 更新完成！"
  fi
}
# 推送文件夹名为当前版本号的文件夹的包
if [ "$prePackageVersion" == "0.0.1" ]; then
  echo "是否为第一次推送？（y/n）"
  read -p "回答: " answer
  echo -e
  if [ "$answer" == "y" ]; then
    echo "版本: $prePackageVersion，首次推送。"
    curPackageVersion="$prePackageVersion"
    delFolder
    npmPublish
  else
    echo "更新版本号..."
    npm version patch >/dev/null
    # 再次获取 version
    curPackageVersion=$(cat package.json | underscore select .version --outfmt text)
    delFolder
    echo -e
    echo "版本: v$prePackageVersion ——> v$curPackageVersion"
    npmPublish
  fi
else
  echo -e "\n更新版本号..."
  npm version patch >/dev/null
  # 再次获取 version
  curPackageVersion=$(cat package.json | underscore select .version --outfmt text)
  delFolder
  echo "版本: v$prePackageVersion ——> v$curPackageVersion"
  npmPublish
fi

# 当前目录下所有的文件夹，仅包括名称为版本号的文件夹。
l=0
for element in "${folderNameArr[@]}"; do
  if [ "$element" != "$curPackageVersion" ]; then
    unset "folderNameArr[l]"
  fi
  ((l++))
done
totalFolderName="${folderNameArr[*]}"

# 推送完成后，将文件转移回来。
for folderName2 in $totalFolderNames; do
  folderNameArr[$i]=$folderName2
  cp -a tempFolders/"${folderNameArr[$i]}" ./
  ((i++))
done
rm -rf tempFolders/
echo -e "\n"
# echo "============================================================="
echo "================== Step 2 生成 getLink.txt =================="
# echo "============================================================="
echo -e
echo "1 输入存放图片的文件夹名"
echo "  ●多个文件夹，请用「空格」隔开。"
echo "  ●输入 1，为当前路径下所有文件夹名。"
echo "  ●当前目录的文件夹: $totalFolderName"
echo -e
read -p "文件夹名: " paths
echo -e
echo "2 输入 NPM 包版本"
echo "  ●输入 1，为当前版本。"
echo "  ●当前版本: $curPackageVersion。"
echo -e
read -p "版本: " version

# 获取所有文件夹
if [ "$paths" == "1" ]; then
  paths="$totalFolderName"
fi
# 默认最新版本
if [ "$version" == "1" ]; then
  version="$curPackageVersion"
fi

# 清空文本
# echo -n "" >getLink.txt
for i in $paths; do
  cd "${i}" || exit
  files=$(ls)
  echo "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬" >>../getLink.txt
  echo "以下图片链接来自文件夹: $i" >>../getLink.txt
  for filename in $files; do
    # 输入图片链接到文本
    if [ "$filename" != "information.txt" ]; then
      echo "![](https://npm.elemecdn.com/$packageName@$version/$i/$filename)" >>../getLink.txt
    fi
  done
  cd ..
  # 输入换行到文本，分隔不同文件夹。
  echo -e >>getLink.txt
done
echo -e "\n"
time2=$(date "+%Y-%m-%d %H:%M:%S")
endTime="$(date +%s -d "$time2")"
useTime=$((("$endTime" - "$startTime") / 1))

# echo "============================================================="
echo "==================== Step 3 脚本执行完毕 ===================="
# echo "============================================================="
echo "脚本运行完成，用时 ${useTime}s。"
echo "图片链接见 getLink.txt 文件。"
echo "只有 $curPackageVersion 文件夹内文件推送至 NPM。"

# shell 脚本运行完成后，不关闭界面。
exec /bin/bash
