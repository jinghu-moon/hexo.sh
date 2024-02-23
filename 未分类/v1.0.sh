#!/bin/bash
# set -x
time1=$(date "+%Y-%m-%d %H:%M:%S")
nowTime="$(date +%s -d "$time1")"

# npm version patch
# npm publish

# 判断是否已安装 derscore-cli。
if [ -z "$(underscore)" ]; then
  npm install -g derscore-cli
fi

# 获取 package.json 的 name、version。
packageName=$(cat package.json | underscore select .name --outfmt text)
packageVersion=$(cat package.json | underscore select .version --outfmt text)

# 获取当前目录文件夹名
echo -n "" >folderName1.txt
files=$(ls)
for folderName1 in $files; do
  echo "$folderName1" >>folderName1.txt
done
sed '/package.json/d;/[a-zA-Z0-9].txt/d;/[a-zA-Z0-9].sh/d;/tempFolders/d;/.npmignore/d' folderName1.txt >folderName2.txt
rm -rf tempFolders/
i=0
for folderName2 in $(<folderName2.txt); do
  folderArr[$i]=$folderName2
  ((i++))
done
totalFolderName="${folderArr[*]}"
echo "$totalFolderName"
rm -f folderName1.txt folderName2.txt

# m1=$(cat package.json | underscore select .name)
# m2=$(cat package.json | underscore select .version)
# echo "$m1" >>temp1.txt
# echo "$m2" >>temp1.txt
# # 删除所有双引号
# data=$(sed 's/"//g' temp1.txt)
# echo "$data" >temp2.txt
# # 获取第一行
# n1=$(sed -n 1p temp2.txt)
# # 获取第二行
# n2=$(sed -n 2p temp2.txt)
# packaName=$(echo "$n1" | cut -d '[' -f2 | cut -d ']' -f1)
# packaVersion=$(echo "$n2" | cut -d '[' -f2 | cut -d ']' -f1)
# rm -f temp1.txt temp2.txt

echo -e
echo "请按照界面提示，输入相应内容。"
echo "   ======================"
echo "     请勿双击运行该脚本"
echo "   ======================"

echo -e "\n"
echo "========================================================"
echo "1、输入存放图片的文件夹名"
echo " ● 多个文件夹，请用「空格」隔开。文件夹名不要含有空格"
echo " ● 输入 1，为当前路径下所有文件夹名。"
echo " ● 当前目录的文件夹: $totalFolderName"
echo -e
read -p "文件夹名: " paths
echo -e
echo "2、输入 NPM 包版本"
echo " ● 输入 1，为当前版本。"
echo " ● 当前版本: $packageVersion。"
echo -e
read -p "版本: " version
echo "========================================================"

# 获取所有文件夹
if [ "$paths" == "1" ]; then
  paths="$totalFolderName"
fi
# 默认最新版本
if [ "$version" == "1" ]; then
  version="$packageVersion"
fi

# 清空文本
echo -n "" >getLink.txt
for i in $paths; do
  cd "${i}" || exit
  files=$(ls)
  echo "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬" >>../getLink.txt
  echo "以下图片链接来自文件夹: $i" >>../getLink.txt
  for filename in $files; do
    # 输入图片链接到文本
    echo "![](https://npm.elemecdn.com/$packageName@$version/$i/$filename)" >>../getLink.txt
  done
  cd ..
  # 输入换行到文本，分隔不同文件夹。
  echo -e >>getLink.txt
done
echo -e "\n"
time2=$(date "+%Y-%m-%d %H:%M:%S")
endTime="$(date +%s -d "$time2")"
useTime=$((("$endTime" - "$nowTime") / 1))
echo "脚本运行完成，用时 ${useTime}s。图片链接见 getLink.txt 文件。"

# shell 脚本运行完成后，不关闭界面。
exec /bin/bash
