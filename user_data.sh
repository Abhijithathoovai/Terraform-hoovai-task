#!/bin/bash
sudo apt update
sudo apt upgrade -y
sudo apt install apache2 -y
rm -rf /var/www/hatm/index.html
sudo apt install wget -y
sudo systemctl start apache2
sudo systemctl enable apache2
sudo apt install ruby -y
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x install
sudo ./install auto
sudo systemctl start codedeploy-agent
sudo systemctl enable codedeploy-agent
 