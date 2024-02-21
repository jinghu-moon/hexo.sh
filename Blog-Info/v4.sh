#!/bin/bash

red="\e[31m"
yellow="\e[33m"
reset="\e[0m"

# 文章路径
postDir="./source/_posts/"
# 资源路径
assetsDir="./public/"

startTime="$(date +%s)"

# 异步执行指令
asyncCommand() {
  local command="$1"
  ("$command") &
  local pid=$!
  trap 'kill $pid' EXIT
  nowDotCount=0
  dotCountChange=1
  # 隐藏光标
  tput civis
  while kill -0 $pid >/dev/null 2>&1; do
    dots=$(printf "%${nowDotCount}s" | tr ' ' '.')
    echo -ne "获取信息中$dots\033[K\r"
    sleep 0.5
    ((nowDotCount += dotCountChange))
    ((nowDotCount == 3 || nowDotCount == 0)) && ((dotCountChange *= -1))
  done
  # 恢复光标
  tput cnorm
  # 取消 trap
  trap - EXIT
  wait $pid
}

# 计算变量内容长度
countNumber() {
  local input="$1"
  # 去除 ANSI 转义码
  input=$(echo "$input" | sed -r "s/\x1B\[[0-9;]*[mK]//g")
  # 中文字符
  chineseCharsCount=$(echo "$input" | grep -oP "[\x{4e00}-\x{9fa5}。，、；：！\‘\’\“\”「」（）《》【】～——……]" | grep -c .)
  # 非中文字符
  englishCharsCount=$(echo "$input" | grep -oP "[^\x{4e00}-\x{9fa5}。，、；：！\‘\’\“\”「」（）《》【】～——……]" | grep -c .)
  allCharsCount=$((chineseCharsCount * 2 + englishCharsCount))
}

