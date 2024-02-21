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

# 主程序
checkEnv
if checkEnv; then
  echo -e "\e[1;33m提示\e[0m: 安装 Hexo 前，请确认您的网络环境良好"
  countDown 5
  echo -n -e "\n请输入博客文件夹名称: "
  read -r choice
  if ! mkdir "$choice" &>/dev/null; then
    echo -n -e "文件夹名称重复，请重新输入: "
    read -r choice
    mkdir "$choice"
  fi
  echo -e " [\e[1;32m✔\e[0m] 新建博客文件夹"

  # 执行 npm install -g hexo-cli 异步地，并显示加载动画
  (npm install -g hexo-cli &>/dev/null) &

  # 获取异步任务的PID
  pid=$!

  # 定义加载动画字符集
  spinChars="/-\|"

  # 循环直到异步任务完成
  while kill -0 $pid 2>/dev/null; do
    for ((i = 0; i < ${#spinChars}; i++)); do
      sleep 0.3
      echo -ne "\r [${spinChars:$i:1}] 安装 Hexo 框架"
    done
  done

  # 检查异步任务的返回状态，显示相应的结果
  if npm install -g hexo-cli &>/dev/null; then
    echo -e "\r [\e[1;32m✔\e[0m] 安装 Hexo 框架"
  else
    echo -e "\r [\e[1;31m✖\e[0m] 安装 Hexo 框架"
  fi
else
  echo -e "\n\e[1;31m该文件夹不为空，请在空文件夹中安装 Hexo，已退出脚本\e[0m"
  exit 0
fi
