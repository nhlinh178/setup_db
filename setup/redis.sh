#!/bin/bash
echo "Cài đặt Redis"
sudo yum install redis -y
sudo sed -i \
    -e "s|^\(#\?\s*\)bind\s*=.*|bind  0.0.0.0|" \
    -e "s|^\(#\?\s*\)port\s*=.*|port 2104|" \
    -e "s|^\(#\?\s*\)requirepass\s*=.*|requirepass  isofh@2015#Redis|" \
    /etc/redis.conf
sudo systemctl enable redis --now
echo "Cài đặt hoàn tất Redis"
