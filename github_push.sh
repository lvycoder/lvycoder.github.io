#!/bin/bash
cd /Users/beiyiwangdejiyi/Desktop/lixie-work/lvycoder.github.io/

# 切换到工作目录
if ! cd ~/Desktop/lixie-work/lvycoder.github.io/; then
    echo "无法切换到指定目录,请检查路径是否正确"
    exit 1
fi

# 获取当前时间作为提交信息
current_time=$(date "+%Y-%m-%d %H:%M:%S")

# 检查是否有变更
if ! git diff --quiet; then
    echo "检测到变更,开始提交..."

    # 添加所有变更
    git add .

    # 提交变更
    git commit -m "Auto update: $current_time"

    # 推送到远程仓库
    if git push origin master; then
        echo "成功推送到 GitHub!"
    else
        echo "推送失败,请检查网络或权限设置"
        exit 1
    fi
else
    echo "没有检测到变更"
fi
