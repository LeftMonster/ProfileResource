#/bin/bash

######### ready key
# GitHub SSH 自动配置脚本
# 该脚本将:
# 1. 生成 SSH 密钥对
# 2. 显示公钥以便您添加到 GitHub
# 3. 创建 SSH 配置文件
# 4. 测试 GitHub 连接

# 颜色设置
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

echo -e "${YELLOW}开始设置 GitHub SSH 连接...${NC}"

# 确保 .ssh 目录存在
mkdir -p ~/.ssh
cd ~/.ssh

# 生成新的 SSH 密钥对
KEY_NAME="github_rsa"
echo -e "${YELLOW}正在生成 SSH 密钥对...${NC}"
ssh-keygen -t rsa -b 4096 -f "$KEY_NAME" -N "" -C "GitHub SSH Key"

if [ $? -ne 0 ]; then
    echo -e "${RED}SSH 密钥生成失败!${NC}"
    exit 1
fi

echo -e "${GREEN}SSH 密钥对已成功生成!${NC}"

# 设置合适的权限
chmod 600 "$KEY_NAME"
chmod 644 "$KEY_NAME.pub"

# 创建或更新 SSH 配置文件
CONFIG_FILE=~/.ssh/config
echo -e "${YELLOW}正在配置 SSH 设置...${NC}"

# 检查配置文件是否已存在
if [ -f "$CONFIG_FILE" ]; then
    # 检查是否已有 GitHub 配置
    if grep -q "Host github.com" "$CONFIG_FILE"; then
        echo -e "${YELLOW}已存在 GitHub 配置，正在更新...${NC}"
        # 使用 sed 删除以前的 GitHub 配置块
        sed -i '/Host github.com/,/^\s*$/d' "$CONFIG_FILE"
    fi
else
    echo -e "${YELLOW}创建新的 SSH 配置文件...${NC}"
    touch "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
fi

# 添加新的 GitHub 配置
echo -e "Host github.com\n  User git\n  IdentityFile ~/.ssh/$KEY_NAME\n  AddKeysToAgent yes\n" >> "$CONFIG_FILE"

echo -e "${GREEN}SSH 配置已更新!${NC}"

# 显示公钥
echo -e "${YELLOW}以下是您的公钥，请将其添加到 GitHub 账户中:${NC}"
echo ""
echo -e "${GREEN}$(cat "$KEY_NAME.pub")${NC}"
echo ""
echo -e "${YELLOW}请复制上面的公钥内容，添加到 GitHub 中的 SSH Keys 设置中。${NC}"
echo -e "${YELLOW}在 GitHub 上：Settings > SSH and GPG keys > New SSH key${NC}"
echo ""

# 等待用户确认已添加公钥到 GitHub
read -p "按 Enter 键继续测试 GitHub 连接（请确保您已将公钥添加到 GitHub）..."

# 测试 GitHub 连接
echo -e "${YELLOW}开始测试 GitHub 连接...${NC}"
echo -e "${YELLOW}将尝试连接 60 次，每次间隔 5 秒...${NC}"

max_attempts=60
attempt=1
connected=false

while [ $attempt -le $max_attempts ]; do
    echo -e "${YELLOW}尝试 $attempt/$max_attempts...${NC}"
    # 添加 -o StrictHostKeyChecking=accept-new 自动接受新的主机密钥
    ssh -T -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q "successfully authenticated"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}成功连接到 GitHub!${NC}"
        connected=true
        break
    else
        echo -e "${YELLOW}连接尚未成功，5 秒后重试...${NC}"
        sleep 5
        attempt=$((attempt+1))
    fi
done

if [ "$connected" = false ]; then
    echo -e "${RED}60 次尝试后仍未能连接到 GitHub。${NC}"
    echo -e "${YELLOW}可能的原因:${NC}"
    echo -e "1. GitHub 公钥尚未正确添加或尚未生效"
    echo -e "2. 网络连接问题"
    echo -e "3. SSH 配置错误"
    echo -e "${YELLOW}请检查以上问题并稍后再试。${NC}"
    exit 1
