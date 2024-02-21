#!/bin/bash

# ============= 变量 =============
# 倒计时时间
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
      echo -ne "\r倒计时结束，开始安装 Hexo"
    else
      # 用不同颜色提示倒计时
      echo -ne "\e[3$((RANDOM % 10 % 8))m\r倒计时 ${time}s \e[0m"
      sleep 1
    fi
  done
}

# 异步执行指令
asyncCommand() {
  local command="$1"
  local message="$2"
  local spinChars=("|" "/" "-" "\\")
  # 异步执行命令并显示加载动画
  ($command &>/dev/null) &
  local pid=$!
  # 在脚本退出时杀死后台进程
  trap 'kill $pid' EXIT
  # 循环直到异步任务完成
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
  if [ $result -eq 0 ]; then
    echo -e "\r [${green}✔${reset}] $message"
  else
    echo -e "\r [${red}✖${reset}] $message"
    exit 1
  fi
}

# 创建博客文件夹
createBlogFolder() {
  echo -ne "\n如果脚本所在目录${yellow}为空${reset}，可输入 ${yellow}0${reset} 跳过以下步骤\n请输入博客文件夹名称: "
  read -r blogRootPath
  if [ "$blogRootPath" == 0 ]; then
    # 使用 find 命令查找当前目录下的文件和目录（不包括子目录）
    # 排除与脚本文件本身同名的文件，统计结果行数
    if [ "$(find ./ -mindepth 1 -maxdepth 1 ! -name "$(basename "$0")" | wc -l)" -eq 0 ]; then
      blogRootPath="$(date +%s)_SeeYue_Blog"
      if ! mkdir "$blogRootPath"; then
        echo "无法创建文件夹: ${yellow}$blogRootPath${reset}，请检查权限或磁盘空间。"
        echo -e " [${red}✖${reset}] 新建博客文件夹"
        exit 1
      fi
      echo -e " [${green}✔${reset}] 新建博客文件夹"
      return
    else
      echo -e "${red}请将脚本放在空文件夹内${reset}"
      exit 1
    fi
  fi
  while true; do
    if [[ "$blogRootPath" == *['/?*<>|\":']* ]]; then
      specialChars=$(echo "$blogRootPath" | grep -oE '[/?*<>|\":]' | tr '\n' ' ' | awk -v RS=' ' '!a[$1]++{printf "%s ", $1}' | sed 's/ *$//')
      echo -ne "名称包含特殊字符: ${yellow}$specialChars${reset}，请重新输入: "
    elif [ -z "$blogRootPath" ]; then
      echo -ne "文件夹名称${yellow}为空${reset}，请重新输入: "
    elif [ -d "$blogRootPath" ]; then
      echo -ne "文件夹名称${yellow}重复${reset}，请重新输入: "
    else
      if ! mkdir "$blogRootPath"; then
        echo "无法创建文件夹: $blogRootPath，请检查权限或磁盘空间。"
        echo -e " [${red}✖${reset}] 新建博客文件夹"
        exit 1
      fi
      echo -e " [${green}✔${reset}] 新建博客文件夹"
      break
    fi
    read -r blogRootPath
  done
}

# 主程序
checkEnv
echo -e "${yellow}提示${reset}: 安装 Hexo 前，请确认您的网络环境良好"
countDown $countdownTime
# 循环执行，直到用户提供合法的文件夹名称
createBlogFolder
startTime="$(date +%s)"
# 安装 Hexo 框架
asyncCommand "npm install -g hexo-cli" "安装 Hexo 框架"
# Hexo 初始化
asyncCommand "hexo init $blogRootPath" "建立 Hexo 项目"

endTime="$(date +%s)"
useTime=$((endTime - startTime))
echo -e "\n博客安装完成，用时 ${yellow}${useTime}s${reset}\n"
echo -e "博客路径: ${yellow}$(realpath "$blogRootPath")${reset}"
