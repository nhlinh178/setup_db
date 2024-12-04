#!/bin/bash

# Cài đặt PostgreSQL 15
echo "Cài đặt PostgreSQL 15..."
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql15-server postgresql15-contrib

# Khởi tạo và khởi động PostgreSQL
echo "Khởi tạo và khởi động PostgreSQL..."
sudo /usr/pgsql-15/bin/postgresql-15-setup initdb
sudo systemctl enable postgresql-15
sudo systemctl start postgresql-15
sudo systemctl status postgresql-15

# Dừng PostgreSQL và di chuyển thư mục dữ liệu
echo "Dừng PostgreSQL và di chuyển thư mục dữ liệu..."
sudo systemctl stop postgresql-15
sudo cp -r /var/lib/pgsql/15/data /pg_data/
sudo mv /var/lib/pgsql/15/data /var/lib/pgsql/15/data.bak

# Cập nhật cấu hình service
echo "Cập nhật cấu hình service PostgreSQL..."
sudo sed -i 's|^Environment=PGDATA=.*|Environment=PGDATA=/pg_data/data|' /usr/lib/systemd/system/postgresql-15.service
sudo systemctl daemon-reload
sudo systemctl restart postgresql-15.service

# Cập nhật file postgresql.conf
echo "Cập nhật cấu hình postgresql.conf..."
sudo bash -c "cat >> /pg_data/data/postgresql.conf << EOF
# Thêm các dòng cấu hình cần thiết ở đây
EOF"

# Cập nhật .bash_profile
echo "Cập nhật .bash_profile..."
cat >> ~/.bash_profile << EOF
[ -f /etc/profile ] && source /etc/profile
export PGDATA=/pg_data/data
export PATH=\${PATH}:/usr/pgsql-15/bin
export PS1="[\u@\h \W]\\$ "
[ -f /var/lib/pgsql/.pgsql_profile ] && source /var/lib/pgsql/.pgsql_profile
alias ssh='ssh -o StrictHostKeyChecking=no'
alias scp='scp -o StrictHostKeyChecking=no'
alias rsync='rsync -e "ssh -o StrictHostKeyChecking=no"'
EOF

source ~/.bash_profile

# Cấu hình quyền truy cập pg_hba.conf
echo "Cấu hình quyền truy cập pg_hba.conf..."
sudo bash -c "cat >> /pg_data/data/pg_hba.conf << EOF
local   all             all                                     md5
host    all             all             0.0.0.0/0               md5
host    replication     replica         standby_ip/24           md5
EOF"

# Khởi động lại PostgreSQL
echo "Khởi động lại PostgreSQL..."
sudo pg_ctl start -D /pg_data/data/

echo "Hoàn tất quá trình cài đặt và cấu hình PostgreSQL 15."
