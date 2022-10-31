# OctoMeow the Octoprint installer



## Install octoprint

```shell
git clone https://github.com/melROLL/OctoMeow.git
cd OctoMeow
sudo chmod +x octoprint_install.sh
sudo ./octoprint_install.sh
```

Script enter password for octoprint system user and pray for tit to work.

Open octoprint on you browser with http://<SERVER_IP>:5000 after script finish work


# Useful commands

## Restart octoprint

```shell
sudo systemctl restart octoprint.service
```

## Restart webcam

```shell
systemctl restart webcam.service
```

## Show octoprint logs

```shell
journalctl --no-pager -b -u octoprint
```

## Show webcam logs

```shell
journalctl --no-pager -b -u octoprint
```
