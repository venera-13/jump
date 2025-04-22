FROM docker.io/centos:centos8.4.2105
LABEL maintainer="https://github.com/venera-13/jump"

########### Configure variables here ##########################
# Username and password for the user
ARG USER=jump
ARG PASS=Venera13
# Set the timezone (from: /usr/share/zoneinfo)
ARG TZ=Europe/Amsterdam
# Set the subject of the self-signed SSL-certificate
ARG KEYSUBJECT=/C=NL/ST=Zuid-Holland/L=Rotterdam/O=MyCorp/OU=MyOU/CN=jump
# Set to "true" to force encryption on TigerVNC-server over TCP/5901. Note: this breaks noVNC and some VNC clients.
ARG VNCTLS=false
# Set the browser to be installed, leave blank for no browser - needs to be a valid packagename in microdnf.
ARG BROWSER="chromium"
# Set optional packages to be installed - need to be valid packagenames in microdnf separated by spaces.
ARG OPTPKGS="nmap-ncat telnet tcpdump openssh-clients bind-utils net-snmp-utils"
########### Do not edit below this line ########################

# Configure timezone
RUN rm /etc/localtime && ln -s /usr/share/zoneinfo/${TZ} /etc/localtime

# Fix repo's for CentOS to use vault.centos.org as the CentOS 8 repositories are no longer available.
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo && \
    sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo && \
    sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo && \
    sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# This block installs necessary packages. 
# Notes:
# RHEL8 does not install UTF-8 glibc language packs by default. Install glibc-langpack-en to solve lots of problems.
# Install EPEL to install packages not found in standard RHEL repositories.
# Install novnc and websockify through CentOS community buildservice as they are not available in either EPEL or RHEL repositories.
RUN dnf update -y && \
    dnf install --nodocs -y epel-release glibc-langpack-en && \
    dnf install --nodocs -y \
        tigervnc-server \
        xrdp \
	    xorgxrdp \
        supervisor \
        openbox \
        rxvt-unicode \
	    sudo \
	    # Fetch novnc and websockify from CentOS community build service
        https://cbs.centos.org/kojifiles/packages/novnc/1.1.0/6.el8/noarch/novnc-1.1.0-6.el8.noarch.rpm \
        https://cbs.centos.org/kojifiles/packages/python-websockify/0.9.0/1.el8/noarch/python3-websockify-0.9.0-1.el8.noarch.rpm \
	    ${BROWSER} \
        ${OPTPKGS} && \
    dnf clean all

# Create user and set password.
# Add to wheel for sudo use.
RUN useradd -m -s /bin/bash ${USER}
RUN echo "${USER}:${PASS}" | chpasswd
RUN usermod -aG wheel ${USER}

# Fix to allow xrdp to start X from a TTY thats not a physical one.
RUN echo "allowed_users = anybody" >> /etc/X11/Xwrapper.config

# Fix for Chromium browser to not use CGROUP sandboxing which does not work in containers.
RUN if [ ${BROWSER} = "chromium" ] ; then sed -i 's/--auto-ssl-client-auth "/--auto-ssl-client-auth --no-sandbox "/' /usr/lib64/chromium-browser/chromium-browser.sh; fi

# Copy configuration files for Supervisord.
COPY etc/xrdp/xrdp.ini     /etc/xrdp/xrdp.ini
COPY etc/xrdp/sesman.ini   /etc/xrdp/sesman.ini
COPY etc/supervisord.conf  /etc/supervisord.conf
COPY etc/supervisord.d/*   /etc/supervisord.d/

# Set username in Supervisord configuration for TigerVNC.
RUN sed -i s/USERNAME/${USER}/g /etc/supervisord.d/vncserver.ini

# If VNCTLS is set to true, force use of encryption by TigerVNC server.
RUN if ${VNCTLS} ; then sed -i 's/-fg/-fg -SecurityTypes=VeNCrypt,TLSVnc/' /etc/supervisord.d/vncserver.ini; fi

# Create self-signed certificate for noVNC.
RUN openssl req -x509 -nodes -newkey rsa:4096 -days 3650 \
    -keyout /etc/pki/tls/certs/novnc.pem -out /etc/pki/tls/certs/novnc.pem  \
    -subj "${KEYSUBJECT}"

# Set openbox background to gray instead of solid black.
RUN echo "xsetroot -gray" >> /etc/xdg/openbox/autostart

# Run commands as non-root user to prevent having to set a lot of permissions and ownership.
USER ${USER}

# Configure password for TigerVNC and start openbox on TigerVNC startup.
RUN mkdir ~/.vnc && echo "${PASS}" | /usr/bin/vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd
RUN echo "openbox-session" > ~/.vnc/xstartup && chmod +x ~/.vnc/xstartup

# Configure xrdp to start openbox on user login.
RUN echo "exec openbox-session" > ~/startwm.sh && chmod +x ~/startwm.sh

# Start supervisord as root.
USER root

# VNC, RDP, noVNC
EXPOSE 5901
EXPOSE 3389
EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
