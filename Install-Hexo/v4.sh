#!/bin/bash

# ============= 变量 =============
# 倒计时时间
countdownTime=5
# 颜色变量
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"
# ===============================

# 检查 Node.js、Git 是否存在
checkEnv() {
  if ! type git &>/dev/null && ! type node &>/dev/null; then
    echo -e "\n${RED}未安装 Node.js 和 Git，请安装后运行脚本${RESET}"
    echo -e "${RED}Git 安装视频: https://www.bilibili.com/video/BV1Rb4y1C7z1/${RESET}"
    echo -e "${RED}Node.js 安装视频: https://www.bilibili.com/video/BV12h411z7Kq/${RESET}"
    exit 1
  fi
  if ! type node &>/dev/null; then
    echo -e "\n${RED}未安装 Node.js，请安装后运行脚本${RESET}"
    echo -e "${RED}Node.js 安装视频: https://www.bilibili.com/video/BV12h411z7Kq/${RESET}"
    exit 1
  fi
  if ! type git &>/dev/null; then
    echo -e "\n${RED}未安装 Git，请安装后运行脚本${RESET}"
    echo -e "${RED}Git 安装视频: https://www.bilibili.com/video/BV1Rb4y1C7z1/${RESET}"
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
  echo
}

# 异步执行指令
asyncCommand() {
  local command="$1"
  local message="$2"
  # 异步执行命令并显示加载动画
  ($command &>/dev/null) &
  pid=$!
  spinChars="/-\|"
  # 循环直到异步任务完成
  while kill -0 $pid 2>/dev/null; do
    for ((i = 0; i < ${#spinChars}; i++)); do
      sleep 0.2
      echo -ne "\r [${spinChars:$i:1}] $message"
    done
  done
  if [ $? -eq 0 ]; then
    echo -e "\r [${GREEN}✔${RESET}] $message"
  else
    echo -e "\r [${RED}✖${RESET}] $message"
    exit 1
  fi
}

# 主程序
checkEnv
echo -e "${YELLOW}提示${RESET}: 安装 Hexo 前，请确认您的网络环境良好"
countDown $countdownTime
echo -ne "请输入博客文件夹名称: "
read -r blogRootPath
# 循环，直到用户提供合法的文件夹名称
while true; do
  if [[ "$blogRootPath" == *['/?*<>|\":']* ]]; then
    # 获取特殊字符，去重
    specialChars=$(echo "$blogRootPath" | grep -oE '[/?*<>|\":]' | tr '\n' ' ' | awk -v RS=' ' '!a[$1]++{printf "%s ", $1}' | sed 's/ *$//')
    echo -ne "名称存在特殊字符: ${YELLOW}$specialChars${RESET}，请重新输入: "
  elif [ -z "$blogRootPath" ]; then
    echo -ne "文件夹名称${YELLOW}为空${RESET}，请重新输入: "
  elif [ -d "$blogRootPath" ]; then
    echo -ne "文件夹名称${YELLOW}重复${RESET}，请重新输入: "
  else
    if ! mkdir "$blogRootPath"; then
      echo "无法创建文件夹，请检查权限或磁盘空间。"
      exit 1
    fi
    echo -e " [${GREEN}✔${RESET}] 新建博客文件夹"
    break
  fi
  read -r blogRootPath
done
startTime="$(date +%s -d "$(date "+%Y-%m-%d %H:%M:%S")")"
# 安装 Hexo 框架
asyncCommand "npm install -g hexo-cli" "安装 Hexo 框架"
# Hexo 初始化
asyncCommand "hexo init $blogRootPath" "进行 Hexo 初始化"
endTime="$(date +%s -d "$(date "+%Y-%m-%d %H:%M:%S")")"
useTime=$((("$endTime" - "$startTime") / 1))
echo -e "\n博客安装完成，用时 ${YELLOW}${useTime}s${RESET}\n"
echo -e "博客路径: ${YELLOW}$(realpath "$blogRootPath")${RESET}"
