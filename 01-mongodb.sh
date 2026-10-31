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

echo "script started executing at $(date +"%F %T")" &>> $logs_file

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "${2}.. is ${R}failed${N}" | tee -a $logs_file
        exit 1
    else 
        echo -e "${2}  is ${G}sucess${N}" | tee -a $logs_file
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Adding mongo repo"

dnf install mongodb-org -y &>> $logs_file
validate $? "install mongoDB"

systemctl enable mongod
systemctl start mongod
validate $? "enable and start mongoDB"


sudo sed -i 's/127\.0\.0\.1/0.0.0.0/' /etc/mongod.conf
validate $? "configuring remote connections to MongoDB"

systemctl restart mongod
validate $? "restarting mongodb"


