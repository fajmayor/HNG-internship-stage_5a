## DevOpsFetch Tool Documentation

## Introduction
DevOpsFetch is a bash script tool designed to provide an overview of key system and network information on a server. It gathers details such as active ports, user logins, Docker images, container statuses, and Nginx configurations. The tool can also run as a systemd service, allowing for continuous monitoring and logging of system activities.

** Installation **
** Prerequisites: **

Ensure the script is executed with root privileges.

Steps:

Copy Script: Copy devopsfetch.sh to /usr/local/bin and rename it to devopsfetch.

```
sudo cp devopsfetch.sh /usr/local/bin/devopsfetch
sudo chmod +x /usr/local/bin/devopsfetch

```
