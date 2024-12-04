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
sudo rsync -avz /var/lib/pgsql /pg_data/
sudo mv /var/lib/pgsql /var/lib/pgsql.bak

# Cập nhật cấu hình service
echo "Cập nhật cấu hình service PostgreSQL..."
sudo sed -i 's|^Environment=PGDATA=.*|Environment=PGDATA=/pg_data/pgsql/15/data|' /usr/lib/systemd/system/postgresql-15.service
sudo systemctl daemon-reload
sudo systemctl restart postgresql-15.service

# Cập nhật file postgresql.conf
echo "Cập nhật cấu hình postgresql.conf..."
sudo sed -i \
    -e "s|^\(#\?\s*\)data_directory\s*=.*|data_directory = '/pg_data/pgsql/15/data'|" \
    -e "s|^\(#\?\s*\)listen_addresses\s*=.*|listen_addresses = '*'|" \
    -e "s|^\(#\?\s*\)port\s*=.*|port = 5432|" \
    -e "s|^\(#\?\s*\)dynamic_shared_memory_type\s*=.*|dynamic_shared_memory_type = posix|" \
    -e "s|^\(#\?\s*\)wal_level\s*=.*|wal_level = replica|" \
    -e "s|^\(#\?\s*\)synchronous_commit\s*=.*|synchronous_commit = on|" \
    -e "s|^\(#\?\s*\)wal_log_hints\s*=.*|wal_log_hints = on|" \
    -e "s|^\(#\?\s*\)archive_mode\s*=.*|archive_mode = on|" \
    -e "s|^\(#\?\s*\)archive_command\s*=.*|archive_command = 'cp %p /data/pg_archivelog/%f'|" \
    -e "s|^\(#\?\s*\)max_wal_senders\s*=.*|max_wal_senders = 2|" \
    -e "s|^\(#\?\s*\)log_destination\s*=.*|log_destination = 'stderr'|" \
    -e "s|^\(#\?\s*\)logging_collector\s*=.*|logging_collector = on|" \
    -e "s|^\(#\?\s*\)log_directory\s*=.*|log_directory = 'log'|" \
    -e "s|^\(#\?\s*\)log_filename\s*=.*|log_filename = 'postgresql-%Y%m%d_%H%M%S.log'|" \
    -e "s|^\(#\?\s*\)log_rotation_age\s*=.*|log_rotation_age = 1d|" \
    -e "s|^\(#\?\s*\)log_rotation_size\s*=.*|log_rotation_size = 0|" \
    -e "s|^\(#\?\s*\)log_truncate_on_rotation\s*=.*|log_truncate_on_rotation = on|" \
    -e "s|^\(#\?\s*\)log_min_duration_statement\s*=.*|log_min_duration_statement = 6000|" \
    -e "s|^\(#\?\s*\)log_checkpoints\s*=.*|log_checkpoints = on|" \
    -e "s|^\(#\?\s*\)log_connections\s*=.*|log_connections = on|" \
    -e "s|^\(#\?\s*\)log_disconnections\s*=.*|log_disconnections = on|" \
    -e "s|^\(#\?\s*\)hot_standby\s*=.*|hot_standby = on|" \
    -e "s|^\(#\?\s*\)hot_standby_feedback\s*=.*|hot_standby_feedback = on|" \
    -e "s|^\(#\?\s*\)log_error_verbosity\s*=.*|log_error_verbosity = default|" \
    -e "s|^\(#\?\s*\)log_line_prefix\s*=.*|log_line_prefix = '%t [%p]: user=%u,db=%d,app=%a,client=%h '|" \
    -e "s|^\(#\?\s*\)log_lock_waits\s*=.*|log_lock_waits = on|" \
    -e "s|^\(#\?\s*\)log_statement\s*=.*|log_statement = 'ddl'|" \
    -e "s|^\(#\?\s*\)log_replication_commands\s*=.*|log_replication_commands = on|" \
    -e "s|^\(#\?\s*\)log_timezone\s*=.*|log_timezone = 'Asia/Ho_Chi_Minh'|" \
    -e "s|^\(#\?\s*\)track_activity_query_size\s*=.*|track_activity_query_size = 8192|" \
    -e "s|^\(#\?\s*\)idle_in_transaction_session_timeout\s*=.*|idle_in_transaction_session_timeout = 60s|" \
    -e "s|^\(#\?\s*\)datestyle\s*=.*|datestyle = 'iso, mdy'|" \
    -e "s|^\(#\?\s*\)timezone\s*=.*|timezone = 'Asia/Ho_Chi_Minh'|" \
    -e "s|^\(#\?\s*\)lc_messages\s*=.*|lc_messages = 'en_US.UTF-8'|" \
    -e "s|^\(#\?\s*\)lc_monetary\s*=.*|lc_monetary = 'en_US.UTF-8'|" \
    -e "s|^\(#\?\s*\)lc_numeric\s*=.*|lc_numeric = 'en_US.UTF-8'|" \
    -e "s|^\(#\?\s*\)lc_time\s*=.*|lc_time = 'en_US.UTF-8'|" \
    -e "s|^\(#\?\s*\)default_text_search_config\s*=.*|default_text_search_config = 'pg_catalog.english'|" \
    -e "s|^\(#\?\s*\)shared_preload_libraries\s*=.*|shared_preload_libraries = 'pg_stat_statements'|" \
    /pg_data/pgsql/15/data/postgresql.conf

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
