#!/bin/bash

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


# 将相关程序都下载到本地
# Function to download a file by ID
download_file() {
    local file_id=$1
    local output_file=$2

    # Make the initial request to get the JSON response
    echo "Requesting download link for ${file_id}..."
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "X-Cx-Permit:51e624fe6f00" \
        -d "{\"file_id\":\"${file_id}\"}" \
        "https://key.gamingsea.top/api/release/download")

    # Extract the download URL from the JSON response
    download_url=$(echo $response | grep -o '"data": "[^"]*"' | sed 's/"data": "//;s/"//')

    if [ -z "$download_url" ]; then
        echo "Error: Could not extract download URL for ${file_id}"
        echo "Response was: ${response}"
        return 1
    fi

    # Download the actual file using the extracted URL
    echo "Downloading ${file_id} to ${output_file}..."
    curl -s -L "$download_url" -o "$output_file"

    if [ $? -eq 0 ]; then
        echo "Successfully downloaded ${output_file}"
    else
        echo "Error downloading ${output_file}"
    fi
}

# Download each of the three files
download_file "run" "run"
download_file "claim" "claim"
download_file "one_key_claim" "one_key_claim"
download_file "download_status" "download_status"

mkdir -p /app/formal/cookies
mkdir -p /app/formal/log

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
    echo -e "${YELLOW}跳过数据库配置，您将需要稍后手动编辑 /app/formal/config.json 文件。${NC}"

    # 创建默认配置文件
    echo '{
    "cookie_path": "/app/formal/cookies/",
    "db": {
        "host": "",
        "username": "",
        "password": "",
        "name": ""
    },
    "start": 0,
    "batch": 2000
    "watch_tag": ["DropsEnabled", "启用掉宝", "DropsAtivados", "Drops有効", "DropsAtivated", "ViewerRewards", "观众奖励"],
    "watch": [
    {
        "game": "游戏名字/分类名",
        "streamer": [],
        "slug": "minecraft"
    }
]
}' > /app/formal/config.json

    echo -e "${GREEN}已使用提供的数据库信息创建配置文件。${NC}"
fi

chmod +x /app/formal/run
chmod +x /app/formal/claim
chmod +x /app/formal/one_key_claim
chmod +x /app/formal/download_status


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
    echo "未找到推进度程序的进程"
fi
nohup /app/formal/run > /app/formal/log/推进度日志.log 2>&1 &
echo "推进度程序已开始运行"
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
/app/formal/download_status' > /app/formal/script/status_save.sh


chmod +x /app/formal/script/*

echo "alias pf='/app/formal/script/query.sh'
alias kp='/app/formal/script/kill_progress.sh'
alias mpr='/app/formal/script/start_run_and_get.sh'
alias stsave='/app/formal/script/status_save.sh'
alias sc='/app/formal/script/stable_claim.sh'" > ~/.bash_profile

# 将目录变更命令添加到 bashrc 和 profile，确保在用户登录后自动切换到目标目录
echo "cd /app/formal" >> ~/.bashrc
echo "cd /app/formal" >> ~/.profile

# 加载别名设置
# 解决 source 命令不可用的问题
#source ~/.bash_profile 2>/dev/null || . ~/.bash_profile
source ~/.bash_profile 2>/dev/null
. ~/.bash_profile

# 确保当前脚本立即切换到目标目录
cd /app/formal
echo -e "${GREEN}已切换到 /app/formal 目录${NC}"
echo -e "${GREEN}安装和配置已完成!${NC}"
echo -e "${YELLOW}下次登录时将自动进入 /app/formal 目录${NC}"

# 提供脚本目录下的文件列表
echo -e "${YELLOW}已创建以下脚本:${NC}"
ls -l /app/formal/script/

# 显示可用的别名命令
echo -e "${YELLOW}已设置以下别名命令:${NC}"
echo "pf - 查询进程"
echo "kp - 杀死指定进程"
echo "mpr - 启动运行和获取程序"
echo "stsave - 保存状态"
echo "sc - 稳定领取"

# 执行 stsave 命令
if [[ "$manual_edit" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}正在执行 stsave 命令...${NC}"
    /app/formal/script/status_save.sh
    echo -e "${GREEN}stsave 命令执行完毕${NC}"

    # 从 /app/formal/cookies 中获取一个 *.pkl 文件名
    echo -e "${YELLOW}正在从 cookies 目录获取文件名...${NC}"
    cookie_file=$(ls /app/formal/cookies/*.pkl 2>/dev/null | head -n 1)

    if [ -n "$cookie_file" ]; then
        # 提取文件名（不包含路径和扩展名）
        cookie_name=$(basename "$cookie_file" .pkl)
        echo -e "${GREEN}找到 cookie 文件: $cookie_name${NC}"

        # 更新配置文件中的 name 字段
        sed -i 's/"name": "",/"name": "'"$cookie_name"'",/' /app/formal/config.json
        echo -e "${GREEN}已更新配置文件中的 name 字段为: $cookie_name${NC}"
    else
        echo -e "${RED}未找到 .pkl 文件。请稍后手动更新配置文件。${NC}"
    fi
else
    echo -e "${RED}请先手动编辑配置文件，然后再执行 stsave 命令！${NC}"
fi

echo -e "${RED}如果您选择了手动编辑，请确保修改 config.json 为您自己的数据库配置信息，然后执行 stsave 命令！${NC}"

# 在当前 shell 中保持在 /app/formal 目录
exec bash -c "cd /app/formal && exec bash"