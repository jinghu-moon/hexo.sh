#!/bin/bash
# set -x
# 颜色变量
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
blue="\e[34m"
reset="\e[0m"
# 文章路径
postDir="./source/_posts/"
# 资源路径
assetsDir="./public/"

startTime="$(date +%s)"

# 统计字数
countWords() {
  local postDir="$1"
  if [ -n "$(find "$postDir" -type f -name "*.md" 2>/dev/null)" ]; then
    totalPostChineseWords=$(grep -o -P "[\x{4e00}-\x{9fa5}]" "$postDir"/*.md | grep -c .)
    totalPostEnglishWords=$(grep -oE "\b[a-zA-Z0-9]+\b" "$postDir"/*.md | wc -l)
    totalPostWords=$((totalPostChineseWords + totalPostEnglishWords))
    nearTotalPostWords="$(awk "BEGIN {printf \"%.1f\", $totalPostWords / 1000}")k"
  else
    nearTotalPostWords="0"
  fi
}

# 计算变量内容长度
countNumber() {
  local input="$1"
  # 去除 ANSI 转义码并计算长度
  input=$(echo "$input" | sed -r "s/\x1B\[[0-9;]*[mK]//g")
  # 中文字符
  chineseCharsCount=$(echo "$input" | grep -o -P "[\x{4e00}-\x{9fa5}。，、；：！\‘\’\“\”「」（）《》【】～——……]" | grep -c .)
  # 英文字符
  englishCharsCount=$(echo "$input" | grep -o -P "[a-zA-Z0-9,.:;!?'|~\()\[\]{}\-_~/\@#%\&*+=\`\"\$┃]" | grep -c .)
  # 空格
  spaceCount=$(echo "$input" | grep -o -E " " | wc -l)
  # echo "中文数量：$chineseCharsCount"
  # echo "英文数量：$englishCharsCount"
  # echo "空格数量：$spaceCount"
  allNumber=$((chineseCharsCount * 2 + englishCharsCount + spaceCount))
}

# checkEnv() {
#   # 检查 yq 是否安装
#   if ! command -v yq &>/dev/null; then
#     echo -e "${red}使用该脚本需要安装 yq。"
#     echo -e "yq 是一个轻量级、可移植的命令行 YAML/JSON 处理工具。"
#     echo -e "地址: https://github.com/mikefarah/yq${reset}"
#     exit 1
#   fi
# }

# checkEnv
# 博客信息
blogName=$(awk -F': ' '/^title:/ {print $2}' _config.yml | sed -e "s/['\"]//g" | awk '{$1=$1;print}')
blogAuthor=$(awk -F': ' '/^author:/ {print $2}' _config.yml | sed -e "s/['\"]//g" | awk '{$1=$1;print}')
hexoVersion="v$(awk -F'"' '/version/ {print $4}' ./node_modules/hexo/package.json)"
nodeVersion="$(node -v)"
npmVersion="v$(npm -v)"
blogFrame=$(echo -e "Hexo: $hexoVersion \e[1;33m|\e[0m Node: $nodeVersion \e[1;33m|\e[0m NPM: $npmVersion")
theme=$(awk -F': ' '/^theme:/ {print $2}' _config.yml | sed -e "s/['\"]//g")
blogTheme="${theme^} v$(awk -F'"' '/"version": "/ {print $4}' ./themes/"$theme"/package.json | tr -d '"')"
# # 博客名称
# blogName="$(yq '.title' <"_config.yml")"
# # 博客作者
# blogAuthor="$(yq '.author' <"_config.yml")"
# # 博客版本
# blogFrame="Hexo v$(yq '.hexo.version' <"package.json")"
# # 博客主题
# theme=$(yq -r '.theme' <_config.yml)
# themeVersion=$(yq -r '.version' <"./themes/$theme/package.json")
# blogTheme="$(tr '[:lower:]' '[:upper:]' <<<"${theme:0:1}")${theme:1} v$themeVersion"

# 文章数量
postsCount="$(find $postDir -type f -name "*.md" | wc -l) 篇"
# 全站字数（统计中英文字数）
countWords $postDir
# 统计文章分类
if [ -z "$(find "$postDir" -type f -name "*.md" 2>/dev/null)" ]; then
  postCategories="未找到 Markdown 文件"
  postTags="未找到 Markdown 文件"
else
  # 文章分类
  postCategories=$(awk '/categories:/,/tags:/{if (sub(/ - /,"")) {gsub(/[\[\]'\''",]/,""); printf "%s ", $0}}' "$postDir"/*.md)
  # 去重
  postCategories=$(echo "$postCategories" | grep -oE "[^ ]+" | sort -u | tr '\n' ' ' | sed 's/ $//')
  # 文章标签
  postTags=$(awk '/tags:/,/categories:/' "$postDir"/*.md | grep "  -" | sed "s/  - '//;s/'//" | tr '\n' ' ')
  # 去重
  postTags=$(echo "$postTags" | grep -oE "[^ ]+" | sort -u | tr '\n' ' ' | sed 's/ $//')
fi

# 统计不同格式的图片数量
jpg_count=$(find "$assetsDir" -type f -iregex '.*\.\(jpg\|jpeg\)' | wc -l)
png_count=$(find "$assetsDir" -type f -iname "*.png" | wc -l)
gif_count=$(find "$assetsDir" -type f -iname "*.gif" | wc -l)
webp_count=$(find "$assetsDir" -type f -iname "*.webp" | wc -l)
ico_count=$(find "$assetsDir" -type f -iname "*.ico" | wc -l)
svg_count=$(find "$assetsDir" -type f -iname "*.svg" | wc -l)
allImagesNumber=$(echo -e "JPG $jpg_count \e[1;33m|\e[0m PNG $png_count \e[1;33m|\e[0m WebP $webp_count \e[1;33m|\e[0m SVG $svg_count \e[1;33m|\e[0m GIF $gif_count \e[1;33m|\e[0m ICO $ico_count")

# 统计不同格式的图片数量和大小
jpg_size=$(find "$assetsDir" -type f -iregex '.*\.\(jpg\|jpeg\)' -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0f KB", total/1024; else print "0"}')
png_size=$(find "$assetsDir" -type f -iname "*.png" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
gif_size=$(find "$assetsDir" -type f -iname "*.gif" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
ico_size=$(find "$assetsDir" -type f -iname "*.ico" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
svg_size=$(find "$assetsDir" -type f -iname "*.svg" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
webp_size=$(find "$assetsDir" -type f -iname "*.webp" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
allImagesSize=$(echo -e "JPG $jpg_size \e[1;33m|\e[0m PNG $png_size \e[1;33m|\e[0m WebP $webp_size \e[1;33m|\e[0m SVG $svg_size \e[1;33m|\e[0m GIF $gif_size \e[1;33m|\e[0m ICO $ico_size")

# echo "图片数量: $allImagesNumber"
# echo "图片大小: $allImagesSize"
# JS 文件
js_count=$(find "$assetsDir" -type f -iname "*.js" | wc -l)
js_size=$(find "$assetsDir" -type f -iname "*.js" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
# CSS 文件
css_count=$(find "$assetsDir" -type f -iname "*.css" | wc -l)
css_size=$(find "$assetsDir" -type f -iname "*.css" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
# 字体数量
font_count=$(find "$assetsDir" -type f -iregex '.*\.\(ttf\|otf\|woff\|woff2\)' | wc -l)
font_size=$(find "$assetsDir" -type f -iregex '.*\.\(ttf\|otf\|woff\|woff2\)' -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0f KB", total/1024; else print "0"}')
assetfiles=$(echo -e "JS: $js_count,$js_size \e[1;33m|\e[0m CSS: $css_count,$css_size \e[1;33m|\e[0m Font: $font_count,$font_size")
# echo "资源文件: $assetfiles"

# 寻找具有最长内容的变量
maxlength=0
maxVariable=""
for variable in "$blogName" "$blogAuthor" "$blogFrame" "$blogTheme" "$postsCount" "$postCategories" "$postTags" "$nearTotalPostWords" "$allImagesNumber" "$allImagesSize" "$assetfiles"; do
  length=$(echo -n "$variable" | sed -r "s/\x1B\[[0-9;]*[mK]//g" | wc -c)
  if [ "$length" -gt "$maxlength" ]; then
    maxlength=$length
    maxVariable=$variable
  fi
done

# 计算变量长度
countNumber "$blogName"
blogNameLength=$allNumber
countNumber "$blogAuthor"
blogAuthorLength=$allNumber
countNumber "$blogFrame"
blogFrameLength=$allNumber
countNumber "$blogTheme"
blogThemeLength=$allNumber
countNumber "$postsCount"
postsCountLength=$allNumber
countNumber "$postCategories"
postCategoriesLength=$allNumber
countNumber "$postTags"
postTagsLength=$allNumber
countNumber "$nearTotalPostWords"
nearTotalPostWordsLength=$allNumber
countNumber "$allImagesNumber"
allImagesNumberLength=$allNumber
countNumber "$allImagesSize"
allImagesSizesLength=$allNumber
countNumber "$assetfiles"
assetfilesLength=$allNumber
countNumber "$maxVariable"
maxlength=$allNumber

echo "blogName: $blogNameLength"
echo "blogAuthor: $blogAuthorLength"
echo "blogFrame: $blogFrameLength"
echo "blogTheme: $blogThemeLength"
echo "postsCount: $postsCountLength"
echo "postCategories: $postCategoriesLength"
echo "postTags: $postTagsLength"
echo "nearTotalPostWords: $nearTotalPostWordsLength"
echo "maxlength 的值为 $allNumber"

# 输出指定个数的符号
# ━ 长度
lineCharNumber=$(printf "%0.s━" $(seq 1 $allNumber))
# 空格长度
blogNameSpaceNumber=$(yes " " | head -n $((maxlength - blogNameLength)) | tr -d '\n')
blogAuthorSpaceNumber=$(yes " " | head -n $((maxlength - blogAuthorLength)) | tr -d '\n')
hexoVersionSpaceNumber=$(yes " " | head -n $((maxlength - blogFrameLength)) | tr -d '\n')
blogThemeSpaceNumber=$(yes " " | head -n $((maxlength - blogThemeLength)) | tr -d '\n')
postsCountSpaceNumber=$(yes " " | head -n $((maxlength - postsCountLength)) | tr -d '\n')
postCategoriesSpaceNumber=$(yes " " | head -n $((maxlength - postCategoriesLength)) | tr -d '\n')
postTagsSpaceNumber=$(yes " " | head -n $((maxlength - postTagsLength)) | tr -d '\n')
nearTotalPostWordsSpaceNumber=$(yes " " | head -n $((maxlength - nearTotalPostWordsLength)) | tr -d '\n')
allImagesNumberSpaceNumber=$(yes " " | head -n $((maxlength - allImagesNumberLength)) | tr -d '\n')
allImagesSizeSpaceNumber=$(yes " " | head -n $((maxlength - allImagesSizesLength)) | tr -d '\n')
assetfilesSpaceNumber=$(yes " " | head -n $((maxlength - assetfilesLength)) | tr -d '\n')

# 打印博客信息
echo
echo -e "┏━━━━━━━━━━┳━$lineCharNumber━┓"
echo -e "┃ 博客名称 ┃ $blogName $blogNameSpaceNumber┃"
echo -e "┣━━━━━━━━━━╋━$lineCharNumber━┫"
echo -e "┃ 博客作者 ┃ $blogAuthor $blogAuthorSpaceNumber┃"
echo -e "┣━━━━━━━━━━╋━$lineCharNumber━┫"
echo -e "┃ 博客框架 ┃ $blogFrame $hexoVersionSpaceNumber┃"
echo -e "┣━━━━━━━━━━╋━$lineCharNumber━┫"
echo -e "┃ 博客主题 ┃ $blogTheme $blogThemeSpaceNumber┃"
echo -e "┣━━━━━━━━━━╋━$lineCharNumber━┫"
echo -e "┃ 文章数量 ┃ $postsCount $postsCountSpaceNumber┃"
echo -e "┣━━━━━━━━━━╋━$lineCharNumber━┫"
echo -e "┃ 文章分类 ┃ $postCategories $postCategoriesSpaceNumber┃"
echo -e "┣━━━━━━━━━━╋━$lineCharNumber━┫"
echo -e "┃ 文章标签 ┃ $postTags $postTagsSpaceNumber┃"
echo -e "┣━━━━━━━━━━╋━$lineCharNumber━┫"
echo -e "┃ 全站字数 ┃ $nearTotalPostWords $nearTotalPostWordsSpaceNumber┃"
echo -e "┣━━━━━━━━━━╋━$lineCharNumber━┫"
echo -e "┃ 图片数量 ┃ $allImagesNumber $allImagesNumberSpaceNumber┃"
echo -e "┣━━━━━━━━━━╋━$lineCharNumber━┫"
echo -e "┃ 图片大小 ┃ $allImagesSize $allImagesSizeSpaceNumber┃"
echo -e "┣━━━━━━━━━━╋━$lineCharNumber━┫"
echo -e "┃ 资源文件 ┃ $assetfiles $assetfilesSpaceNumber┃"
echo -e "┗━━━━━━━━━━┻━$lineCharNumber━┛"

endTime="$(date +%s)"
useTime=$((endTime - startTime))
echo -e "\n安装用时: ${yellow}${useTime}s${reset}"
