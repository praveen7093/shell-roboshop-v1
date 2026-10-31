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
        echo -e "$ $(timestamp) [INFO] {2}  is ${G}sucess${N}" | tee -a $logs_file
    fi
}

echo "$(timestamp) [INFO] ===== script started execution======" | tee -a $logs_file

dnf module enable maven:3.9 -y &>> logs_file
dnf install maven java-25-openjdk-devel -y &>> logs_file
validate $? "installing java and maven"

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME
validate $? "setting JAVA_HOME for maven"

alternatives --set  java "/usr/lib/jvm/java-25-openjdk/bin/java"
validate $? "setting java 25 as default java version"

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

curl -L -o /tmp/validate $? "downloading shipping".zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip
validate $? "downloading shipping"

cd /app
unzip /tmp/cart.zip
validate $? "unzipping shipping"

mvn clean package &>> $logs_file
validate $? "installing dependencies"

mv target/shipping.jar shipping.jar
validate $? "moving shipping jar files"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/shipping.service"    
cp "$scripts_dir/shipping.service" /etc/systemd/system/shipping.service

dnf install mysql -y
validate $? "installing ysql client"

systemctl daemon-reload &>> $logs_file
systemctl enable shipping &>> $logs_file
systemctl start shipping &>> $logs_file
validate $? "starting and enabling the shipping service"


systemctl restart shipping
validate $? "restarting shipping"

echo "$(timestamp) [INFO] ===== script execution seconds: $SECONDS =====" | tee -a $logs_file