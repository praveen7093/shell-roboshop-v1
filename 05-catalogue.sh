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

dnf module disable nodejs -y &>> $logs_file
dnf module enable nodejs:24 -y &>> $logs_file
dnf install nodejs -y  &>> $logs_file
validate $? "installing nodejs 24" &>> $logs_file

node -v
validate $? "verifying the version"



id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "creating system user"
else
    echo -e "system user roboshop already user is exisit....${Y}Skipping${N}"
fi
rm -rf /app
validate $? "removing old code"

mkdir -p /app
validate $? "creatin app directory"

curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip
validate $? "downloading catalogue"

cd /app
unzip /tmp/catalogue.zip
validate $? "unzipping catalogue"

npm install &>> $logs_file
validate $? "installing dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/catalogue.service"    
cp "$scripts_dir/catalogue.service" /etc/systemd/system/catalogue.service

systemctl daemon-reload &>> $logs_file
systemctl enable catalogue &>> $logs_file
systemctl start catalogue &>> $logs_file
validate $? "starting and enabling the catalogue service"

cp "$scripts_dir//mongo.repo" /etc/yum.repos.d/mongo.repo
validate $? "adding mongo repo"

dnf install mongodb-mongosh -y
validate $? "installing mongodb client"

mongosh --host "mongodb.$domain_name" </app/db/master-data.js
validate $? "lodading products"

echo "$(timestamp) [INFO] ===== script execution seconds: $SECONDS =====" | tee -a $logs_file