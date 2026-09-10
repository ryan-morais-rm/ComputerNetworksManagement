#Install the prerequisite packages:
#Bash

sudo apt-get install -y apt-transport-https wget gnupg

#Import the GPG key:
#Bash

sudo mkdir -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/grafana.asc https://apt.grafana.com/gpg-full.key
sudo chmod 644 /etc/apt/keyrings/grafana.asc

#To add a repository for stable releases, run the following command:
#Bash

echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

#To add a repository for beta releases, run the following command:
Bash

echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com beta main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

#Run the following command to update the list of available packages:
#Bash

# Updates the list of available packages
sudo apt-get update

#To install Grafana OSS, run the following command:
#Bash

# Installs the latest OSS release:
sudo apt-get install grafana

