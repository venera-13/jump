# JUMP is a Universal Maintenance Pod

JUMP is a container originally designed as a tool for maintenance on ''edge'' systems running Docker. Starting a JUMP container can give access for troubleshooting or maintenance using the remote access tools most engineers are comfortable with. Using multiple protocols provides flexibility and allows access from numerous clients from a great number of operating systems.

Jump provides the following protocols for accessing the desktop:

- RDP
- VNC
- HTTPS (works through web proxies)

The JUMP container enables dynamic resizing of desktop sessions on all of the above protocols. No more scroll bars on your remote session!

## Encryption

The HTTPS and RDP protocols enforce encryption by default. TigerVNC offers anonymous TLS encryption but does not mind clients connecting without using it. To enforce the use of TLS in VNC the variable "VNCTLS" in the Dockerfile can be set to "true". Please note this breaks the noVNC HTTPS frontend and some older VNC clients.

## Used components

Alle used software is open-source.

- CentOS 8
- TigerVNC-server
- noVNC HTML5 VNC-frontend
- XRDP Terminal Server for X11
- Chromium browser
- Openbox or XFCE4 window manager

## Build instructions

Clone the Git repository and add your own values to the "ARG" variables in the Dockerfile or the docker-compose.yml depending on wether you want to use docker-compose or not.

| ARG        | Description                              |
|------------|------------------------------------------|
| USER       | Username of desktop user                 |
| PASS       | Password of desktop user                 |
| TZ         | Timezone the container lives in          |
| KEYSUBJECT | Information about the SSL certificate    |
| VNCTLS     | Enforce TLS encryption on VNC server     |
| BROWSER    | Select your browser: firefox/chromium    |
| OPTPKGS    | Select optional packages to install      |


### Build using Openbox
Building the container using docker-compose

```bash
git clone https://github.com/venera-13/jump.git
cd jump
vim docker-compose.yml
docker-compose -f ./docker-compose.yml build
```

Building the container with docker

```bash
git clone https://github.com/venera-13/jump.git
cd jump
vim Dockerfile
docker build -f ./Dockerfile -t docker.io/okroshka/jump:latest .
```

### Build using XFCE4
Building the container using docker-compose

```bash
git clone https://github.com/venera-13/jump.git
cd jump
vim docker-compose.xfce.yml
docker-compose -f ./docker-compose.xfce.yml build
```

Building the container with docker

```bash
git clone https://github.com/venera-13/jump.git
cd jump
vim Dockerfile.xfce
docker build -f ./Dockerfile.xfce -t docker.io/okroshka/jump:xfce-latest .
```


## Using the container

Start the container with the below command. If you did not build the image yourself in the above steps the container will be downloaded from docker.io. Parameters are explained in the table.

```bash
# For Openbox
docker run -d --rm --shm-size=1g --name jump  -p 3389:3389 -p 5901:5901 -p 8080:8080 docker.io/okroshka/jump:latest

# For XFCE4
docker run -d --rm --shm-size=1g --name jump  -p 3389:3389 -p 5901:5901 -p 8080:8080 docker.io/okroshka/jump:xfce-latest

# Stopping and removing the container
docker stop jump
```

| Parameter     | Omschrijving                                                       |
|---------------|--------------------------------------------------------------------|
| -d            | Run container in background non interactively                      |
| --rm          | Delete container after you're done with it                         |
| --shm-size=1g | Increase allowed shared memory. Keeps modern browsers from crashing|
| --name jump   | Name the container so it is easy to recognise                      |
| -p 3389:3389  | Expose RDP port                                                    |
| -p 5901:5901  | Expose VNC port                                                    |
| -p 8080:8080  | Expose port for noVNC HTML5 VNC frontend                           |

After starting, the container is ready to accept connections from RDP, VNC or Web clients.
