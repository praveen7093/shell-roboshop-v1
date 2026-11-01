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
        echo -e "$ $(timestamp) [INFO] ${2}.. is ${G}sucess${N}" | tee -a $logs_file
    fi
}

echo "$(timestamp) [INFO] ===== script started execution======" | tee -a $logs_file

dnf install python3.14 python3.14-pip -y &>> $logs_file
validate $? "installing pyhton 3.14"

python3.14 --version
validate $? "checking version"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "creating system user"
else
    echo -e "system user roboshop already user is exisit....${Y}Skipping${N}"
fi

rm -rf /app &>> $logs_file
validate $? "removing old code" 

mkdir -p /app &>> $logs_file
validate $? "creatin app directory"

curl -L -o /tmp/payment.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/payment-v4.zip
validate $? "downloading payment"

cd /app
unzip /tmp/payment.zip &>> $logs_file
validate $? "unzipping payment"

python3.14 -m venv /app/.venv &>> $logs_file
validate $? "creating virtual environment"

/app/.venv/bin/pip install -r requirements.txt &>> $logs_file
validate $? "installing dependencies"

sed -i "s/DOMAIN_NAME/${domain_name}/g" "$scripts_dir/payment.service"
cp "$scripts_dir/payment.service" /etc/systemd/system/payment.service

systemctl daemon-reload &>> $logs_file
systemctl enable payment &>> $logs_file
systemctl restart payment &>> $logs_file
validate $? "starting/restarting payment"

echo "$(timestamp) [INFO] ===== script execution seconds: $SECONDS =====" | tee -a $logs_file