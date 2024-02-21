#!/bin/bash
# Hexo 安装脚本
# 该脚本用于自动安装 Hexo 博客框架，并进行一些初始化设置。

# ============= 变量 =============
# 倒计时时间，单位：秒
countdownTime=5
# 颜色变量
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
reset="\e[0m"
# ===============================

# 检查 Node.js、Git 是否存在
checkEnv() {
  if ! command -v node &>/dev/null; then
    echo -e "\n${red}未安装 Node.js，请安装后运行脚本${reset}"
    echo -e "${red}Node.js 安装视频: https://www.bilibili.com/video/BV12h411z7Kq/${reset}"
    exit 1
  fi
  if ! command -v git &>/dev/null; then
    echo -e "\n${red}未安装 Git，请安装后运行脚本${reset}"
    echo -e "${red}Git 安装视频: https://www.bilibili.com/video/BV1Rb4y1C7z1/${reset}"
    exit 1
  fi
}

# 倒计时
countDown() {
  local seconds="$1"
  for time in $(seq "$seconds" -1 0); do
    if [ "$time" -eq 0 ]; then
      echo -ne "\r倒计时结束，开始安装 Hexo。"
    else
      # 不同颜色提示倒计时
      echo -ne "\e[3$((RANDOM % 10 % 8))m\r倒计时 ${time}s \e[0m"
      sleep 1
    fi
  done
}

# 异步执行指令
asyncCommand() {
  local command="$1"
  local message="$2"
  # 旋转字符
  local spinChars=("|" "/" "-" "\\")
  # local spinChars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
  # local spinChars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  # 异步执行命令
  ($command &>/dev/null) &
  local pid=$!
  # 在脚本退出时杀死后台进程
  trap 'kill $pid' EXIT
  # 显示加载动画，循环直到异步任务完成
  while ps -p $pid >/dev/null; do
    for ((i = 0; i < ${#spinChars[@]}; i++)); do
      sleep 0.2
      echo -ne "\r [${spinChars[i]}] $message"
    done
  done
  # 取消 trap
  trap - EXIT
  wait $pid
  local result=$?
  # 提示指令师傅成功执行
  if [ $result -eq 0 ]; then
    echo -e "\r [${green}✔${reset}] $message"
  else
    echo -e "\r [${red}✖${reset}] $message"
    exit 1
  fi
}

# 创建博客文件夹
createBlogFolder() {
  echo -ne "\n脚本所在目录${yellow}为空${reset}时，可输入 ${yellow}0${reset} 跳过以下步骤。"
  echo -ne "\n请输入博客文件夹名称: "
  # 用户输入博客文件夹名称
  read -r blogRootPath
  echo
  # 循环判断用户输入是否合法
  while true; do
    if [ "$blogRootPath" == 0 ]; then
      # 使用 find 命令查找当前目录下的文件和目录（不包括子目录）
      # 排除与脚本文件本身同名的文件，统计结果行数
      if [ "$(find ./ -mindepth 1 -maxdepth 1 ! -name "$(basename "$0")" | wc -l)" -eq 0 ]; then
        blogRootPath="$(date +%s)_SeeYue_Hexo_Blog"
        if ! mkdir "$blogRootPath"; then
          echo "无法创建文件夹: ${yellow}$blogRootPath${reset}，请检查权限或磁盘空间。"
          exit 1
        fi
        return 1
      else
        echo -e "${red}请将脚本放在空文件夹内。${reset}"
        exit 1
      fi
    fi
    if [[ "$blogRootPath" == *['/?*<>|\":']* ]]; then
      # 提取特殊字符，并去重
      specialChars=$(echo "$blogRootPath" | grep -oE '[/?*<>|\":]' | tr '\n' ' ' | awk -v RS=' ' '!a[$1]++{printf "%s ", $1}' | sed 's/ *$//')
      echo -ne "名称包含特殊字符: ${yellow}$specialChars${reset}，请重新输入: "
    elif [ -z "$blogRootPath" ]; then
      echo -ne "文件夹名称${yellow}为空${reset}，请重新输入: "
    elif [ -d "$blogRootPath" ]; then
      echo -ne "文件夹名称${yellow}重复${reset}，请重新输入: "
    else
      if ! mkdir "$blogRootPath"; then
        echo "无法创建文件夹: $blogRootPath，请检查权限或磁盘空间。"
        echo -e " [${red}✖${reset}] 新建 Blog 目录"
        exit 1
      fi
      # 输入合法，跳出函数
      echo -e " [${green}✔${reset}] 新建 Blog 目录"
      break
    fi
    read -r blogRootPath
  done
}

# 主程序
# 检查环境
checkEnv
echo -e "${yellow}提示${reset}: 安装 Hexo 前，请确认您的网络环境良好。"
# 倒计时
countDown $countdownTime
# 创建文件夹，循环执行，直到用户提供合法的文件夹名称
createBlogFolder
result=$?
startTime="$(date +%s)"
# 安装 Hexo 框架
if ! command -v hexo &>/dev/null; then
  asyncCommand "npm install -g hexo-cli" "安装 Hexo 框架"
else
  echo -e " [${green}✔${reset}] 安装 Hexo 框架"
fi
# Hexo 初始化
asyncCommand "hexo init $blogRootPath" "创建 Hexo 项目"
# 转移 Hexo 文件
if [[ "$result" -eq 1 ]]; then
  asyncCommand "mv -n ./$blogRootPath/.github/ ./$blogRootPath/* ./" "转移 Hexo 文件"
  rm -r ./"$blogRootPath"
  blogRootPath=./
fi
endTime="$(date +%s)"
useTime=$((endTime - startTime))
echo -e "\n安装用时: ${yellow}${useTime}s${reset}"
echo -e "博客路径: ${yellow}$(realpath "$blogRootPath")${reset}"
echo -e "还需使用该脚本，请将其放入${yellow}博客目录${reset}使用。"
