#!/bin/bash
echo "Cài đặt Redis"
sudo yum install redis -y

echo "Sửa file redis.conf "
sudo cp /etc/redis.conf /etc/redis.conf.bak  
# Sao lưu file gốc
# Thay đổi bind và port
sudo sed -i \
    -e "s|^bind .*|bind 0.0.0.0|" \
    -e "s|^port .*|port 2104|" \
    -e "s|^# requirepass .*|requirepass isofh@2015#Redis|" \
    /etc/redis.conf
sudo grep -E "^(bind|port|requirepass)" /etc/redis.conf
sudo systemctl enable redis --now
echo "Cài đặt hoàn tất Redis"
