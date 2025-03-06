#!/bin/bash
# Tham số
echo "Received PATHPG: $PATHPG"
echo "Received PATHARCHIVE: $PATHARCHIVE"
echo "Received IP_RANGE: $IP_RANGE"
PATHDATA=/$PATHPG/pgsql/15/data
# Cài đặt PostgreSQL 15
echo "Cài đặt PostgreSQL 15..."
sudo dnf install -y rsync
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
sudo mkdir -p /$PATHPG/
sudo mkdir -p /$PATHARCHIVE/
sudo chown -R postgres:postgres /$PATHPG
sudo chown -R postgres:postgres /$PATHARCHIVE
sudo chmod 755 /data
sudo chmod -R 700 /$PATHPG 
sudo chmod -R 700 /$PATHARCHIVE
sudo rsync -avz /var/lib/pgsql /$PATHPG/
sudo mv /var/lib/pgsql /var/lib/pgsql.bak
sudo cat /tmp/setup/postgresql.conf > $PATHDATA/postgresql.conf
# Cập nhật cấu hình service
echo "Cập nhật cấu hình service PostgreSQL..."
sudo sed -i "s|^Environment=PGDATA=.*|Environment=PGDATA=$PATHDATA|" /usr/lib/systemd/system/postgresql-15.service
sudo systemctl daemon-reload

# Cập nhật file postgresql.conf
echo "Cập nhật cấu hình postgresql.conf..."
sudo sed -i \
    -e "s|^\(#\?\s*\)data_directory\s*=.*|data_directory = '$PATHDATA'|" \
    -e "s|^\(#\?\s*\)archive_command\s*=.*|archive_command = 'cp %p /$PATHARCHIVE/%f'|" \
    $PATHDATA/postgresql.conf
echo "Cập nhật cấu hình hoàn tất!"
# Sửa đường dẫn thư mục home của postgresql
sudo sed -i.bak -E "s|^(postgres:[^:]*:[^:]*:[^:]*:[^:]*:)([^:]*)(:.*)|\1/data/pg_data/pgsql\3|" /etc/passwd
# Cập nhật .bash_profile
echo "Cập nhật .bash_profile..."
sudo cat > /$PATHPG/pgsql/.bash_profile << EOF
[ -f /etc/profile ] && source /etc/profile
PGDATA=$PATHDATA
export PGDATA
export PATH=\${PATH}:/usr/pgsql-15/bin
export PS1="[\u@\h \W]\\\$ "
# If you want to customize your settings,
# Use the file below. This is not overridden
# by the RPMS.
[ -f /$PATHPG/pgsql/.pgsql_profile ] && source /$PATHPG/pgsql/.pgsql_profile
alias ssh='ssh -o StrictHostKeyChecking=no'
alias scp='scp -o StrictHostKeyChecking=no'
alias rsync='rsync -e "ssh -o StrictHostKeyChecking=no"'
EOF

sudo su - postgres -c "source /$PATHPG/pgsql/.bash_profile"
echo "Cập nhật pg_hba"
sudo cat > $PATHDATA/pg_hba.conf << EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
host    all             all             10.0.50.0/24            md5
host    all             all             $IP_RANGE               md5
# Allow replication connections from localhost, by a user with the
# replication privilege.
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
EOF

sudo chown -R postgres:postgres /$PATHPG
sudo chmod -R 700 /$PATHPG 
# Khởi động lại PostgreSQL
echo "Khởi động lại PostgreSQL..."
sudo su - postgres -c "pg_ctl start -D $PATHDATA"
echo "Hoàn tất quá trình cài đặt và cấu hình PostgreSQL 15."
