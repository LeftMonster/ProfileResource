#/bin/bash

mkdir -p /app/formal
cd /app/formal

# 将相关程序都下载到本地
wget https://github.com/LeftMonster/month-version/releases/download/ver1.4/run
wget https://github.com/LeftMonster/month-version/releases/download/ver1.4/claim
wget https://github.com/LeftMonster/month-version/releases/download/ver1.4/one_key_claim

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
        "game": "partyanimals",
        "streamer": []
    }
]
}
'

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
# sudo source ~/.bash_profile
. ~/.bash_profile
