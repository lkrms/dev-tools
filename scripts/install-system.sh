#!/bin/bash

if [ "$(uname -s)" != "Linux" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

. /etc/lsb-release

echo -e "Upgrading everything that's currently installed...\n"

sudo apt-get update || exit 1
sudo apt-get -y dist-upgrade || exit 1

echo -e "Installing missing drivers...\n"

sudo ubuntu-drivers autoinstall || exit 1

echo -e "Installing software-properties-common to get add-apt-repository...\n"

sudo apt-get -y install software-properties-common || exit 1

echo -e "Adding all required apt repositories...\n"

OLD_SOURCES="$(cat /etc/apt/sources.list /etc/apt/sources.list.d/*.list)"

cat /etc/apt/sources.list.d/*.list | grep -q 'caffeine-developers/ppa' || sudo add-apt-repository -y ppa:caffeine-developers/ppa || exit 1
cat /etc/apt/sources.list.d/*.list | grep -q 'phoerious/keepassxc' || sudo add-apt-repository -y ppa:phoerious/keepassxc || exit 1
cat /etc/apt/sources.list.d/*.list | grep -q 'scribus/ppa' || sudo add-apt-repository -y ppa:scribus/ppa || exit 1
cat /etc/apt/sources.list.d/*.list | grep -q 'wereturtle/ppa' || sudo add-apt-repository -y ppa:wereturtle/ppa || exit 1

cat /etc/apt/sources.list | grep -q '^deb .*'"$DISTRIB_CODENAME"'.*partner' || sudo add-apt-repository -y "deb http://archive.canonical.com/ubuntu $DISTRIB_CODENAME partner"

if [ ! -f /etc/apt/sources.list.d/docker.list ]; then

    wget -O - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - || exit 1
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $DISTRIB_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null || exit 1

fi

if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then

    wget -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - || exit 1
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null || exit 1

fi

if [ ! -f /etc/apt/sources.list.d/owncloud-client.list ]; then

    wget -O - https://download.opensuse.org/repositories/isv:ownCloud:desktop/Ubuntu_$DISTRIB_RELEASE/Release.key | sudo apt-key add - || exit 1
    echo "deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_$DISTRIB_RELEASE/ /" | sudo tee /etc/apt/sources.list.d/owncloud-client.list >/dev/null || exit 1

fi

if [ ! -f /etc/apt/sources.list.d/sublime-text.list ]; then

    wget -O - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add - || exit 1
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list >/dev/null || exit 1

fi

if [ ! -f /etc/apt/sources.list.d/virtualbox.list ]; then

    wget -O - https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo apt-key add - || exit 1
    echo "deb http://download.virtualbox.org/virtualbox/debian $DISTRIB_CODENAME contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list >/dev/null || exit 1

fi

if [ ! -f /etc/apt/sources.list.d/spotify.list ]; then

    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0DF731E45CE24F27EEEB1450EFDC8610341D9410 || exit 1
    echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null || exit 1

fi

if [ ! -f /etc/apt/sources.list.d/typora.list ]; then

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BA300B7755AFCFAE || exit 1
    echo "deb http://typora.io linux/" | sudo tee /etc/apt/sources.list.d/typora.list >/dev/null || exit 1

fi

if [ "$(cat /etc/apt/sources.list /etc/apt/sources.list.d/*.list)" != "$OLD_SOURCES" ]; then

    echo -e "Repositories have changed; running apt-get update...\n"

    sudo apt-get update || exit 1

fi

echo -e "Installing everything you might need...\n"

sudo apt-get -y install \
    apache2 \
    attr \
    autokey-gtk \
    blueman \
    build-essential \
    caffeine \
    dconf-editor \
    debconf-utils \
    dkms \
    docker-ce \
    docker-compose \
    filezilla \
    firefox \
    geany \
    ghostscript \
    ghostwriter \
    gimp \
    git \
    google-chrome-stable \
    heirloom-mailx \
    imagemagick \
    indicator-multiload \
    inkscape \
    iotop \
    keepassxc \
    lib32ncurses5 \
    lib32z1 \
    libapache2-mod-php \
    libpam0g:i386 \
    libqt5script5 \
    libreoffice \
    mariadb-server \
    meld \
    mysql-workbench \
    nodejs \
    npm \
    openssh-server \
    owncloud-client \
    pdftk \
    php \
    php-bcmath \
    php-cli \
    php-curl \
    php-dev \
    php-gd \
    php-gettext \
    php-imagick \
    php-imap \
    php-json \
    php-mbstring \
    php-mcrypt \
    php-mysql \
    php-pear \
    php-soap \
    php-xdebug \
    php-xml \
    php-xmlrpc \
    pv \
    python \
    python-dateutil \
    python-dev \
    python-mysqldb \
    python-requests \
    qtdeclarative5-controls-plugin \
    qtdeclarative5-dialogs-plugin \
    remmina \
    ruby \
    scribus \
    shutter \
    speedcrunch \
    spotify-client \
    sublime-text \
    syslinux-utils \
    thunderbird \
    traceroute \
    trickle \
    typora \
    usb-creator-gtk \
    vim \
    virtualbox-5.2 \
    vlc \
    whois \
    x11vnc \
    || exit 1

sudo adduser "$USER" vboxusers || exit 1
sudo groupadd -f docker || exit 1
sudo adduser "$USER" docker || exit 1

pushd "$HOME/Downloads" >/dev/null

wget -c http://get.code-industry.net/public/master-pdf-editor-4.3.61_qt5.amd64.deb || exit 1
wget -c https://dbeaver.jkiss.org/files/dbeaver-ce_latest_amd64.deb || exit 1
wget -c https://download.teamviewer.com/download/linux/teamviewer_amd64.deb || exit 1
wget -c https://downloads.slack-edge.com/linux_releases/slack-desktop-3.0.0-amd64.deb || exit 1
wget -c https://github.com/aluxian/Messenger-for-Desktop/releases/download/v2.0.9/messengerfordesktop-2.0.9-linux-amd64.deb || exit 1
wget -c https://github.com/hluk/CopyQ/releases/download/v3.1.1/copyq_3.1.1_Ubuntu_16.04-1_amd64.deb || exit 1
wget -c https://go.skype.com/skypeforlinux-64.deb || exit 1
wget -c https://release.gitkraken.com/linux/gitkraken-amd64.deb || exit 1

sudo dpkg -EGi copyq_3.1.1_Ubuntu_16.04-1_amd64.deb dbeaver-ce_latest_amd64.deb gitkraken-amd64.deb master-pdf-editor-4.3.61_qt5.amd64.deb messengerfordesktop-2.0.9-linux-amd64.deb skypeforlinux-64.deb slack-desktop-3.0.0-amd64.deb teamviewer_amd64.deb || exit 1

popd >/dev/null

echo -e "Disabling TeamViewer daemon...\n"

sudo teamviewer daemon disable >/dev/null 2>&1

echo -e "Configuring MariaDB (MySQL)...\n"

if [ ! -f /etc/mysql/mariadb.conf.d/51-custom.cnf ]; then

    sudo tee "/etc/mysql/mariadb.conf.d/51-custom.cnf" >/dev/null <<EOF
[mysqld]
max_allowed_packet = 128M
table_open_cache = 250
innodb_file_per_table = 1
EOF

    sudo service mysql restart

fi

echo -e "Configuring PHP...\n"

function applyPhpSetting {

    INIFILE=$1
    SETTINGNAME=$2
    SETTINGVALUE=$3

    if grep -qE "^\s*${SETTINGNAME}\s*=" "$INIFILE"; then

        # we have a defined setting to replace
        sudo sed -ri "s#^\s*${SETTINGNAME}\s*=.*\$#${SETTINGNAME} = ${SETTINGVALUE}#" "$INIFILE"

    elif grep -qE "^\s*;\s*${SETTINGNAME}\s*=" "$INIFILE"; then

        # we have a commented-out setting to replace
        sudo sed -ri "s#^\s*;\s*${SETTINGNAME}\s*=.*\$#${SETTINGNAME} = ${SETTINGVALUE}#" "$INIFILE"

    else

        echo "${SETTINGNAME} = ${SETTINGVALUE}" | sudo tee -a "$INIFILE" >/dev/null

    fi

}

function enablePhpExtension {

    INIFILE=$1
    SETTINGNAME=$2
    SETTINGVALUE=$3

    # as above, except we're matching on value too
    if grep -qE "^\s*${SETTINGNAME}\s*=\s*${SETTINGVALUE}\s*$" "$INIFILE"; then

        # we have a defined setting to replace
        sudo sed -ri "s#^\s*${SETTINGNAME}\s*=\s*${SETTINGVALUE}\s*\$#${SETTINGNAME} = ${SETTINGVALUE}#" "$INIFILE"

    elif grep -qE "^\s*;\s*${SETTINGNAME}\s*=\s*${SETTINGVALUE}\s*$" "$INIFILE"; then

        # we have a commented-out setting to replace
        sudo sed -ri "s#^\s*;\s*${SETTINGNAME}\s*=\s*${SETTINGVALUE}\s*\$#${SETTINGNAME} = ${SETTINGVALUE}#" "$INIFILE"

    else

        echo "${SETTINGNAME} = ${SETTINGVALUE}" | sudo tee -a "$INIFILE" >/dev/null

    fi

}

sudo mkdir -p /usr/local/lib/php/extensions && sudo chown ${USER}:$(id -g) /usr/local/lib/php/extensions

[ -d /etc/php ] && find /etc/php -name php.ini -type f | while read INI; do

    [ -f "${INI}.original" ] || sudo cp -p "$INI" "${INI}.original"

    applyPhpSetting "$INI" error_reporting E_ALL
    applyPhpSetting "$INI" display_errors On
    applyPhpSetting "$INI" display_startup_errors On
    applyPhpSetting "$INI" xdebug.profiler_enable 1
    applyPhpSetting "$INI" xdebug.remote_enable 1
    applyPhpSetting "$INI" xdebug.remote_connect_back 1

    [ -d /usr/local/lib/php/extensions ] && find /usr/local/lib/php/extensions -name '*.so' -type f | while read EXTENSION; do

        if [ "$(basename "$EXTENSION")" != "xdebug.so" ]; then

            enablePhpExtension "$INI" extension "$EXTENSION"

        else

            enablePhpExtension "$INI" zend_extension "$EXTENSION"

        fi

    done

done

echo -e "Configuring Apache...\n"

sudo mkdir -p /var/www/virtual && sudo chown ${USER}:$(id -g) /var/www/virtual

if [ ! -e /var/www/virtual/127.0.0.1 ]; then

    mkdir -p /var/www/virtual/127.0.0.1

fi

sudo adduser ${USER} www-data
sudo adduser www-data ${USER}

if [ ! -f /etc/apache2/sites-available/virtual.conf ]; then

    sudo tee "/etc/apache2/sites-available/virtual.conf" >/dev/null <<EOF
<VirtualHost *:80>
    VirtualDocumentRoot /var/www/virtual/%0
    VirtualScriptAlias /var/www/virtual/%0
    <FilesMatch "\.(html|htm|js|css|json)$">
        FileETag None
        <IfModule mod_headers.c>
            Header unset ETag
            Header set Cache-Control "max-age=0, no-cache, no-store, must-revalidate"
            Header set Pragma "no-cache"
            Header set Expires "Wed, 11 Jan 1984 05:00:00 GMT"
        </IfModule>
    </FilesMatch>
    <Directory />
        Options FollowSymLinks
        AllowOverride None
    </Directory>
    <Directory /var/www/virtual/>
        Options Indexes FollowSymLinks
        AllowOverride all
        Require all granted
    </Directory>
</VirtualHost>
EOF

fi

sudo rm /etc/apache2/sites-enabled/*
sudo ln -sf ../sites-available/virtual.conf /etc/apache2/sites-enabled/virtual.conf

sudo a2enmod headers
sudo a2enmod rewrite
sudo a2enmod vhost_alias

sudo service apache2 restart

echo -e "Configuring VNC...\n"

if [ ! -f "$HOME/.vnc/passwd" ]; then

    echo -e "\nNo password has been set for VNC. Please provide one.\n\n"
    x11vnc -storepasswd

fi

if [ ! -f /lib/systemd/system/x11vnc.service ]; then

    sudo tee "/lib/systemd/system/x11vnc.service" >/dev/null <<EOF
[Unit]
Description=Start x11vnc at startup.
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth "$HOME/.vnc/passwd" -rfbport 5900 -shared

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable x11vnc.service
    sudo systemctl start x11vnc.service

fi

# use Meld as our default merge / diff tool
if [ "$(git config --global merge.tool)" == "" ]; then

    git config --global merge.tool meld
    git config --global --bool mergetool.prompt false

fi

# GitKraken supports KDiff, but not Meld, so ...
command -v kdiff3 >/dev/null 2>&1 || sudo ln -s /usr/bin/meld /usr/local/bin/kdiff3

# on Ubuntu, move launcher to bottom
gsettings set com.canonical.Unity.Launcher launcher-position Bottom

echo -e "\n\nDone. You may also want to install: libpam-gnome-keyring (if this is a Lubuntu installation), unity-tweak-tool, compizconfig-settings-manager"

echo -e "\n\nPlanning to work with Docker and Dory? Consider adding a '#' before 'dns=dnsmasq' in /etc/NetworkManager/NetworkManager.conf, disable Apache with 'systemctl disable apache2.service', and reboot."

echo -e "\n\n"

