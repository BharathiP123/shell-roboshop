#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-script"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log
MONGODBHOST=mongodb.bpotla.com
mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}
### NodeJS###
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disable nodejs" &>>$LOG_FILE
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable  nodejs" &>>$LOG_FILE
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installed nodejs" &>>$LOG_FILE
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
mkdir /app 
VALIDATE $? "creating app directory" &>>$LOG_FILE
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "download the code" &>>$LOG_FILE
cd /app 
VALIDATE $? "changing the directory" &>>$LOG_FILE
unzip /tmp/catalogue.zip
VALIDATE $? "unziping the fiel" &>>$LOG_FILE 
npm install
VALIDATE $? "installed npm" &>>$LOG_FILE
cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "coping the service file" &>>$LOG_FILE

systemctl daemon-reload
VALIDATE $? "running the daemon" &>>$LOG_FILE
systemctl enable catalogue 
VALIDATE $? "enable the  service" &>>$LOG_FILE
systemctl start catalogue
VALIDATE $? "started the service" &>>$LOG_FILE

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copy the mongo repo" &>>$LOG_FILE
dnf install mongodb-mongosh -y
VALIDATE $? "installed mongosh client" &>>$LOG_FILE
mongosh --host $MONGODBHOST </app/db/master-data.js
VALIDATE $? connected to DB" &>>$LOG_FILE 
