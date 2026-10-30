#!/bin/bash
user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $user_id -ne 0 ]; then
    echo "please run the script with sud0 access" &>> $logs_file
    exit 1
fi

mkdir -p $logs_folder


timestamp(){
   date +"%F %T"
}

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$(timestamp) [ERROR] ${2}.. is ${R}failed${N}" | tee -a $logs_file
        exit 1
    else 
        echo -e "$ $(timestamp) [INFO] {2}  is ${G}sucess${N}" | tee -a $logs_file
    fi
}

echo "$(timestamp) [INFO] ===== script started execution======" | tee -a $logs_file

dnf module enable mysql:8.4 -y &>> $logs_file 
dnf install mysql-server -y &>> $logs_file 
validate $? "install mysql server"

systemctl enable mysqld &>> $logs_file 
systemctl start mysqld &>> $logs_file 
validate $? "start mysql"


mysql_secure_installation --set-root-pass RoboShop@1 &>> $logs_file 
validate $? "mysql setup root passwod"

echo "$(timestamp) [INFO] ===== script  execution seconds : $SECONDS ======"
echo "$(timestamp) [INFO] ===== script execution time======" | tee -a $logs_file

