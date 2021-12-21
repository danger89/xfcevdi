FROM debian:bullseye

LABEL maintainer="melroy@melroy.org"

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_PROXY

WORKDIR /app

# Enable APT proxy (if APT_PROXY is set)
COPY ./configs/apt.conf ./
COPY ./apt_proxy.sh ./
RUN ./apt_proxy.sh

## First install basic require packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    dirmngr gnupg gnupg-l10n \
    gnupg-utils gpg gpg-agent \
    gpg-wks-client gpg-wks-server gpgconf \
    gpgsm libassuan0 libksba8 \
    libldap-2.4-2 libldap-common libnpth0 \
    libreadline8 libsasl2-2 libsasl2-modules \
    libsasl2-modules-db libsqlite3-0 libssl1.1 \
    lsb-base pinentry-curses readline-common \
    apt-transport-https ca-certificates curl \
    software-properties-common apt-utils net-tools

## Add additional repositories/components (software-properties-common is required to be installed)
# Add contrib and non-free distro components (deb822-style format)
RUN apt-add-repository -y contrib && apt-add-repository -y non-free
# Add Debian backports repo for XFCE thunar-font-manager 
RUN add-apt-repository -y "deb http://deb.debian.org/debian bullseye-backports main contrib non-free"

# Retrieve third party GPG keys from keyserver
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 302F0738F465C1535761F965A6616109451BBBF2 972FD88FA0BAFB578D0476DFE1F958385BFE2B6E

# Add Linux Mint GPG keyring file (for the Mint-Y-Dark theme)
RUN gpg --export 302F0738F465C1535761F965A6616109451BBBF2 | tee /usr/share/keyrings/linuxmint-archive-keyring.gpg > /dev/null

# Add Linux Mint Debbie repo source file
COPY ./configs/linuxmint-debbie.list /etc/apt/sources.list.d/linuxmint-debbie.list

# Add X2Go GPG keyring file
RUN gpg --export 972FD88FA0BAFB578D0476DFE1F958385BFE2B6E | tee /usr/share/keyrings/x2go-archive-keyring.gpg > /dev/null

# Add X2Go repo source file
COPY ./configs/x2go.list /etc/apt/sources.list.d/x2go.list

## Install X2Go server and session
RUN apt update && apt-get install -y x2go-keyring && apt-get update
RUN apt-get install -y x2goserver x2goserver-xsession
## Install important (or often used) dependency packages
RUN apt-get install -y --no-install-recommends \
    openssh-server \
    pulseaudio \
    locales \
    rsyslog \
    pavucontrol \
    git \
    wget \
    sudo \
    zip \
    bzip2 \
    unzip \
    unrar \
    ffmpeg \
    pwgen \
    nano \
    file \
    dialog \
    at-spi2-core \
    util-linux \
    coreutils \
    xdg-utils \
    xz-utils \
    x11-utils \
    x11-xkb-utils
## Install XFCE4
RUN apt-get upgrade -y && apt-get install -y \
    xfwm4 xfce4-session xfce4-panel \
    xfce4-terminal xfce4-appfinder \
    xfce4-goodies xfce4-pulseaudio-plugin \
    xfce4-statusnotifier-plugin xfce4-whiskermenu-plugin \
    thunar tumbler xarchiver \
    mugshot thunar-archive-plugin

## Add themes & fonts
RUN apt-get install -y --no-install-recommends fonts-ubuntu breeze-gtk-theme mint-themes
# Don't add papirus icons (can be comment-out if you want)
#RUN apt install -y papirus-icon-theme

## Add additional applications
RUN apt-get install -y --no-install-recommends firefox-esr htop gnome-calculator mousepad ristretto
# Add Office
RUN apt install -y libreoffice-base libreoffice-base-core libreoffice-common libreoffice-core libreoffice-base-drivers \
    libreoffice-nlpsolver libreoffice-script-provider-bsh libreoffice-script-provider-js libreoffice-script-provider-python libreoffice-style-colibre \
    libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-draw libreoffice-math 

# Update locales, generate new SSH host keys and clean-up (keep manpages)
RUN update-locale
RUN rm -rf /etc/ssh/ssh_host_* \
    && ssh-keygen -A
RUN apt-get clean -y && rm -rf /usr/share/doc/* /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apk/*

# Update timezone to The Netherlands
RUN echo 'Europe/Amsterdam' > /etc/timezone
RUN unlink /etc/localtime && ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime

# Start default XFCE4 panels (don't ask for it)
RUN mv -f /etc/xdg/xfce4/panel/default.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
# Use mice as default Splash
COPY ./configs/xfconf/xfce4-session.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
# Add XFCE4 settings to start-up
COPY ./configs/xfce4-settings.desktop /etc/xdg/autostart/
# Enable Clipman by default during start-up
RUN sed -i "s/Hidden=.*/Hidden=false/" /etc/xdg/autostart/xfce4-clipman-plugin-autostart.desktop
# Remove unnecessary existing start-up apps
RUN rm -rf /etc/xdg/autostart/light-locker.desktop /etc/xdg/autostart/xscreensaver.desktop
COPY ./setup.sh ./
COPY ./configs/terminalrc ./
COPY ./configs/whiskermenu-1.rc ./
COPY ./xfce_settings.sh ./
COPY ./run.sh ./

EXPOSE 22

CMD ./run.sh