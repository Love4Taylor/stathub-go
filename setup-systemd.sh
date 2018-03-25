#!/bin/bash

VERSION="0.14.2"
STATHUB_URL="https://github.com/likexian/stathub-go/releases/download/v${VERSION}/server_$(uname -m).tar.gz"

[ $(id -u) -ne 0 ] && sudo="sudo" || sudo=""
id -u nobody >/dev/null 2>&1
if [ $? -ne 0 ]; then
    $sudo groupadd nogroup
    useradd -g nogroup nobody -s /bin/false
fi

$sudo mkdir -p /var/stathub
$sudo chown -R $(id -u -n):$(id -g -n) /var/stathub
if [ ! -d /var/stathub ]; then
    echo "Unable to create dir /var/stathub and chown to current user, Please manual do it"
    exit 1
fi
cd /var/stathub

command_exists() {
    type "$1" &> /dev/null
}

if command_exists wget; then
    wget --no-check-certificate $STATHUB_URL
elif command_exists curl; then
    curl --insecure -O $STATHUB_URL
else
    echo "Unable to find curl or wget, Please install and try again."
    exit 1
fi

if [ ! -f server_$(uname -m).tar.gz ]; then
    echo "Unable to get server file, Please manual download it"
    exit 1
fi
tar zxf server_$(uname -m).tar.gz
rm -rf server_$(uname -m).tar.gz

source /etc/os-release
case $ID in
debian|ubuntu)
    $sudo sh -c 'echo -e "[Unit]\nDescription=StatHub Server\nAfter=network.target\n\n[Service]\nType=simple\nUser=root\nWorkingDirectory=/var/stathub\nExecStart=/var/stathub/server\nPIDFile=/var/stathub/data/stathub.pid\nExecStop=/usr/bin/kill -HUP \$MAINPID\nSuccessExitStatus=2\nRestart=on-failure\n\n[Install]\nWantedBy=multi-user.target" > /lib/systemd/system/stathub.service'
    $sudo systemctl enable stathub
    ;;
centos|fedora)
    yumdnf="yum"
    if test "$(echo "$VERSION_ID >= 22" | bc)" -ne 0; then
        yumdnf="dnf"
    fi
    $sudo sh -c 'echo -e "[Unit]\nDescription=StatHub Server\nAfter=network.target\n\n[Service]\nType=simple\nUser=root\nWorkingDirectory=/var/stathub\nExecStart=/var/stathub/server\nPIDFile=/var/stathub/data/stathub.pid\nExecStop=/usr/bin/kill -HUP \$MAINPID\nSuccessExitStatus=2\nRestart=on-failure\n\n[Install]\nWantedBy=multi-user.target" > /usr/lib/systemd/system/stathub.service'
    $sudo systemctl enable stathub
    ;;
*)
    exit 1
    ;;
esac

echo "----------------------------------------------------"
echo "| Server install sucessful, Please start it using  |"
echo "| systemctl {start|stop|restart} stathub           |"
echo "| Now it will automatic start                      |"
echo "|                                                  |"
echo "| Feedback: https://github.com/likexian/stathub-go |"
echo "| Thank you for your using, By Li Kexian           |"
echo "| StatHub, Apache License, Version 2.0             |"
echo "----------------------------------------------------"

$sudo systemctl start stathub
sleep 1

KEY=$(grep key server.json | cut -d \" -f 4)
STATHUB_CLIENT_URL=https://127.0.0.1:15944/node?key=$KEY
if command_exists wget; then
    wget --no-check-certificate -O - $STATHUB_CLIENT_URL | sh
elif command_exists curl; then
    curl --insecure $STATHUB_CLIENT_URL | sh
else
    echo "Unable to find curl or wget, Please install and try again."
    exit 1
fi
