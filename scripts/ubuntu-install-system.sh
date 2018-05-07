#!/bin/bash

if [ "$(uname -s)" != "Linux" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

. /etc/lsb-release || exit 2

if [ "$DISTRIB_ID" != "Ubuntu" ]; then

    echo "Error: $(basename "$0") is not supported on this distribution."
    exit 1

fi

if [ "$DISTRIB_CODENAME" != "xenial" -a "$DISTRIB_CODENAME" != "bionic" ]; then

    echo "Error: $(basename "$0") is only supported on LTS releases of Ubuntu."
    exit 1

fi

echo -e "Upgrading everything that's currently installed...\n"

sudo apt-get update || exit 1
sudo apt-get -y dist-upgrade || exit 1
sudo snap refresh || exit 1

echo -e "Installing missing drivers...\n"

DRIVER_ERRORS=0

sudo ubuntu-drivers autoinstall || DRIVER_ERRORS=1

echo -e "Installing software-properties-common to get add-apt-repository...\n"

sudo apt-get -y install software-properties-common || exit 1

echo -e "Adding all required apt repositories...\n"

OLD_SOURCES="$(cat /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null)"

cat /etc/apt/sources.list.d/*.list 2>/dev/null | grep -q 'alexlarsson/flatpak' || sudo add-apt-repository -y ppa:alexlarsson/flatpak || exit 1
cat /etc/apt/sources.list.d/*.list | grep -q 'stebbins/handbrake-releases' || sudo add-apt-repository -y ppa:stebbins/handbrake-releases || exit 1

# Ghostwriter
cat /etc/apt/sources.list.d/*.list | grep -q 'wereturtle/ppa' || sudo add-apt-repository -y ppa:wereturtle/ppa || exit 1

if [ "$DISTRIB_CODENAME" == "xenial" ]; then

    # bionic provides up-to-date versions of these out-of-the-box
    cat /etc/apt/sources.list.d/*.list | grep -q 'caffeine-developers/ppa' || sudo add-apt-repository -y ppa:caffeine-developers/ppa || exit 1
    cat /etc/apt/sources.list.d/*.list | grep -q 'inkscape.dev/stable' || sudo add-apt-repository -y ppa:inkscape.dev/stable || exit 1
    cat /etc/apt/sources.list.d/*.list | grep -q 'linrunner/tlp' || sudo add-apt-repository -y ppa:linrunner/tlp || exit 1
    cat /etc/apt/sources.list.d/*.list | grep -q 'phoerious/keepassxc' || sudo add-apt-repository -y ppa:phoerious/keepassxc || exit 1
    cat /etc/apt/sources.list.d/*.list | grep -q 'scribus/ppa' || sudo add-apt-repository -y ppa:scribus/ppa || exit 1

else

    # CopyQ's PPA version depends on Qt 5, so we install an old version on xenial
    cat /etc/apt/sources.list.d/*.list | grep -q 'hluk/copyq' || sudo add-apt-repository -y ppa:hluk/copyq || exit 1

fi

cat /etc/apt/sources.list | grep -q '^deb .*'"$DISTRIB_CODENAME"'.*partner' || sudo add-apt-repository -y "deb http://archive.canonical.com/ubuntu $DISTRIB_CODENAME partner"

if [ ! -f /etc/apt/sources.list.d/docker.list ]; then

    DOCKER_CODENAME=$DISTRIB_CODENAME

    # temporary workaround until Docker adds support for bionic
    [ "$DISTRIB_CODENAME" == "bionic" ] && DOCKER_CODENAME=artful

    wget -O - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - || exit 1
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $DOCKER_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null || exit 1

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
    echo "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $DISTRIB_CODENAME contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list >/dev/null || exit 1

fi

if [ ! -f /etc/apt/sources.list.d/spotify.list ]; then

    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0DF731E45CE24F27EEEB1450EFDC8610341D9410 || exit 1
    echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null || exit 1

fi

if [ ! -f /etc/apt/sources.list.d/mkvtoolnix.list ]; then

    wget -O - https://mkvtoolnix.download/gpg-pub-moritzbunkus.txt | sudo apt-key add - || exit 1
    echo "deb https://mkvtoolnix.download/ubuntu/ $DISTRIB_CODENAME main" | sudo tee /etc/apt/sources.list.d/mkvtoolnix.list >/dev/null || exit 1

fi

if [ ! -f /etc/apt/sources.list.d/typora.list ]; then

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BA300B7755AFCFAE || exit 1
    echo "deb https://typora.io ./linux/" | sudo tee /etc/apt/sources.list.d/typora.list >/dev/null || exit 1

fi

if [ ! -f /etc/apt/sources.list.d/nodesource.list ]; then

    wget -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add - || exit 1
    echo "deb https://deb.nodesource.com/node_8.x $DISTRIB_CODENAME main" | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null || exit 1
    echo "deb-src https://deb.nodesource.com/node_8.x $DISTRIB_CODENAME main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list >/dev/null || exit 1

fi

if [ ! -f /etc/apt/sources.list.d/yarn.list ]; then

    wget -O - https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - || exit 1
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list >/dev/null || exit 1

fi

if [ "$(cat /etc/apt/sources.list /etc/apt/sources.list.d/*.list)" != "$OLD_SOURCES" ]; then

    echo -e "Repositories have changed; running apt-get update...\n"

    sudo apt-get update || exit 1

fi

echo -e "Installing everything you might need...\n"

# virtualisation
sudo apt-get -y install \
    docker-ce \
    virtualbox-5.2 \
    || exit 1

sudo adduser "$USER" vboxusers || exit 1
sudo groupadd -f docker || exit 1
sudo adduser "$USER" docker || exit 1

# laptop power management; see http://linrunner.de/en/tlp/docs/tlp-linux-advanced-power-management.html
sudo apt-get -y install \
    acpi-call-dkms \
    dkms \
    tlp \
    tlp-rdw \
    tp-smapi-dkms \
    || exit 1

# system / network / terminal utilities
sudo apt-get -y install \
    aptitude \
    attr \
    debconf-utils \
    hwinfo \
    iotop \
    net-tools \
    nethogs \
    openssh-server \
    powertop \
    pv \
    s-nail \
    syslinux-utils \
    traceroute \
    trickle \
    vim \
    whois \
    || exit 1

# package / dependency managers
sudo apt-get -y install \
    flatpak \
    yarn \
    || exit 1

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || exit 1

# Pandoc
sudo apt-get -y install \
    pandoc \
    texlive-fonts-recommended \
    texlive-latex-recommended \
    || exit 1

# PDF manipulation
sudo apt-get -y install \
    ghostscript \
    || exit 1

if dpkg -s pdftk >/dev/null 2>&1; then

    echo -e "Removing pdftk...\n"

    sudo apt-get -y purge pdftk

fi

# indicator-based apps
sudo apt-get -y install \
    autokey-gtk \
    blueman \
    caffeine \
    indicator-multiload \
    shutter \
    || exit 1

if [ "$DISTRIB_CODENAME" != "xenial" ]; then

    sudo apt-get -y install \
        copyq \
        || exit 1

fi

# utility apps
sudo apt-get -y install \
    dconf-editor \
    remmina \
    speedcrunch \
    usb-creator-gtk \
    x11vnc \
    || exit 1

# desktop essentials
sudo apt-get -y install \
    filezilla \
    firefox \
    galculator \
    geany \
    ghostwriter \
    gimp \
    google-chrome-stable \
    handbrake-cli \
    handbrake-gtk \
    inkscape \
    keepassxc \
    libdvd-pkg \
    libreoffice \
    mkvtoolnix \
    mkvtoolnix-gui \
    owncloud-client \
    scribus \
    spotify-client \
    thunderbird \
    typora \
    vlc \
    || exit 1

# development
sudo apt-get -y install \
    build-essential \
    git \
    nodejs \
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
    php-mysql \
    php-pear \
    php-soap \
    php-xdebug \
    php-xml \
    php-xmlrpc \
    python \
    python-dateutil \
    python-dev \
    python-mysqldb \
    python-requests \
    ruby \
    || exit 1

if [ "$DISTRIB_CODENAME" == "xenial" ]; then

    # removed from PHP 7.2, which ships with bionic
    sudo apt-get -y install \
        php-mcrypt \
        || exit 1

fi

# services for development
sudo apt-get -y install \
    apache2 \
    libapache2-mod-php \
    mariadb-server \
    || exit 1

# desktop apps for development
sudo apt-get -y install \
    meld \
    mysql-workbench \
    sublime-text \
    || exit 1

# needed for MakeMKV (see: http://www.makemkv.com/forum2/viewtopic.php?f=3&t=224)
sudo apt-get -y install \
    pkg-config \
    libc6-dev \
    libssl-dev \
    libexpat1-dev \
    libavcodec-dev \
    libgl1-mesa-dev \
    libqt4-dev \
    zlib1g-dev \
    || exit 1

# needed for Synergy installation
sudo apt-get -y install \
    libavahi-compat-libdnssd1 \
    || exit 1

# needed for Db2 installation
sudo apt-get -y install \
    libpam0g:i386 \
    || exit 1

# needed for Cisco AnyConnect client
sudo apt-get -y install \
    lib32ncurses5 \
    lib32z1 \
    || exit 1

if dpkg -s deja-dup >/dev/null 2>&1; then

    echo -e "Removing deja-dup...\n"

    sudo apt-get -y purge deja-dup

fi

mkdir -p "$HOME/Downloads/install" || exit 1

pushd "$HOME/Downloads/install" >/dev/null

# delete package files more than 24 hours old
find . -maxdepth 1 -type f -name '*.deb' -mtime +1 -delete

wget -c --no-use-server-timestamps http://get.code-industry.net/public/master-pdf-editor-4.3.89_qt5.amd64.deb || exit 1
wget -c --no-use-server-timestamps https://dbeaver.jkiss.org/files/dbeaver-ce_latest_amd64.deb || exit 1
wget -c --no-use-server-timestamps https://download.teamviewer.com/download/linux/teamviewer_amd64.deb || exit 1
wget -c --no-use-server-timestamps https://github.com/saenzramiro/rambox/releases/download/0.5.17/Rambox_0.5.17-x64.deb || exit 1
wget -c --no-use-server-timestamps https://go.skype.com/skypeforlinux-64.deb || exit 1
wget -c --no-use-server-timestamps https://release.gitkraken.com/linux/gitkraken-amd64.deb || exit 1

if [ "$DISTRIB_CODENAME" == "xenial" ]; then

    wget -c --no-use-server-timestamps https://downloads.slack-edge.com/linux_releases/slack-desktop-3.1.1-amd64.deb || exit 1
    wget -c --no-use-server-timestamps https://github.com/hluk/CopyQ/releases/download/v3.1.1/copyq_3.1.1_Ubuntu_16.04-1_amd64.deb || exit 1

fi

sudo dpkg -EGi *.deb || sudo aptitude -yf install || exit 1

popd >/dev/null

echo -e "Installing snaps...\n"

if [ "$DISTRIB_CODENAME" != "xenial" ]; then

    sudo snap install slack --classic || exit 1

fi

echo -e "Installing npm packages...\n"
sudo npm install -g jslint || exit 1

# Sublime Text expects "jsl" to be on the path, so make it so
command -v jsl >/dev/null 2>&1 || sudo ln -s /usr/bin/jslint /usr/local/bin/jsl

echo -e "Updating all npm packages...\n"
sudo npm update -g || exit 1

echo -e "Installing flatpack packages...\n"
flatpak install -y flathub org.baedert.corebird || exit 1

echo -e "Updating all flatpak packages...\n"
flatpak update || exit 1

echo -e "Configuring TLP (power management)...\n"

function applyTlpSetting {

    INIFILE=$1
    SETTINGNAME=$2
    SETTINGVALUE=$3

    if grep -qE "^${SETTINGNAME}=" "$INIFILE"; then

        # we have a defined setting to replace
        sudo sed -ri "s;^${SETTINGNAME}=.*\$;${SETTINGNAME}=${SETTINGVALUE};" "$INIFILE"

    elif grep -qE "^#${SETTINGNAME}=" "$INIFILE"; then

        # we have a commented-out setting to replace
        sudo sed -ri "s;^#${SETTINGNAME}=.*\$;${SETTINGNAME}=${SETTINGVALUE};" "$INIFILE"

    else

        echo "${SETTINGNAME}=${SETTINGVALUE}" | sudo tee -a "$INIFILE" >/dev/null

    fi

}

sudo update-rc.d -f ondemand remove || exit 1

INI="/etc/default/tlp"

if [ -f "$INI" ]; then

    [ -f "${INI}.original" ] || sudo cp -p "$INI" "${INI}.original"

    applyTlpSetting "$INI" CPU_SCALING_GOVERNOR_ON_AC performance
    applyTlpSetting "$INI" CPU_SCALING_GOVERNOR_ON_BAT powersave
    applyTlpSetting "$INI" CPU_HWP_ON_AC performance
    applyTlpSetting "$INI" CPU_HWP_ON_BAT balance_power
    applyTlpSetting "$INI" CPU_BOOST_ON_AC 1
    applyTlpSetting "$INI" CPU_BOOST_ON_BAT 0
    applyTlpSetting "$INI" USB_BLACKLIST_BTUSB 1
    applyTlpSetting "$INI" USB_BLACKLIST_PHONE 1

fi

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
    VirtualDocumentRoot /var/www/virtual/%0/html
    VirtualScriptAlias /var/www/virtual/%0/html
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
    <Directory /var/www/virtual/*/html>
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

# x11vnc can't currently be configured to start before login on bionic; see http://c-nergy.be/blog/?p=8984
if [ "$DISTRIB_CODENAME" == "xenial" ]; then

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

fi

# use Meld as our default merge / diff tool
if [ "$(git config --global merge.tool)" == "" ]; then

    git config --global merge.tool meld
    git config --global --bool mergetool.prompt false

fi

# GitKraken supports KDiff, but not Meld, so ...
command -v kdiff3 >/dev/null 2>&1 || sudo ln -s /usr/bin/meld /usr/local/bin/kdiff3

# move launcher to bottom
if [ "$DISTRIB_CODENAME" == "xenial" ]; then

    gsettings set com.canonical.Unity.Launcher launcher-position Bottom

elif [ "$DISTRIB_CODENAME" == "bionic" ]; then

    gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM
    gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true

fi

echo -e "\n\nDone. You may also want to install: libpam-gnome-keyring (if this is a Lubuntu installation), unity-tweak-tool, compizconfig-settings-manager"

echo -e "\n\nPlanning to work with Docker and Dory? Consider adding a '#' before 'dns=dnsmasq' in /etc/NetworkManager/NetworkManager.conf, disable Apache with 'systemctl disable apache2.service', and reboot."

echo -e "\n\nTo complete the installation of libdvdcss, you may need to run: dpkg-reconfigure libdvd-pkg"

if [ "$DRIVER_ERRORS" -ne "0" ]; then

    echo -e "\n\nIMPORTANT: an error was encountered while installing missing drivers. Run 'ubuntu-drivers autoinstall' to try again."

fi

echo -e "\n\n"