fi

echo -e "${GREEN}GitHub SSH 配置已完成!${NC}"
echo -e "${GREEN}您现在可以与 版本软件 交互。${NC}"

mkdir -p /app/formal
cd /app/formal


#git clone git@github.com:LeftMonster/month-version.git


# 将相关程序都下载到本地
wget --header="Content-Type: application/json" \
     --post-data='{"file_id":"run"}' \
     https://key.gamingsae.top/api/release/download/run \
     -O run

wget https://key.gamingsae.top/api/release/download/claim
wget --header="Content-Type: application/json" \
     --post-data='{"file_id":"claim"}' \
     https://key.gamingsae.top/api/release/download/claim \
     -O claim

wget --header="Content-Type: application/json" \
     --post-data='{"file_id":"one_key_claim"}' \
     https://key.gamingsae.top/api/release/download/one_key_claim \
     -O one_key_claim


mkdir -p /app/formal/cookies
mkdir -p /app/formal/log
echo '{
    "cookie_path": "/app/formal/cookies/",
    "db": {
        "host": "",
        "username": "",
        "password": "",
        "name": ""
    },
    "config_server":{
        "name": "",
        "start": 0,
        "batch": 2000
    },
    "watch_tag": ["DropsEnabled", "启用掉宝", "DropsAtivados", "Drops有効", "DropsAtivated"],
    "watch": [
    {
        "game": "游戏名字/分类名",
        "streamer": []
    }
]
}
' >> /app/formal/config.json

chmod +x /app/formal/run


################# 自动脚本命令部分
mkdir -p /app/formal/script/

echo '#!/bin/bash
if [ $# -eq 0 ]; then
        echo "请提供至少一个进程的进程序号作为参数"
        exit 1
fi
for pid in "$@"; do
        kill "$pid"
        if [ $? -eq 0 ]; then
                echo "已成功杀死进程 $pid"
        else
                echo "无法杀死进程 $pid"
        fi
done' > /app/formal/script/kill_progress.sh


echo '#!/bin/bash
process_info=$(pgrep -af "/app/formal/run")
if [ -n "$process_info" ]; then
    echo "找到以下进程："
    echo "$process_info"
    pkill -f "/app/formal/run"
    echo "挂机进程已被杀死"
else
    echo "未找到注册的进程"
fi
nohup /app/formal/run /app/formal/log/推进度日志.log 2>&1 &
get_process=$(pgrep -af "/app/formal/claim")

if [ -n "$get_process" ]; then
        echo "找到以下进程："
        echo "$get_process"
        pkill -f "/app/formal/claim"
        echo "进程已被杀死。"
else
        echo "未找到领取进程。"
fi

nohup /app/formal/claim > /app/formal/log/领取日志.log 2>&1 &
echo "领取程序已开始运行"' > /app/formal/script/start_run_and_get.sh

echo '#!/bin/bash
ps -ef|grep /app/formal/run' > /app/formal/script/query.sh

echo '#!/bin/bash
/app/formal/one_key_claim' > /app/formal/script/stable_claim.sh

echo '#!/bin/bash
/app/formal/cheapest-tw/branch/download_status.py' > /app/formal/script/status_save.sh


chmod +x /app/formal/script/*

echo "alias pf='/app/formal/script/query.sh'
alias kp='/app/formal/script/kill_progress.sh'
alias mpr='/app/formal/script/start_run_and_get.sh'
alias stsave='/app/formal/script/status_save.sh'
alias sc='/app/formal/script/one_key_claim.sh'" > ~/.bash_profile

# ubuntu 的内置命令source不可执行，需要替换
# 参考：https://stackoverflow.com/questions/48785324/source-command-in-shell-script-not-working
source ~/.bash_profile
. ~/.bash_profile
