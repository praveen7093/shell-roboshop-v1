#!/bin/bash
user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
domain_name="koladaws.store"
scripts_dir=$( dirname "$(realpath "$0")")
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $user_id -ne 0 ]; then
    echo "please run the script with sudo access" &>> $logs_file
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
        echo -e "$ $(timestamp) [INFO] ${2}  is ${G}sucess${N}" | tee -a $logs_file
    fi
}

dnf module disable nginx -y &>> logs_file
dnf module enable nginx:1.26 -y &>> logs_file
dnf install nginx -y &>> logs_file
validate $? "installing nginx"

systemctl enable nginx &>> logs_file
systemctl start nginx &>> logs_file
validate $? "start nginx server"


id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "creating system user"
else
    echo -e "system user roboshop already user is exisit....${Y}Skipping${N}"
fi

rm -rf /usr/share/nginx/html/*
validate $? "removing default content"

echo "$(timestamp) [INFO] ===== script started execution======" | tee -a $logs_file