#!/bin/bash

######### 脚本初始化和工具检测及自动安装 #########
# 颜色设置
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

echo -e "${YELLOW}开始检测必要工具...${NC}"

# 检测系统包管理器
PKG_MANAGER=""
PKG_INSTALL_CMD=""

if command -v apt-get &> /dev/null; then
  PKG_MANAGER="apt-get"
  PKG_INSTALL_CMD="apt-get install -y"
elif command -v yum &> /dev/null; then
  PKG_MANAGER="yum"
  PKG_INSTALL_CMD="yum install -y"
elif command -v dnf &> /dev/null; then
  PKG_MANAGER="dnf"
  PKG_INSTALL_CMD="dnf install -y"
elif command -v pacman &> /dev/null; then
  PKG_MANAGER="pacman"
  PKG_INSTALL_CMD="pacman -S --noconfirm"
elif command -v zypper &> /dev/null; then
  PKG_MANAGER="zypper"
  PKG_INSTALL_CMD="zypper install -y"
fi

# 映射工具名称到对应的包名（不同发行版可能不同）
declare -A tool_to_package
tool_to_package["ssh-keygen"]="openssh-client"
tool_to_package["curl"]="curl"
tool_to_package["grep"]="grep"
tool_to_package["sed"]="sed"
tool_to_package["mkdir"]="coreutils"
tool_to_package["chmod"]="coreutils"
tool_to_package["touch"]="coreutils"

# 检查必要工具是否安装
required_tools=("ssh-keygen" "curl" "grep" "sed" "mkdir" "chmod" "touch")
missing_tools=()

for tool in "${required_tools[@]}"; do
  if ! command -v "$tool" &> /dev/null; then
    missing_tools+=("$tool")
  fi
done

