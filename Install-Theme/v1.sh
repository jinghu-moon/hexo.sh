#!/bin/bash
# 颜色变量
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
reset="\e[0m"

checkEnv() {
  # 检查 yq 是否安装
  if ! command -v yq &>/dev/null; then
    echo -e "${red}使用该脚本需要安装 yq。"
    echo -e "yq 是一个轻量级、可移植的命令行 YAML/JSON 处理工具。"
    echo -e "地址: https://github.com/mikefarah/yq${reset}"
    exit 1
  fi
}

# 异步执行指令
asyncCommand() {
  local command="$1"
  local message="$2"
  ($command &>/dev/null) &
  local pid=$!
  trap 'kill $pid' EXIT
  # 默认符号数量
  nowDotCount=0
  # 最大符号数量
  maxDotCount=3
  # 符号数量变化方向
  dotCountChange=1
  # 隐藏光标
  tput civis
  while kill -0 $pid >/dev/null 2>&1; do
    dots=$(printf "%${nowDotCount}s" | tr ' ' '.')
    echo -ne "${message}${dots}\033[K\r"
    sleep 0.5
    ((nowDotCount += dotCountChange))
    ((nowDotCount == "$maxDotCount" || nowDotCount == 0)) && ((dotCountChange *= -1))
  done
  # 恢复光标
  tput cnorm
  # 取消 trap
  trap - EXIT
  wait $pid
}

checkEnv
# 获取博客已有主题数量
if [ "$(find themes/ -mindepth 1 -maxdepth 1 -type d | wc -l) " -ge 2 ]; then
  blogTheme=$(awk -F': ' '/^theme:/ {print $2}' _config.yml | sed -e "s/['\"]//g; s/\s*#.*//; s/\s*$//")
  downloadedThemes=$(find themes -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sed 's/.*/\u&/' | tr '\n' ' ')
  echo -e "当前使用主题: ${yellow}${blogTheme^}${reset}，可用主题: $downloadedThemes"
  echo -ne "输入主题名，使用已有主题；输入 ${green}0${reset} 下载新主题\n请输入: "
  while true; do
    read -r themeName
    if [[ "$themeName" == 0 ]]; then
      break
    elif [[ "${downloadedThemes,,}" == *"${themeName,,}"* ]]; then
      sed -i "s/^theme:.*/theme: $themeName/" _config.yml
      blogTheme=$(awk -F': ' '/^theme:/ {print $2}' _config.yml | sed -e "s/['\"]//g; s/\s*#.*//; s/\s*$//")
      if [ ! -f "_config.$themeName.yml" ]; then
        cp -r "./themes/$themeName/_config.yml" "./_config.$themeName.yml"
      fi
      echo -e "当前使用主题: ${yellow}${blogTheme^}${reset}"
      exit 1
    else
      echo -ne "输入${red}错误${reset}，请重新输入: "
    fi
  done
fi

echo -e "输入 ${yellow}0${reset} 查看主题推荐。\n示例: 下载 hexo-theme-fluid 主题，输入 fluid 即可。"
read -rp "请输入: " themeName
if [ "$themeName" == 0 ]; then
  echo -e "${green}[1]${reset} AnZhiYu  : 安知鱼主题，这是一个简洁美丽的 Hexo 主题。"
  echo -e "${green}[2]${reset} Butterfly: 🦋 A Hexo Theme: Butterfly"
  echo -e "${green}[3]${reset} Fluid    : 一款 Material Design 风格的 Hexo 主题。"
  echo -e "${green}[4]${reset} Icarus   : A simple, delicate, and modern theme for the static site generator Hexo."
  echo -e "${green}[5]${reset} Keep     : 🌈 A simple and light theme for Hexo. It makes you more focused on writing."
  echo -e "${green}[6]${reset} Next     : 🎉 Elegant and powerful theme for Hexo."
  echo -e "${green}[7]${reset} Redefine : Simplicity in Speed, Purity in Design: Redefine Your Hexo Journey."
  echo -e "${green}[8]${reset} Sellar   : 内置文档系统的简约商务风 Hexo 主题，支持大量的标签组件和动态数据组件。"
  echo -e "${green}[9]${reset} Yun      : ☁️  A fast & light & lovely theme for Hexo."
  echo -e "在用 Fluid 主题，比较喜欢 Sellar 主题。"
  echo -ne "输入主题编号，下载对应主题: "
  while true; do
    read -r themeName
    if [[ "$themeName" == [0-9] ]]; then
      case $themeName in
      1) themeName=AnZhiYu ;;
      2) themeName=Butterfly ;;
      3) themeName=Fluid ;;
      4) themeName=Icarus ;;
      5) themeName=Keep ;;
      6) themeName=Next ;;
      7) themeName=Redefine ;;
      8) themeName=Sellar ;;
      9) themeName=Yun ;;
      *) ;;
      esac
      break
    else
      echo -ne "输入${red}错误${reset}，请重新输入: "
    fi
  done
fi

# 检查主题是否已安装
if [ -d "themes/$themeName" ]; then
  echo "主题已存在于博客中，请输入其他主题名称。"
  exit 1
fi

matchLink=$(curl -s "https://api.github.com/search/repositories?q=hexo-theme-${themeName}+in:name&sort=stars&order=desc&per_page=1" | yq -r '.items[0].html_url')
echo "匹配链接: $matchLink"
# 确认下载
read -rp "确认下载主题 $themeName 吗？(Y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
  echo "已取消下载主题。"
  exit 1
fi

# 下载主题
asyncCommand "git clone $matchLink" "下载主题中"
echo -e "\033[2K下载主题 ${green}✔${reset}"
storeName=$(basename "$matchLink")
cp -r "${storeName}" "./themes/$themeName"
cp -r "./themes/$themeName/_config.yml" "./_config.$themeName.yml"
rm -rf "./${storeName}"
sed -i "s/^theme:.*/theme: $themeName/" _config.yml
echo -e "\033[2K配置主题 ${green}✔${reset}"
blogTheme=$(awk -F': ' '/^theme:/ {print $2}' _config.yml | sed -e "s/['\"]//g; s/\s*#.*//; s/\s*$//")
echo -e "当前使用主题: ${yellow}${blogTheme^}${reset}"
