#!/bin/bash
usr=$(id -u)
time=$(date +%F-%H-%M-%S)
scriptname=$(echo $0 | cut -d "." -f1)
log=/tmp/$scriptname-$time.log

u=$(id -u)

lak(){
    if [ $1 -ne 0 ]
    then
        echo "$2 failed"
    else
        echo "$2 success"
    fi
}

if [ $u -ne 0 ]
then
    echo "is this sudo"
    exit 1
else    
    echo "SUDO"
fi

dnf module disable nodejs -y &>>log
lak $? "disabling"

dnf module enable nodejs:20 -y &>>log
lak $? "enabling"

dnf install nodejs -y &>>log
lak $? "installing"

id expense &>>log
if [ $? -ne 0 ]
then    
    useradd expense &>>log
    lak $? "creating usr"
else
    echo "already created skipping"
fi

mkdir -p /app &>>log
lak $? "dir"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>log
lak $? "backend code downloading"

cd /app 
rm -rf /app/*
unzip /tmp/backend.zip
lak $? "extracted backend code"

npm install &>>log
lak $? "installing"

#check your repo and path
cp /home/ec2-user/expense-script/backend.service /etc/systemd/system/backend.service &>>log
lak $? "copied backend service"

systemctl daemon-reload &>>log

systemctl start backend &>>log

systemctl enable backend &>>log
lak $? "starting and enabling backend"

dnf install mysql -y &>>log
lak $? "installing"

mysql -h db.vjeeth.site -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>log
lak $? "schema loading"

systemctl restart backend &>>log
lak $? "restarting backend"
