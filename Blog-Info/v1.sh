#!/bin/bash
# 颜色变量
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
reset="\e[0m"
# 文章路径
postDir="./source/_posts/"

# 统计字数
countWords() {
  local postDir="$1"
  if [ -d "$postDir" ]; then
    totalPostChineseWords=$(grep -o -P "[\x{4e00}-\x{9fa5}]" "$postDir"/*.md | grep -c .)
    totalPostEnglishWords=$(grep -oE "\\b[a-zA-Z0-9]+\\b" "$postDir"/*.md | wc -l)
    totalPostWords=$((totalPostChineseWords + totalPostEnglishWords))
    nearTotalPostWords=$(awk "BEGIN {printf \"%.1f\", $totalPostWords / 1000}")
    # echo "所有 MD 文件中文字数: $totalPostChineseWords"
    # echo "所有 MD 文件英文字数: $totalPostEnglishWords"
    # echo "所有 MD 文件文字数: $totalPostWords"
    # echo "所有 MD 文件的单词数（千为单位）: ${nearTotalPostWords}k"
  else
    echo -e "${red}错误: 文章路径不存在或不是目录${reset}"
    exit 1
  fi
}

# 检查 yq 是否安装
if ! command -v yq &>/dev/null; then
  echo -e "${red}yq 未安装，请先安装 yq: https://github.com/mikefarah/yq${reset}"
  exit 1
fi
# 博客名称
blogName="$(yq '.title' <"_config.yml")"
# 博客作者
blogAuthor="$(yq '.author' <"_config.yml")"
# 博客版本
hexoVersion="$(yq '.hexo.version' <"package.json")"
# 博客主题
blogTheme="$(yq '.theme' <"_config.yml")"
# 将字符串的首字母大写
blogTheme="${blogTheme^}"
# 博客主题版本
blogThemeVersion="$(yq '.version' <"./themes/$blogTheme/package.json")"
# 文章数量
postsCount=$(find $postDir -type f -name "*.md" | wc -l)

# 全站字数（统计中英文字数）
countWords $postDir
# 文章分类
postCategories=$(awk '/categories:/,/tags/' "$postDir"/*.md | grep "  -" | sed "s/  - '//;s/'//" | tr '\n' ' ')
postCategories=$(echo "$postCategories" | grep -oE "[^ ]+" | awk '!a[$0]++{printf "%s ", $0}')
# 文章标签
postTags=$(awk '/tags:/,/categories:/' "$postDir"/*.md | grep "  -" | sed "s/  - '//;s/'//" | tr '\n' ' ')
postTags=$(echo "$postTags" | grep -oE "[^ ]+" | awk '!a[$0]++{printf "%s ", $0}')

# 打印博客信息
echo -e "\n==========================="
echo " 博客名称: $blogName"
echo " 博客作者: $blogAuthor"
echo " 博客版本: Hexo v$hexoVersion"
echo " 博客主题: $blogTheme v$blogThemeVersion"
echo " 文章数量: $postsCount 篇"
echo " 文章分类: $postCategories，"
echo " 文章标签: $postTags"
echo " 全站字数: ${nearTotalPostWords}k"
echo "==========================="

length_blogName=$(printf "%s" "$blogName" | wc -c)
length_blogAuthor=$(printf "%s" "$blogAuthor" | wc -c)
length_hexoVersion=$(printf "%s" "Hexo v$hexoVersion" | wc -c)
length_blogTheme=$(printf "%s" "$blogTheme v$blogThemeVersion" | wc -c)
length_postsCount=$(printf "%s" "$postsCount" | wc -c)
length_postCategories=$(printf "%s" "$postCategories" | wc -c)
length_postTags=$(printf "%s" "$postTags" | wc -c)
length_nearTotalPostWords=$(printf "%s" "${nearTotalPostWords}k" | wc -c)

echo "长度博客名称: $length_blogName"
echo "长度博客作者: $length_blogAuthor"
echo "长度博客版本: $length_hexoVersion"
echo "长度博客主题: $length_blogTheme"
echo "长度文章数量: $length_postsCount"
echo "长度文章分类: $length_postCategories"
echo "长度文章标签: $length_postTags"
echo "长度全站字数: $length_nearTotalPostWords"
