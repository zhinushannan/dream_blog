#!/bin/bash

now_date=`date +'%Y-%m-%d_%H:%M:%S'`

echo 开始添加变更：git add .
git add .
echo;

echo 开始提交变更：git commit -m ${now_date}
git commit -m ${now_date}
echo;

echo 开始推送变更：git push
git push
echo;