getBlogInfo() {

  # 博客信息
  blogName=$(awk -F': ' '/^title:/ {print $2}' _config.yml | sed -e "s/['\"]//g; s/\s*#.*//; s/\s*$//")
  blogAuthor=$(awk -F': ' '/^author:/ {print $2}' _config.yml | sed -e "s/['\"]//g; s/\s*#.*//; s/\s*$//")
  hexoVersion="v$(awk -F'"' '/version/ {print $4}' ./node_modules/hexo/package.json)"
  nodeVersion="$(node -v)"
  npmVersion="v$(npm -v)"
  theme=$(awk -F': ' '/^theme:/ {print $2}' _config.yml | sed -e "s/['\"]//g; s/\s*#.*//; s/\s*$//")
  blogTheme="${theme^} v$(awk -F'"' '/"version": "/ {print $4}' ./themes/"$theme"/package.json | tr -d '"')"
  blogEnv=$(echo -e "Hexo: $hexoVersion \e[1;33m|\e[0m Node.js: $nodeVersion \e[1;33m|\e[0m NPM: $npmVersion \e[1;33m|\e[0m Theme: $blogTheme")

  # 文章信息
  if [ -z "$(find "$postDir" -type f -name "*.md" 2>/dev/null)" ]; then
    postState=$(echo -e "${red}未找到 Markdown 文件${reset}")
    postCategories=$(echo -e "${red}未找到 Markdown 文件${reset}")
    postTags=$(echo -e "${red}未找到 Markdown 文件${reset}")
  else
    # 文章数量
    postCount="$(find $postDir -type f -name "*.md" | wc -l) 篇"
    totalPostChineseWords=$(grep -o -P "[\x{4e00}-\x{9fa5}]" "$postDir"/*.md | grep -c .)
    totalPostEnglishWords=$(grep -oE "\b[a-zA-Z0-9]+\b" "$postDir"/*.md | wc -l)
    # 文章字数
    totalPostWords="$(awk "BEGIN {printf \"%.1fk\", ($totalPostChineseWords + $totalPostEnglishWords) / 1000}") 字"
    postState=$(echo -e "$postCount \e[1;33m|\e[0m $totalPostWords")
    # 文章分类
    # postCategories=$(awk '/categories:/,/tags:/{if (sub(/ - /,"")) {gsub(/[\[\]'\''",]/,""); printf "%s ", $0}}' "$postDir"/*.md)
    postCategories=$(awk '/categories:/,/tags:/' "$postDir"/*.md | grep "  -" | sed "s/  - //; s/[][\"',]//g; s/,/ /g" | tr '\n' ' ')
    # 去重
    postCategories=$(echo "$postCategories" | grep -oE "[^ ]+" | sort -u | tr '\n' ' ' | sed 's/ $//')
    # 如果文章分类的字符数大于或等于 80，则取 postCategories 的前 10 个单词
    if [ "$(echo -n "$postCategories" | sed -r "s/\x1B\[[0-9;]*[mK]//g" | wc -m)" -ge 60 ]; then
      fullPostCategories=$postCategories
      postCategories=$(echo "$postCategories" | awk '{for(i=1;i<=10;i++) {printf "%s ", $i}}' | sed 's/ $/.../')
    fi
    # 文章标签
    postTags=$(awk '/tags:/,/categories:/' "$postDir"/*.md | grep "  -" | sed "s/  - //; s/[][\"']//g" | tr '\n' ' ')
    # 去重
    postTags=$(echo "$postTags" | grep -oE "[^ ]+" | sort -u | tr '\n' ' ' | sed 's/ $//')
    # 如果文章分类的字符数大于或等于 80，则取 postTags 的前 10 个单词
    if [ "$(echo -n "$postTags" | sed -r "s/\x1B\[[0-9;]*[mK]//g" | wc -m)" -ge 60 ]; then
      fullPostTags=$postTags
      postTags=$(echo "$postTags" | awk '{for(i=1;i<=10;i++) {printf "%s ", $i}}' | sed 's/ $/.../')
    fi
  fi

  # 统计不同格式的图片数量
  jpg_count=$(find "$assetsDir" -type f -iregex '.*\.\(jpg\|jpeg\)' | wc -l)
  png_count=$(find "$assetsDir" -type f -iname "*.png" | wc -l)
  gif_count=$(find "$assetsDir" -type f -iname "*.gif" | wc -l)
  webp_count=$(find "$assetsDir" -type f -iname "*.webp" | wc -l)
  ico_count=$(find "$assetsDir" -type f -iname "*.ico" | wc -l)
  svg_count=$(find "$assetsDir" -type f -iname "*.svg" | wc -l)
  ImagesCount=$(echo -e "JPG $jpg_count \e[1;33m|\e[0m PNG $png_count \e[1;33m|\e[0m WebP $webp_count \e[1;33m|\e[0m SVG $svg_count \e[1;33m|\e[0m GIF $gif_count \e[1;33m|\e[0m ICO $ico_count")

  # 统计不同格式的图片大小
  jpg_size=$(find "$assetsDir" -type f -iregex '.*\.\(jpg\|jpeg\)' -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0f KB", total/1024; else print "0"}')
  png_size=$(find "$assetsDir" -type f -iname "*.png" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
  gif_size=$(find "$assetsDir" -type f -iname "*.gif" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
  ico_size=$(find "$assetsDir" -type f -iname "*.ico" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
  svg_size=$(find "$assetsDir" -type f -iname "*.svg" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
  webp_size=$(find "$assetsDir" -type f -iname "*.webp" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
  ImageSize=$(echo -e "JPG $jpg_size \e[1;33m|\e[0m PNG $png_size \e[1;33m|\e[0m WebP $webp_size \e[1;33m|\e[0m SVG $svg_size \e[1;33m|\e[0m GIF $gif_size \e[1;33m|\e[0m ICO $ico_size")

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

  # 寻找具有最长内容的变量
  maxlength=0
  for variable in "$blogName" "$blogAuthor" "$blogEnv" "$postState" "$postCategories" "$postTags" "$ImagesCount" "$ImageSize" "$assetfiles"; do
    countNumber "$variable"
    length=$allCharsCount
    if [ "$length" -gt "$maxlength" ]; then
      maxlength=$length
      maxVariable=$variable
      export maxVariable
    fi
  done

  for variable in "blogName" "blogAuthor" "blogEnv" "postState" "postCategories" "postTags" "ImagesCount" "ImageSize" "assetfiles" "maxVariable"; do
    countNumber "${!variable}"
    # 变量内容长度
    length="${variable}Length"
    eval "$length=\$allCharsCount"
    # 空格长度
    SpaceNum="${variable}SpaceNum"
    eval "$SpaceNum=\$(yes ' ' | head -n \$((maxlength - length)) | tr -d '\n')"
  done
  lineCharNumber=$(printf "%0.s━" $(seq 1 "$maxlength"))

  echo -en "\033[2K${yellow}获取信息完成${reset}\n"

  # 打印博客信息
  declare -a titles=("博客名称" "博客作者" "博客环境" "文章统计" "文章分类" "文章标签" "图片数量" "图片大小" "资源文件")
  declare -a values=("$blogName" "$blogAuthor" "$blogEnv" "$postState" "$postCategories" "$postTags" "$ImagesCount" "$ImageSize" "$assetfiles")
  declare -a spaces=("$blogNameSpaceNum" "$blogAuthorSpaceNum" "$blogEnvSpaceNum" "$postStateSpaceNum" "$postCategoriesSpaceNum" "$postTagsSpaceNum" "$ImagesCountSpaceNum" "$ImageSizeSpaceNum" "$assetfilesSpaceNum")
  echo -e "\n┏━━━━━━━━━━┳━$lineCharNumber━┓"
  for ((i = 0; i < ${#titles[@]}; i++)); do
    echo -e "┃ ${titles[$i]} ┃ ${values[$i]} ${spaces[$i]}┃"
    if ((i < ${#titles[@]} - 1)); then
      echo -e "┣━━━━━━━━━━╋━$lineCharNumber━┫"
    fi
  done
  echo -e "┗━━━━━━━━━━┻━$lineCharNumber━┛\n"
  if [[ $postCategories == *"..."* ]]; then
    echo -e "\n${yellow}完整文章分类: ${reset}$fullPostCategories" | xargs -n 8 | awk '{print (NR==1)?$0:("              "$0)}'
  fi
  if [[ $postTags == *"..."* ]]; then
    echo -e "\n${yellow}完整文章标签: ${reset}$fullPostTags" | xargs -n 8 | awk '{print (NR==1)?$0:("              "$0)}'
  fi
  endTime="$(date +%s)"
  useTime=$((endTime - startTime))
  echo -e "\n获取信息用时: ${yellow}${useTime}s${reset}"
}

updatedTime=$(stat -c %Y "${assetsDir}index.html")
nowTime=$(date +%s)
if ((nowTime - updatedTime <= 3600)); then
  asyncCommand "getBlogInfo"
else
  echo -ne "在获取博客信息前，建议清理博客缓存、生成博客文件\n是否需要(Y/N): "
  read -r choice
  if [[ "$choice" =~ [Yy] ]]; then
    (hexo clean && hexo g) &>/dev/null
    tput cnorm
    echo -e "已生成博客文件"
    asyncCommand "getBlogInfo"
  else
    asyncCommand "getBlogInfo"
  fi
fi