# 如果有缺失工具，尝试自动安装
if [ ${#missing_tools[@]} -ne 0 ]; then
  echo -e "${YELLOW}检测到以下必要工具未安装:${NC}"
  for tool in "${missing_tools[@]}"; do
    echo "- $tool"
  done

  if [ -z "$PKG_MANAGER" ]; then
    echo -e "${RED}无法检测到系统包管理器，请手动安装缺失工具后再运行此脚本。${NC}"
    echo -e "${YELLOW}通常需要安装以下包: openssh-client curl grep sed coreutils${NC}"
    exit 1
  fi

  echo -e "${YELLOW}检测到包管理器: $PKG_MANAGER，将尝试自动安装缺失工具...${NC}"

  # 请求权限执行 sudo 操作
  echo -e "${YELLOW}需要管理员权限安装软件包。${NC}"

  # 检查是否可以使用 sudo
  if ! command -v sudo &> /dev/null; then
    echo -e "${RED}系统中没有 sudo 命令。请以 root 身份运行此脚本或手动安装缺失的工具。${NC}"
    exit 1
  fi

  # 安装缺失的工具
  for tool in "${missing_tools[@]}"; do
    package=${tool_to_package["$tool"]}
    echo -e "${YELLOW}正在安装 $tool (包名: $package)...${NC}"

    if ! sudo $PKG_INSTALL_CMD $package; then
      echo -e "${RED}安装 $tool 失败！${NC}"
      echo -e "${YELLOW}请尝试手动安装:${NC} sudo $PKG_INSTALL_CMD $package"
      exit 1
    fi
  done

  # 检查是否所有工具现在都可用了
  still_missing=()
  for tool in "${missing_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      still_missing+=("$tool")
    fi
  done

  if [ ${#still_missing[@]} -ne 0 ]; then
    echo -e "${RED}以下工具安装后仍不可用:${NC}"
    for tool in "${still_missing[@]}"; do
      echo "- $tool"
    done
    echo -e "${YELLOW}请尝试手动安装这些工具后再运行此脚本。${NC}"
    exit 1
  fi

  echo -e "${GREEN}所有缺失工具已成功安装！${NC}"
else
  echo -e "${GREEN}所有基本工具已安装！${NC}"

# 检测网络连接和网络相关工具
echo -e "${YELLOW}正在测试网络连接...${NC}"
if ! ping -c 1 github.com &> /dev/null && ! ping -c 1 8.8.8.8 &> /dev/null; then
  echo -e "${RED}网络连接似乎有问题。无法连接到外部网络。${NC}"
  echo -e "${YELLOW}请检查您的网络连接后再重试。${NC}"
  echo -e "${YELLOW}是否仍然继续运行脚本? (y/n)${NC}"
  read -r continue_without_network
  if [[ ! "$continue_without_network" =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# 检测并安装其他可能需要的网络工具
network_tools=("dig" "host" "nc" "netstat")
network_packages=("dnsutils" "bind-utils" "net-tools" "netcat")
missing_net_tools=()

for i in "${!network_tools[@]}"; do
  tool="${network_tools[$i]}"
  if ! command -v "$tool" &> /dev/null; then
    missing_net_tools+=("$i")
  fi
done

if [ ${#missing_net_tools[@]} -ne 0 ] && [ -n "$PKG_MANAGER" ]; then
  echo -e "${YELLOW}检测到一些有用的网络工具未安装，建议安装这些工具以提高脚本稳定性。${NC}"
  echo -e "${YELLOW}是否要安装这些网络工具? (y/n)${NC}"
  read -r install_net_tools

  if [[ "$install_net_tools" =~ ^[Yy]$ ]]; then
    for i in "${missing_net_tools[@]}"; do
      tool="${network_tools[$i]}"
      package="${network_packages[$i]}"
      echo -e "${YELLOW}正在安装 $tool (包名: $package)...${NC}"

      sudo $PKG_INSTALL_CMD $package || {
        echo -e "${YELLOW}安装 $package 失败，但这不会影响脚本的基本功能。${NC}"
      }
    done
  fi
fi

echo -e "${GREEN}所有必要工具准备就绪！${NC}"
fi

########## ready key #########
## GitHub SSH 自动配置脚本
## 该脚本将:
## 1. 生成 SSH 密钥对
## 2. 显示公钥以便您添加到 GitHub
## 3. 创建 SSH 配置文件
## 4. 测试 GitHub 连接
#
#echo -e "${YELLOW}开始设置 GitHub SSH 连接...${NC}"
#
## 确保 .ssh 目录存在
#if ! mkdir -p ~/.ssh 2>/dev/null; then
#  echo -e "${RED}无法创建 ~/.ssh 目录，请检查权限！${NC}"
#  exit 1
#fi
#
#cd ~/.ssh || {
#  echo -e "${RED}无法进入 ~/.ssh 目录！${NC}"
#  exit 1
#}


## 生成新的 SSH 密钥对
#KEY_NAME="github_rsa"
#echo -e "${YELLOW}正在生成 SSH 密钥对...${NC}"
#
## 检查是否已存在密钥
#if [ -f "$KEY_NAME" ]; then
#  echo -e "${YELLOW}密钥 $KEY_NAME 已存在，是否覆盖? (y/n)${NC}"
#  read -r overwrite
#  if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
#    echo -e "${YELLOW}保留现有密钥，跳过生成步骤。${NC}"
#  else
#    ssh-keygen -t rsa -b 4096 -f "$KEY_NAME" -N "" -C "GitHub SSH Key"
#    if [ $? -ne 0 ]; then
#      echo -e "${RED}SSH 密钥生成失败!${NC}"
#      exit 1
#    fi
#    echo -e "${GREEN}SSH 密钥对已成功生成!${NC}"
#  fi
#else
#  ssh-keygen -t rsa -b 4096 -f "$KEY_NAME" -N "" -C "GitHub SSH Key"
#  if [ $? -ne 0 ]; then
#    echo -e "${RED}SSH 密钥生成失败!${NC}"
#    exit 1
#  fi
#  echo -e "${GREEN}SSH 密钥对已成功生成!${NC}"
#fi
#
## 设置合适的权限
#chmod 600 "$KEY_NAME" || {
#  echo -e "${RED}无法设置密钥文件权限！${NC}"
#  exit 1
#}
#chmod 644 "$KEY_NAME.pub" || {
#  echo -e "${RED}无法设置公钥文件权限！${NC}"
#  exit 1
#}
#
## 创建或更新 SSH 配置文件
#CONFIG_FILE=~/.ssh/config
#echo -e "${YELLOW}正在配置 SSH 设置...${NC}"
#
## 检查配置文件是否已存在
#if [ -f "$CONFIG_FILE" ]; then
#  # 检查是否已有 GitHub 配置
#  if grep -q "Host github.com" "$CONFIG_FILE"; then
#    echo -e "${YELLOW}已存在 GitHub 配置，正在更新...${NC}"
#    # 使用 sed 删除以前的 GitHub 配置块
#    sed -i '/Host github.com/,/^\s*$/d' "$CONFIG_FILE" || {
#      echo -e "${RED}更新配置文件失败！${NC}"
#      exit 1
#    }
#  fi
#else
#  echo -e "${YELLOW}创建新的 SSH 配置文件...${NC}"
#  touch "$CONFIG_FILE" || {
#    echo -e "${RED}创建配置文件失败！${NC}"
#    exit 1
#  }
#  chmod 600 "$CONFIG_FILE" || {
#    echo -e "${RED}设置配置文件权限失败！${NC}"
#    exit 1
#  }
#fi
#
## 添加新的 GitHub 配置
#echo -e "Host github.com\n  User git\n  IdentityFile ~/.ssh/$KEY_NAME\n  AddKeysToAgent yes\n" >> "$CONFIG_FILE" || {
#  echo -e "${RED}向配置文件写入内容失败！${NC}"
#  exit 1
#}
#
#echo -e "${GREEN}SSH 配置已更新!${NC}"
#
## 显示公钥
#echo -e "${YELLOW}以下是您的公钥，请将其添加到 GitHub 账户中:${NC}"
#echo ""
#if [ -f "$KEY_NAME.pub" ]; then
#  echo -e "${GREEN}$(cat "$KEY_NAME.pub")${NC}"
#else
#  echo -e "${RED}公钥文件不存在！${NC}"
#  exit 1
#fi
#echo ""
#echo -e "${YELLOW}请复制上面的公钥内容，添加到 GitHub 中的 SSH Keys 设置中。${NC}"
#echo -e "${YELLOW}在 GitHub 上：Settings > SSH and GPG keys > New SSH key${NC}"
#echo ""
#
## 等待用户确认已添加公钥到 GitHub
#read -p "按 Enter 键继续测试 GitHub 连接（请确保您已将公钥添加到 GitHub）..."
#
## 测试 GitHub 连接
#echo -e "${YELLOW}开始测试 GitHub 连接...${NC}"
#echo -e "${YELLOW}将尝试连接 60 次，每次间隔 5 秒...${NC}"
#
#max_attempts=60
#attempt=1
#connected=false
#
#while [ $attempt -le $max_attempts ]; do
#  echo -e "${YELLOW}尝试 $attempt/$max_attempts...${NC}"
#  # 添加 -o StrictHostKeyChecking=accept-new 自动接受新的主机密钥
#  if ssh -T -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q "successfully authenticated"; then
#    echo -e "${GREEN}成功连接到 GitHub!${NC}"
#    connected=true
#    break
#  else
#    echo -e "${YELLOW}连接尚未成功，5 秒后重试...${NC}"
#    sleep 5
#    attempt=$((attempt+1))
#  fi
#done
#
#if [ "$connected" = false ]; then
#  echo -e "${RED}60 次尝试后仍未能连接到 GitHub。${NC}"
#  echo -e "${YELLOW}可能的原因:${NC}"
#  echo -e "1. GitHub 公钥尚未正确添加或尚未生效"
#  echo -e "2. 网络连接问题"
#  echo -e "3. SSH 配置错误"
#  echo -e "${YELLOW}请检查以上问题并稍后再试。${NC}"
#
#  echo -e "${YELLOW}您是否仍想继续后续安装步骤? (y/n)${NC}"
#  read -r continue_anyway
#  if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
#    exit 1
#  fi
#  echo -e "${YELLOW}继续运行脚本...${NC}"
#else
#  echo -e "${GREEN}GitHub SSH 配置已完成!${NC}"
#  echo -e "${GREEN}您现在可以与 版本软件 交互。${NC}"
#fi

# 创建并进入目标目录
if ! mkdir -p /app/formal 2>/dev/null; then
  echo -e "${RED}无法创建 /app/formal 目录，请检查权限！${NC}"
  echo -e "${YELLOW}尝试在当前用户目录下创建...${NC}"

  if ! mkdir -p ~/formal 2>/dev/null; then
    echo -e "${RED}也无法在用户目录创建 formal 目录！${NC}"
    exit 1
  else
    echo -e "${GREEN}已在用户目录创建 ~/formal 目录${NC}"
    APP_DIR=~/formal
  fi
else
  APP_DIR=/app/formal
fi

cd "$APP_DIR" || {
  echo -e "${RED}无法进入 $APP_DIR 目录！${NC}"
  exit 1
}

# 将相关程序都下载到本地
# Function to download a file by ID
download_file() {
  local file_id=$1
  local output_file=$2
  local max_attempts=3
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    echo -e "${YELLOW}尝试下载 ${file_id} (尝试 $attempt/$max_attempts)...${NC}"

    # Make the initial request to get the JSON response
    echo "Requesting download link for ${file_id}..."
    response=$(curl -s -X POST \
      -H "Content-Type: application/json" \
      -H "X-Cx-Permit:51e624fe6f00" \
      -d "{\"file_id\":\"${file_id}\"}" \
      "https://key.gamingsea.top/api/release/download")

    # 检查 curl 命令是否成功
    if [ $? -ne 0 ]; then
      echo -e "${RED}网络请求失败，5秒后重试...${NC}"
      sleep 5
      attempt=$((attempt+1))
      continue
    fi

    # Extract the download URL from the JSON response
    download_url=$(echo "$response" | grep -o '"data": "[^"]*"' | sed 's/"data": "//;s/"//')

    if [ -z "$download_url" ]; then
      echo -e "${RED}无法提取下载链接，响应内容：${NC}"
      echo "$response"
      sleep 5
      attempt=$((attempt+1))
      continue
    fi

    # Download the actual file using the extracted URL
    echo "Downloading ${file_id} to ${output_file}..."
    curl -s -L "$download_url" -o "$output_file"

    if [ $? -eq 0 ] && [ -s "$output_file" ]; then
      echo -e "${GREEN}成功下载 ${output_file}${NC}"
      return 0
    else
      echo -e "${RED}下载 ${output_file} 失败，5秒后重试...${NC}"
      sleep 5
      attempt=$((attempt+1))
    fi
  done

  echo -e "${RED}经过 $max_attempts 次尝试后，下载 ${file_id} 失败${NC}"
  return 1
}

# 创建必要的目录
mkdir -p "$APP_DIR/cookies" || {
  echo -e "${RED}无法创建 cookies 目录！${NC}"
  exit 1
}

mkdir -p "$APP_DIR/log" || {
  echo -e "${RED}无法创建 log 目录！${NC}"
  exit 1
}

# 下载所需文件
echo -e "${YELLOW}开始下载所需文件...${NC}"
files_to_download=("run" "claim" "one_key_claim" "download_status")
download_failures=0

for file in "${files_to_download[@]}"; do
  if ! download_file "$file" "$file"; then
    echo -e "${RED}下载 $file 失败！${NC}"
    download_failures=$((download_failures+1))
  fi
done

if [ $download_failures -gt 0 ]; then
  echo -e "${RED}有 $download_failures 个文件下载失败。脚本可能无法正常工作。${NC}"
  echo -e "${YELLOW}您是否仍想继续? (y/n)${NC}"
  read -r continue_after_dl_fail
  if [[ ! "$continue_after_dl_fail" =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# 设置执行权限
for file in "${files_to_download[@]}"; do
  if [ -f "$APP_DIR/$file" ]; then
    chmod +x "$APP_DIR/$file" || {
      echo -e "${RED}无法为 $file 设置执行权限！${NC}"
    }
  fi
done

# 询问用户是否手动编辑配置文件
echo -e "${YELLOW}配置文件设置:${NC}"
read -p "您想手动编辑配置文件填写数据库信息吗？(y/n): " manual_edit

# 初始化数据库变量
db_host=""
db_username=""
db_password=""
db_name=""
config_server_name=""

# 根据用户选择决定如何处理配置文件
if [[ "$manual_edit" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}跳过数据库配置，您将需要稍后手动编辑 $APP_DIR/config.json 文件。${NC}"

  # 创建默认配置文件
  echo '{
  "cookie_path": "'"$APP_DIR"'/cookies/",
  "db": {
    "host": "",
    "username": "",
    "password": "",
    "name": ""
  },
  "start": 0,
  "batch": 2000,
  "watch_tag": [],
  "watch": [
    {
      "game": "游戏名字/分类名",
      "streamer": [],
      "slug": "minecraft"
    }
  ]
}' > "$APP_DIR/config.json" || {
    echo -e "${RED}创建配置文件失败！${NC}"
    exit 1
  }

  echo -e "${GREEN}已创建默认配置文件模板。${NC}"
fi

################# 自动脚本命令部分
mkdir -p "$APP_DIR/script/" || {
  echo -e "${RED}无法创建脚本目录！${NC}"
  exit 1
}

echo '#!/bin/bash
if [ $# -eq 0 ]; then
  echo "请提供至少一个进程的进程序号作为参数"
  exit 1
fi
for pid in "$@"; do
  if ps -p "$pid" > /dev/null; then
    kill "$pid"
    if [ $? -eq 0 ]; then
      echo "已成功杀死进程 $pid"
    else
      echo "无法杀死进程 $pid"
    fi
  else
    echo "进程 $pid 不存在"
  fi
done' > "$APP_DIR/script/kill_progress.sh" || {
  echo -e "${RED}创建 kill_progress.sh 脚本失败！${NC}"
}

echo '#!/bin/bash
# 检查是否已经有进程在运行
process_info=$(pgrep -af "'"$APP_DIR"'/run")
if [ -n "$process_info" ]; then
  echo "找到以下进程："
  echo "$process_info"
  pkill -f "'"$APP_DIR"'/run"
  echo "挂机进程已被杀死"
else
  echo "未找到推进度程序的进程"
fi

# 检查run文件是否存在
if [ ! -f "'"$APP_DIR"'/run" ]; then
  echo "错误: run 文件不存在！"
  exit 1
fi

# 检查权限
if [ ! -x "'"$APP_DIR"'/run" ]; then
  echo "为 run 文件添加执行权限..."
  chmod +x "'"$APP_DIR"'/run" || {
    echo "无法为 run 文件添加执行权限，请检查！"
    exit 1
  }
fi

# 启动run程序
nohup "'"$APP_DIR"'/run" > "'"$APP_DIR"'/log/run.log" 2>&1 &
echo "推进度程序已开始运行"

# 检查claim是否已在运行
get_process=$(pgrep -af "'"$APP_DIR"'/claim")
if [ -n "$get_process" ]; then
  echo "找到以下进程："
  echo "$get_process"
  pkill -f "'"$APP_DIR"'/claim"
  echo "进程已被杀死。"
else
  echo "未找到领取进程。"
fi

# 检查claim文件是否存在
if [ ! -f "'"$APP_DIR"'/claim" ]; then
  echo "错误: claim 文件不存在！"
  exit 1
fi

# 检查权限
if [ ! -x "'"$APP_DIR"'/claim" ]; then
  echo "为 claim 文件添加执行权限..."
  chmod +x "'"$APP_DIR"'/claim" || {
    echo "无法为 claim 文件添加执行权限，请检查！"
    exit 1
  }
fi

# 启动claim程序
nohup "'"$APP_DIR"'/claim" > "'"$APP_DIR"'/log/claim.log" 2>&1 &
echo "领取程序已开始运行"' > "$APP_DIR/script/start_run_and_get.sh" || {
  echo -e "${RED}创建 start_run_and_get.sh 脚本失败！${NC}"
}

echo '#!/bin/bash
ps -ef | grep "'"$APP_DIR"'/run" | grep -v grep' > "$APP_DIR/script/query.sh" || {
  echo -e "${RED}创建 query.sh 脚本失败！${NC}"
}

echo '#!/bin/bash
# 检查文件是否存在
if [ ! -f "'"$APP_DIR"'/one_key_claim" ]; then
  echo "错误: one_key_claim 文件不存在！"
  exit 1
fi

# 检查权限
if [ ! -x "'"$APP_DIR"'/one_key_claim" ]; then
  echo "为 one_key_claim 文件添加执行权限..."
  chmod +x "'"$APP_DIR"'/one_key_claim" || {
    echo "无法为 one_key_claim 文件添加执行权限，请检查！"
    exit 1
  }
fi

"'"$APP_DIR"'/one_key_claim"' > "$APP_DIR/script/stable_claim.sh" || {
  echo -e "${RED}创建 stable_claim.sh 脚本失败！${NC}"
}

echo '#!/bin/bash
# 检查文件是否存在
if [ ! -f "'"$APP_DIR"'/download_status" ]; then
  echo "错误: download_status 文件不存在！"
  exit 1
fi

# 检查权限
if [ ! -x "'"$APP_DIR"'/download_status" ]; then
  echo "为 download_status 文件添加执行权限..."
  chmod +x "'"$APP_DIR"'/download_status" || {
    echo "无法为 download_status 文件添加执行权限，请检查！"
    exit 1
  }
fi

"'"$APP_DIR"'/download_status"' > "$APP_DIR/script/status_save.sh" || {
  echo -e "${RED}创建 status_save.sh 脚本失败！${NC}"
}

# 为脚本添加执行权限
for script in "$APP_DIR"/script/*.sh; do
  chmod +x "$script" 2>/dev/null
done

# 添加别名到 bash_profile
echo "if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi" > ~/.bash_profile || {
  echo -e "${RED}更新 bash_profile 失败！${NC}"
}

echo "alias pf='$APP_DIR/script/query.sh'
alias kp='$APP_DIR/script/kill_progress.sh'
alias mpr='$APP_DIR/script/start_run_and_get.sh'
alias stsave='$APP_DIR/script/status_save.sh'
alias sc='$APP_DIR/script/stable_claim.sh'" >> ~/.bashrc

# 将目录变更命令添加到 bashrc 和 profilevim ~/.
echo "cd $APP_DIR" >> ~/.bashrc || {
  echo -e "${RED}更新 bashrc 失败！${NC}"
}

echo "cd $APP_DIR" >> ~/.profile || {
  echo -e "${RED}更新 profile 失败！${NC}"
}

# 加载别名设置
# source ~/.bash_profile 2>/dev/null || . ~/.bash_profile
source ~/.bash_profile 2>/dev/null
. ~/.bash_profile

# 确保当前脚本立即切换到目标目录
cd "$APP_DIR" || {
  echo -e "${RED}无法切换到 $APP_DIR 目录！${NC}"
  exit 1
}

echo -e "${GREEN}已切换到 $APP_DIR 目录${NC}"
echo -e "${GREEN}安装和配置已完成!${NC}"
echo -e "${YELLOW}下次登录时将自动进入 $APP_DIR 目录${NC}"

# 提供脚本目录下的文件列表
echo -e "${YELLOW}已创建以下脚本:${NC}"
ls -l "$APP_DIR/script/"

# 显示可用的别名命令
echo -e "${YELLOW}已设置以下别名命令:${NC}"
echo "pf - 查询进程"
echo "kp - 杀死指定进程"
echo "mpr - 启动运行和获取程序"
echo "stsave - 保存状态"
echo "sc - 稳定领取"

# 检查配置文件并执行 stsave 命令
if [[ ! "$manual_edit" =~ ^[Yy]$ ]]; then
  # 检查 download_status 文件是否存在并且可执行
  if [ -f "$APP_DIR/download_status" ] && [ -x "$APP_DIR/download_status" ]; then
    echo -e "${YELLOW}正在执行 stsave 命令...${NC}"
    "$APP_DIR/script/status_save.sh"
    echo -e "${GREEN}stsave 命令执行完毕${NC}"

    # 从 cookies 中获取一个 *.pkl 文件名
    echo -e "${YELLOW}正在从 cookies 目录获取文件名...${NC}"
    cookie_file=$(ls "$APP_DIR/cookies"/*.pkl 2>/dev/null | head -n 1)

    if [ -n "$cookie_file" ]; then
      # 提取文件名（不包含路径和扩展名）
      cookie_name=$(basename "$cookie_file" .pkl)
      echo -e "${GREEN}找到 cookie 文件: $cookie_name${NC}"

      # 更新配置文件中的 name 字段
      if [ -f "$APP_DIR/config.json" ]; then
        sed -i 's/"name": "",/"name": "'"$cookie_name"'",/' "$APP_DIR/config.json" || {
          echo -e "${RED}更新配置文件失败！${NC}"
        }
        echo -e "${GREEN}已更新配置文件中的 name 字段为: $cookie_name${NC}"
      else
        echo -e "${RED}配置文件不存在！${NC}"
      fi
    else
      echo -e "${RED}未找到 .pkl 文件。请稍后手动更新配置文件。${NC}"
    fi
  else
    echo -e "${RED}download_status 文件不存在或不可执行！${NC}"
  fi
else
  echo -e "${RED}请先手动编辑配置文件，然后再执行 stsave 命令！${NC}"
fi

echo -e "${RED}如果您选择了手动编辑，请确保修改 config.json 为您自己的数据库配置信息，然后执行 stsave 命令！${NC}"

# 在当前 shell 中保持在目标目录
exec bash -c "cd '$APP_DIR' && exec bash"