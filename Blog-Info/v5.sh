#!/bin/bash
# set -x
red="\e[31m"
yellow="\e[33m"
reset="\e[0m"
strong="\e[1m"

# 文章路径
postDir="./source/_posts/"
# 资源路径
assetsDir="./public/"
# 分类内容最大长度
maxCategoryLength=75
# 分类内容最多显示个数
maxCategoryNumber=10
# 分类内容最大长度
maxTagLength=75
# 分类内容最多显示个数
maxTagNumber=10

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
  chineseCharsCount=$(echo "$input" | grep -oP "[\x{4e00}-\x{9fa5}。，、；：！\‘\’\“\”「」（）《》【】～——……]" | grep -c .)
  noChineseCharsCount=$(echo "$input" | grep -oP "[^\x{4e00}-\x{9fa5}。，、；：！\‘\’\“\”「」（）《》【】～——……]" | grep -c .)
  allCharsCount=$((chineseCharsCount * 2 + noChineseCharsCount))
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
  blogEnv=$(echo -e "${strong}Hexo:${reset} $hexoVersion ${strong}${yellow}|${reset} ${strong}Node.js:${reset} $nodeVersion ${strong}${yellow}|${reset} ${strong}NPM:${reset} $npmVersion ${strong}${yellow}|${reset} ${strong}Theme:${reset} $blogTheme")

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
    postState=$(echo -e "$postCount ${strong}${yellow}|${reset} $totalPostWords")
    # 文章分类
    # postCategories=$(awk '/categories:/,/tags:/{if (sub(/ - /,"")) {gsub(/[\[\]'\''",]/,""); printf "%s ", $0}}' "$postDir"/*.md)
    postCategories=$(awk '/categories:/,/tags:/' "$postDir"/*.md | grep "  -" | sed "s/  - //; s/[][\"',]//g; s/,/ /g" | tr '\n' ' ')
    # 去重
    postCategories=$(echo "$postCategories" | grep -oE "[^ ]+" | sort -u | tr '\n' ' ' | sed 's/ $//')
    # 限制分类显示个数
    if [ "$(echo -n "$postCategories" | sed -r "s/\x1B\[[0-9;]*[mK]//g" | wc -m)" -ge $maxCategoryLength ]; then
      fullPostCategories=$postCategories
      postCategories=$(echo "$postCategories" | awk '{for(i=1;i<='$maxCategoryNumber';i++) {printf "%s ", $i}}' | sed 's/ $/.../')
    fi
    # 文章标签
    postTags=$(awk '/tags:/,/---/' "$postDir"/*.md | grep "  -" | sed "s/  - //; s/[][\"']//g" | tr '\n' ' ')
    # 去重
    postTags=$(echo "$postTags" | grep -oE "[^ ]+" | sort -u | tr '\n' ' ' | sed 's/ $//')
    # 限制标签显示个数
    if [ "$(echo -n "$postTags" | sed -r "s/\x1B\[[0-9;]*[mK]//g" | wc -m)" -ge $maxTagLength ]; then
      fullPostTags=$postTags
      postTags=$(echo "$postTags" | awk '{for(i=1;i<='$maxTagNumber';i++) {printf "%s ", $i}}' | sed 's/ $/.../')
    fi
  fi

  imagesCount=""
  imageSize=""
  for format in "JPG" "PNG" "GIF" "WebP" "ICO" "SVG"; do
    # 统计图片数量
    count=$(find "$assetsDir" -type f -iregex ".*\.\($format\)" | wc -l)
    # 统计图片大小
    size=$(find "$assetsDir" -type f -iregex ".*\.\($format\)" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
    imagesCount+=$(printf "${strong}%s${reset} %d ${strong}${yellow}|${reset} " "$format" "$count")
    imageSize+=$(printf "${strong}%s${reset} %s ${strong}${yellow}|${reset} " "$format" "$size")
  done
  # 去除末尾 |
  imagesCount=${imagesCount:0:-16}
  imageSize=${imageSize:0:-16}

  # JS 文件
  jsCount=$(find "$assetsDir" -type f -iname "*.js" | wc -l)
  jsSize=$(find "$assetsDir" -type f -iname "*.js" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
  # CSS 文件
  cssCount=$(find "$assetsDir" -type f -iname "*.css" | wc -l)
  cssSize=$(find "$assetsDir" -type f -iname "*.css" -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0fKB", total/1024; else print "0"}')
  # Font 文件
  fontCount=$(find "$assetsDir" -type f -iregex '.*\.\(ttf\|otf\|woff\|woff2\)' | wc -l)
  fontSize=$(find "$assetsDir" -type f -iregex '.*\.\(ttf\|otf\|woff\|woff2\)' -exec du -b {} + | awk '{total+=$1} END{if (total > 1024*1024) printf "%.2fMB", total/1024/1024; else if (total > 0) printf "%.0f KB", total/1024; else print "0"}')
  assetfiles=$(echo -e "${strong}JS:${reset} $jsCount, $jsSize ${strong}${yellow}|${reset} ${strong}CSS:${reset} $cssCount, $cssSize ${strong}${yellow}|${reset} ${strong}Font:${reset} $fontCount, $fontSize")

  # 寻找具有最长内容的变量
  maxlength=0
  for variable in "$blogName" "$blogAuthor" "$blogEnv" "$postState" "$postCategories" "$postTags" "$imagesCount" "$imageSize" "$assetfiles"; do
    countNumber "$variable"
    length=$allCharsCount
    if [ "$length" -gt "$maxlength" ]; then
      maxlength=$length
      maxVariable=$variable
      export maxVariable
    fi
  done

  # 计算变量内容长度
  for variable in "blogName" "blogAuthor" "blogEnv" "postState" "postCategories" "postTags" "imagesCount" "imageSize" "assetfiles" "maxVariable"; do
    countNumber "${!variable}"
    # 变量内容长度
    length="${variable}Length"
    eval "$length=\$allCharsCount"
    # 变量对应空格长度
    SpaceNumber="${variable}SpaceNumber"
    eval "$SpaceNumber=\$(yes ' ' | head -n \$((maxlength - length)) | tr -d '\n')"
  done
  lineCharNumber=$(printf "%0.s━" $(seq 1 "$maxlength"))

  echo -en "\033[2K${yellow}获取信息完成${reset}\n"

  # 打印博客信息
  declare -a titles=("${strong}博客名称${reset}" "${strong}博客作者${reset}" "${strong}博客环境${reset}" "${strong}文章统计${reset}" "${strong}文章分类${reset}" "${strong}文章标签${reset}" "${strong}图片数量${reset}" "${strong}图片大小${reset}" "${strong}资源文件${reset}")
  declare -a values=("$blogName" "$blogAuthor" "$blogEnv" "$postState" "$postCategories" "$postTags" "$imagesCount" "$imageSize" "$assetfiles")
  declare -a spaces=("$blogNameSpaceNumber" "$blogAuthorSpaceNumber" "$blogEnvSpaceNumber" "$postStateSpaceNumber" "$postCategoriesSpaceNumber" "$postTagsSpaceNumber" "$imagesCountSpaceNumber" "$imageSizeSpaceNumber" "$assetfilesSpaceNumber")
  echo -e "\n┏━━━━━━━━━━┳━$lineCharNumber━┓"
  for ((i = 0; i < ${#titles[@]}; i++)); do
    echo -e "┃ ${titles[$i]} ┃ ${values[$i]} ${spaces[$i]}┃"
    if ((i < ${#titles[@]} - 1)); then
      echo -e "┣━━━━━━━━━━╋━$lineCharNumber━┫"
    fi
  done
  echo -e "┗━━━━━━━━━━┻━$lineCharNumber━┛\n"

  [[ $postCategories == *"..."* ]] && echo -e "\n${yellow}完整文章分类: ${reset}$fullPostCategories" | xargs -n 8 | awk '{print (NR==1)?$0:("              "$0)}'
  [[ $postTags == *"..."* ]] && echo && echo -e "\n${yellow}完整文章标签: ${reset}$fullPostTags" | xargs -n 8 | awk '{print (NR==1)?$0:("              "$0)}'
}

startTime="$(date +%s)"
updatedTime=$(stat -c %Y "${assetsDir}index.html")
nowTime=$(date +%s)
# 单位为秒
if ((nowTime - updatedTime <= 10800)); then
  startTime="$(date +%s)"
  asyncCommand "getBlogInfo"
else
  echo -ne "在获取博客信息前，建议清理博客缓存、生成博客文件\n是否需要(Y/N): "
  while true; do
    read -r choice
    if [[ "$choice" =~ [Yy] ]]; then
      (hexo clean && hexo g) &>/dev/null
      echo -e "已生成博客文件"
      break
    elif [ -z "$choice" ]; then
      echo -ne "输入${red}为空${reset}，请重新输入: "
    elif [[ "$choice" != [YyNn] ]]; then
      echo -ne "输入${red}错误${reset}，请重新输入: "
    else
      break
    fi
  done
  asyncCommand "getBlogInfo"
fi

endTime="$(date +%s)"
useTime=$((endTime - startTime))
echo -e "\n获取信息用时: ${yellow}${useTime}s${reset}"
