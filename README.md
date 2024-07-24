## DevOpsFetch Tool Documentation

## Introduction
DevOpsFetch is a bash script tool designed to provide an overview of key system and network information on a server. It gathers details such as active ports, user logins, Docker images, container statuses, and Nginx configurations. The tool can also run as a systemd service, allowing for continuous monitoring and logging of system activities.

**Installation**

**Prerequisites:**

Ensure the script is executed with root privileges.

**Steps:**

- Clone this repository

- Make `setup_devopsfetch.sh` script executable by running the following;

```
chmod +x setup_devopsfetch.sh
```
- Install `setup_devopsfetch.sh` using root or sudo

```
sudo ./setup_devopsfetch.sh
```
- Check help options to view usage example

```
devopsfetch -h
```

## To Remove the Tool

- Stop and Disable the service using the command below;
```
sudo systemctl stop devopsfetch.service
sudo systemctl disable devopsfetch.service
```
- Remove the service
```
sudo rm /etc/systemd/system/devopsfetch.service
```
- Remove the script

```
sudo rm /usr/local/bin/devopsfetch 
```
Remove the log rotation setting
```
sudo rm /etc/logrotate.d/devopsfetch
```