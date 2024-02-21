#!/bin/bash

# 检查 Node.js、Git 是否存在
checkEnv() {
  if ! type git &>/dev/null && ! type node &>/dev/null; then
    echo -e "\n\e[31m未安装 Node.js 和 Git，请安装后运行脚本\e[0m"
    echo -e "\e[31mGit 安装视频: https://www.bilibili.com/video/BV1Rb4y1C7z1/\e[0m"
    echo -e "\e[31mNode.js 安装视频: https://www.bilibili.com/video/BV12h411z7Kq/\e[0m"
    exit 1
  fi
  if ! type node &>/dev/null; then
    echo -e "\n\e[31m未安装 Node.js，请安装后运行脚本\e[0m"
    echo -e "\e[31mNode.js 安装视频: https://www.bilibili.com/video/BV12h411z7Kq/\e[0m"
    exit 1
  fi
  if ! type git &>/dev/null; then
    echo -e "\n\e[31m未安装 Git，请安装后运行脚本\e[0m"
    echo -e "\e[31mGit 安装视频: https://www.bilibili.com/video/BV1Rb4y1C7z1/\e[0m"
    exit 1
  fi
}

# 倒计时
countDown() {
  local seconds="$1"
  for ((time = seconds; time >= 0; time--)); do
    if [ $time -eq 0 ]; then
      echo -ne "\r倒计时结束，开始安装 Hexo"
    else
      echo -ne "\e[3$((RANDOM % 10 % 8))m\r倒计时 ${time}s \e[0m"
      sleep 1
    fi
  done
  echo
}

# 异步执行指令+加载动画
asyncCommand() {
  local command="$1"
  local message="$2"

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
  # if $command &>/dev/null; then
  if [ $? -eq 0 ]; then
    echo -e "\r [\e[1;32m✔\e[0m] $message"
  else
    echo -e "\r [\e[1;31m✖\e[0m] $message"
  fi
}

# 主程序
checkEnv
if checkEnv; then
  echo -e "\e[1;33m提示\e[0m: 安装 Hexo 前，请确认您的网络环境良好"
  countDown 5
  echo -ne "请输入博客文件夹名称: "
  read -r blogRootPath
  while true; do
    if [ -d "$blogRootPath" ]; then
      echo -ne "文件夹名称重复，请重新输入: "
      read -r blogRootPath
    else
      mkdir "$blogRootPath"
      echo -e " [\e[1;32m✔\e[0m] 新建博客文件夹"
      break
    fi
  done
  startTime="$(date +%s -d "$(date "+%Y-%m-%d %H:%M:%S")")"
  # 安装 Hexo 框架
  asyncCommand "npm install -g hexo-cli" "安装 Hexo 框架"
  # Hexo 初始化
  asyncCommand "hexo init $blogRootPath" "Hexo 初始化"
  endTime="$(date +%s -d "$(date "+%Y-%m-%d %H:%M:%S")")"
  useTime=$((("$endTime" - "$startTime") / 1))
  echo -e "\n博客安装完成，用时 \e[33m${useTime}s\e[0m\n"
  echo -e "博客路径: \e[1;33m$(pwd)/$blogRootPath\e[0m"
fi
