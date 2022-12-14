#!/bin/bash

set -e

export HOMEDIR="/home/octo"
export DISTRIBUTOR="$(/usr/bin/lsb_release -is)"

#cool colors go brrrrrrr
function echo_yellow {
  TEXT="${@}"
  echo -e "\e[33m${TEXT}\e[0m"
}
function echo_green {
  TEXT="${@}"
  echo -e "\e[32m${TEXT}\e[0m"
}
function echo_red {
  TEXT="${@}"
  echo -e "\e[31m${TEXT}\e[0m"
}
if [ "$EUID" -ne 0 ]; then
  echo_red "# ======================================================="
  echo_red "# Please run as root if sudo can't help you need to pray "
    echo_red "# ======================================================="
  exit 1
fi

case $DISTRIBUTOR in
  Debian|Ubuntu)
    echo_green "# Detected distribution: ${DISTRIBUTOR}"
    ;;
  *)
    echo_red "# Unsupported distribution try with Debian or Ubuntu: ${DISTRIBUTOR}"
    exit 2
    ;;
esac

#this is needed because it keeps fucking up with python
function setup_venv {
  set -e
  mkdir ${HOMEDIR}/OctoPrint
  cd ${HOMEDIR}/OctoPrint
  #virtualenv -p /usr/bin/python3 --quiet venv
    virtualenv -p /usr/bin/python --quiet venv
  source venv/bin/activate
  pip install pip --upgrade
  #pip install octoprint # neet to put denis octoprint here
  pip install git+https://github.com/denpat/Octoprint138WASP
}

export -f setup_venv

if [ -d "${HOMEDIR}" ]; then
    read -p "User octo already exist, delete user and continue? (Y/n)" -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo_yellow "# Delete user octo and $HOMEDIR folder"
        userdel -r octo
    else
        echo_red "User octo already exist. Installation stoped"
        exit
    fi
fi

echo_yellow "# Create octo user"
useradd -m -s /bin/bash -G tty,dialout,video octo

echo_yellow "# Please password for octo user"
passwd octo

echo_yellow "# Install package dependencies"
apt-get update
# Python dependencies DO NOT TOUCH IT !!!!!!!!!!!!!!!!
# Python dependencies DO NOT TOUCH IT !!!!!!!!!!!!!!!!
case $DISTRIBUTOR in # Python dependencies DO NOT TOUCH IT !!!!!!!!!!!!!!!!
  Ubuntu|Debian) 
    apt-get -y install \
      build-essential \
      curl \
      git \
      libyaml-dev \
      python-dev \
      python-pip \
      python-setuptools \
      python-virtualenv \
      zlib1g-dev \
      virtualenv
    ;;
esac
# Python dependencies DO NOT TOUCH IT !!!!!!!!!!!!!!!!
# Python dependencies DO NOT TOUCH IT !!!!!!!!!!!!!!!!

# ffmpeg && mjpg-streamer build dependencies use for the webcam
case $DISTRIBUTOR in
  Debian)
    apt-get -y install \
      cmake \
      ffmpeg \
      git \
      imagemagick \
      libjpeg62-turbo-dev \
      libv4l-dev \
      sudo
    ;;
  Ubuntu)
    apt-get -y install \
      cmake \
      ffmpeg \
      git \
      imagemagick \
      libjpeg8-dev \
      libv4l-dev \
      sudo
    ;;
esac
echo_red "# =============================="
echo_yellow "# Configure OctoPrint VirtualEnv"
echo_green "# =============================="

su octo -c "setup_venv"

echo_red"# ============================="
echo_yellow "# Configure OctoPrint autostart"
echo_green "# ============================="

curl -fsvL \
  -o /etc/systemd/system/octoprint.service \
  https://raw.githubusercontent.com/melROLL/OctoMeow/main/octoprint.service
curl -fsvL \
  -o /etc/default/octoprint \
 https://raw.githubusercontent.com/melROLL/OctoMeow/main/octoprint.default

echo_yellow "# Build mjpg-streamer"
git clone https://github.com/jacksonliam/mjpg-streamer.git /home/octo/mjpg-streamer
cd /home/octo/mjpg-streamer/mjpg-streamer-experimental
export LD_LIBRARY_PATH=.
make
cp -v /home/octo/mjpg-streamer/mjpg-streamer-experimental/_build/mjpg_streamer /usr/local/bin/mjpg_streamer

echo_red "# ================="
echo_yellow "# Configure scripts"
echo_green "# ================="

echo "octo ALL=NOPASSWD: /sbin/shutdown,/bin/systemctl restart octoprint.service" >> /etc/sudoers
curl -fsvL \
  -o /etc/systemd/system/webcam.service \
  https://raw.githubusercontent.com/melROLL/OctoMeow/main/webcam.service
curl -fsvL \
  -o /usr/local/bin/webcamDaemon\
  https://raw.githubusercontent.com/melROLL/OctoMeow/main/webcamDaemon
chmod +x /usr/local/bin/webcamDaemon

systemctl daemon-reload

for SERVICE in $(echo octoprint webcam); do
  set +e
  systemctl enable ${SERVICE}.service
  systemctl start ${SERVICE}.service
  sleep 10
  systemctl is-active --quiet ${SERVICE}.service
  if [ $? -ne 0 ]; then
    echo_red "# Service ${SERVICE} not running! Check it:"
    echo_red "# Run for logs: journalctl --no-pager -b -u ${SERVICE}.service"
  else
    echo_green "# Service ${SERVICE} OK."
  fi
done

echo_green "# ================================"
echo_yellow "# ================================"
echo_red "# ================================"
echo_green "# it is installed !!!!!!!!!!!!!!!!"
echo_red "# ================================"
echo_yellow "# ================================"
echo_green "# ================================"

for IP in $(hostname --all-ip-addresses | grep -v '127.0.0.1'); do
  echo_green "# Listen http://${IP}:5000"
  echo_green "# Webcam stream http://${IP}:8080/?action=stream"
done
