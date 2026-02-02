#!/bin/bash
# nohup python /data/app.py > /dev/null 2>&1 &
nohup python /home/vncuser/ff.py  > /home/vncuser/fff.log 2>&1 &

# 设置最大等待时间和计数器
max_wait=240  # 最大等待300秒（5分钟）
wait_interval=5  # 每5秒检查一次
elapsed=0
# 定义需要检查的环境变量列表
# 检查 DATA_JSON, HF_USER1, HF_REPO, HF_EMAIL, HF_TOKEN1 是否都不为空
if [[ -n "$DATA_JSON" && -n "$HF_USER1" && -n "$HF_REPO" && -n "$HF_EMAIL" && -n "$HF_TOKEN1" ]]; then
    echo "🚀 环境变量检查通过，开始循环等待 profiles.ini..."

    # 循环等待 profiles.ini 文件出现
    while [ $elapsed -lt $max_wait ]; do
        if [ -f "/home/vncuser/ff/.mozilla/firefox/profiles.ini" ]; then
            echo "✅ profiles.ini 文件已出现，执行 ff.sh"
            /home/vncuser/ff.sh
            break
        else
            echo "⏳ 等待 profiles.ini 文件... (已等待 ${elapsed}秒)"
            # 注意：如果 fff.log 文件很大，cat 可能会刷屏，建议按需查看
            [ -f /home/vncuser/fff.log ] && tail -n 5 /home/vncuser/fff.log 
            
            sleep $wait_interval
            elapsed=$((elapsed + wait_interval))
        fi
    done

    # 检查是否超时
    if [ $elapsed -ge $max_wait ]; then
        echo "❌ 等待超时，profiles.ini 文件未在 ${max_wait} 秒内出现"
        echo "⚠️  尝试直接执行 ff.sh"
        /home/vncuser/ff.sh
    fi

else
    echo "⚠️  检测到必要环境变量为空，跳过等待，直接执行 ff.sh"
    /home/vncuser/ff.sh
fi
