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

CLI_ONLY=0

# i.e. no GUI software, drivers, virtualisation etc.
[ -e /proc/version ] && grep -q Microsoft /proc/version && CLI_ONLY=1

echo -e "Upgrading everything that's currently installed...\n"

sudo apt-get update || exit 1
sudo apt-get -y dist-upgrade || exit 1
[ "$CLI_ONLY" -eq "0" ] && { sudo snap refresh || exit 1; }

# disabled due to issues with nvidia drivers
#
#echo -e "Installing missing drivers...\n"
#
DRIVER_ERRORS=0
#
#sudo ubuntu-drivers autoinstall || DRIVER_ERRORS=1

echo -e "Installing software-properties-common to get add-apt-repository...\n"

sudo apt-get -y install software-properties-common || exit 1

echo -e "Adding all required apt repositories...\n"

OLD_SOURCES="$(cat /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null)"

#cat /etc/apt/sources.list.d/*.list | grep -q 'alexlarsson/flatpak' || sudo add-apt-repository -y ppa:alexlarsson/flatpak || exit 1

if [ "$CLI_ONLY" -eq "0" ]; then

    cat /etc/apt/sources.list.d/*.list | grep -q 'eosrei/fonts' || sudo add-apt-repository -y ppa:eosrei/fonts || exit 1
    cat /etc/apt/sources.list.d/*.list | grep -q 'stebbins/handbrake-releases' || sudo add-apt-repository -y ppa:stebbins/handbrake-releases || exit 1

    # touchpad-indicator
    cat /etc/apt/sources.list.d/*.list | grep -q 'atareao/atareao' || sudo add-apt-repository -y ppa:atareao/atareao || exit 1

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
        echo "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $DISTRIB_CODENAME contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list >/dev/null || exit 1

    fi

    if [ ! -f /etc/apt/sources.list.d/spotify.list ]; then

        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90 || exit 1
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

    if [ ! -f /etc/apt/sources.list.d/microsoft.list ]; then

        wget -O - https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - || exit 1
        echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/$DISTRIB_RELEASE/prod $DISTRIB_CODENAME main" | sudo tee /etc/apt/sources.list.d/microsoft.list >/dev/null || exit 1

    fi

fi

cat /etc/apt/sources.list | grep -q '^deb .*'"$DISTRIB_CODENAME"'.*partner' || sudo add-apt-repository -y "deb http://archive.canonical.com/ubuntu $DISTRIB_CODENAME partner"

# enable manual installation of "proposed" packages
cat /etc/apt/sources.list | grep -q '^deb .*'"$DISTRIB_CODENAME"'-proposed' || sudo add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu/ ${DISTRIB_CODENAME}-proposed restricted main multiverse universe"

if [ ! -f /etc/apt/preferences.d/proposed-updates ]; then

    sudo tee "/etc/apt/preferences.d/proposed-updates" >/dev/null <<EOF
Package: *
Pin: release a=${DISTRIB_CODENAME}-proposed
Pin-Priority: 400
EOF

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

function apt_get {

    for p in "$@"; do

        if ! dpkg -s $p >/dev/null 2>&1; then

            APT_GET_PENDING+=($p)

        fi

    done

}

function apt_remove {

    for p in "$@"; do

        if dpkg -s $p >/dev/null 2>&1; then

            APT_REMOVE_PENDING+=($p)

        fi

    done

}

function do_apt_get {

    if [ "${#APT_GET_PENDING[@]}" -gt "0" ]; then

        sudo apt-get -y install "${APT_GET_PENDING[@]}" || exit 1

        APT_GET_PENDING=()

    fi

    if [ "${#APT_REMOVE_PENDING[@]}" -gt "0" ]; then

        sudo apt-get -y purge "${APT_REMOVE_PENDING[@]}" || exit 1

        APT_REMOVE_PENDING=()

    fi

}

APT_GET_PENDING=()
APT_REMOVE_PENDING=()

# virtualisation
[ "$CLI_ONLY" -eq "0" ] && apt_get \
    docker-ce \
    virtualbox-5.2 \

# power management; see http://linrunner.de/en/tlp/docs/tlp-linux-advanced-power-management.html
[ "$CLI_ONLY" -eq "0" ] && apt_get \
    acpi-call-dkms \
    dkms \
    tlp \
    tlp-rdw \
    tp-smapi-dkms \

# system / network / terminal utilities
apt_get \
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

# package / dependency managers
apt_get \
    yarn \

#apt_get \
#    flatpak \

# Pandoc
[ "$CLI_ONLY" -eq "0" ] && apt_get \
    pandoc \
    texlive-fonts-recommended \
    texlive-latex-recommended \

# PDF manipulation
apt_get \
    ghostscript \

apt_remove \
    pdftk \

# indicator-based apps
[ "$CLI_ONLY" -eq "0" ] && apt_get \
    autokey-gtk \
    blueman \
    shutter \
    touchpad-indicator \

if [ "$DISTRIB_CODENAME" != "xenial" ]; then

    [ "$CLI_ONLY" -eq "0" ] && apt_get \
        copyq \

fi

# utility apps
[ "$CLI_ONLY" -eq "0" ] && apt_get \
    dconf-editor \
    gconf-editor \
    remmina \
    seahorse \
    synergy \
    tilix \
    usb-creator-gtk \
    x11vnc \

# desktop essentials
[ "$CLI_ONLY" -eq "0" ] && apt_get \
    filezilla \
    firefox \
    fonts-symbola \
    fonts-twemoji-svginot \
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
    speedcrunch \
    spotify-client \
    thunderbird \
    typora \
    vlc \

# photography
[ "$CLI_ONLY" -eq "0" ] && apt_get \
    geeqie \
    rapid-photo-downloader \

apt_get \
    libmediainfo0v5 \

# development
apt_get \
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

if [ "$DISTRIB_CODENAME" == "xenial" ]; then

    # removed from PHP 7.2, which ships with bionic
    apt_get \
        php-mcrypt \

    [ "$CLI_ONLY" -eq "0" ] && apt_get \
        powershell \

else

    [ "$CLI_ONLY" -eq "0" ] && apt_get \
        powershell-preview \

fi

# services for development
apt_get \
    apache2 \
    libapache2-mod-php \
    mariadb-server \

# desktop apps for development
[ "$CLI_ONLY" -eq "0" ] && apt_get \
    git-cola \
    meld \
    mysql-workbench \
    sublime-text \

# needed for MakeMKV (see: http://www.makemkv.com/forum2/viewtopic.php?f=3&t=224)
[ "$CLI_ONLY" -eq "0" ] && apt_get \
    pkg-config \
    libc6-dev \
    libssl-dev \
    libexpat1-dev \
    libavcodec-dev \
    libgl1-mesa-dev \
    libqt4-dev \
    zlib1g-dev \

# needed for Db2 installation
#[ "$CLI_ONLY" -eq "0" ] && apt_get \
#    libpam0g:i386 \

# needed for Cisco AnyConnect client
[ "$CLI_ONLY" -eq "0" ] && apt_get \
    lib32ncurses5 \
    lib32z1 \
    libpangox-1.0-0 \
    network-manager-openconnect \

apt_remove deja-dup
[ "$CLI_ONLY" -eq "0" ] && apt_remove apport

do_apt_get

echo -e "Applying post-install tweaks...\n"

#flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || exit 1

if [ "$CLI_ONLY" -eq "0" ]; then

    sudo adduser "$USER" vboxusers || exit 1
    sudo groupadd -f docker || exit 1
    sudo adduser "$USER" docker || exit 1

    mkdir -p "$HOME/Downloads/install" || exit 1

    pushd "$HOME/Downloads/install" >/dev/null

    # delete package files more than 24 hours old
    find . -maxdepth 1 -type f -name '*.deb' -mtime +1 -delete

    wget -c --no-use-server-timestamps --content-disposition https://go.microsoft.com/fwlink/?LinkID=760868 || exit 1
    wget -c --no-use-server-timestamps https://code-industry.net/public/master-pdf-editor-5.1.30_qt5.amd64.deb || exit 1
    wget -c --no-use-server-timestamps https://dbeaver.jkiss.org/files/dbeaver-ce_latest_amd64.deb || exit 1
    wget -c --no-use-server-timestamps https://download.teamviewer.com/download/linux/teamviewer_amd64.deb || exit 1
    wget -c --no-use-server-timestamps https://github.com/ramboxapp/community-edition/releases/download/0.6.1/Rambox-0.6.1-linux-amd64.deb || exit 1
    wget -c --no-use-server-timestamps https://go.skype.com/skypeforlinux-64.deb || exit 1
    wget -c --no-use-server-timestamps https://release.gitkraken.com/linux/gitkraken-amd64.deb || exit 1

    if [ "$DISTRIB_CODENAME" == "xenial" ]; then

        wget -c --no-use-server-timestamps https://downloads.slack-edge.com/linux_releases/slack-desktop-3.2.1-amd64.deb || exit 1
        wget -c --no-use-server-timestamps https://github.com/hluk/CopyQ/releases/download/v3.1.1/copyq_3.1.1_Ubuntu_16.04-1_amd64.deb || exit 1

    else

        # required by Shutter on Ubuntu > 17.10
        wget -c --no-use-server-timestamps https://launchpad.net/ubuntu/+archive/primary/+files/libgoocanvas-common_1.0.0-1_all.deb || exit 1
        wget -c --no-use-server-timestamps https://launchpad.net/ubuntu/+archive/primary/+files/libgoocanvas3_1.0.0-1_amd64.deb || exit 1
        wget -c --no-use-server-timestamps https://launchpad.net/ubuntu/+archive/primary/+files/libgoo-canvas-perl_0.06-2ubuntu3_amd64.deb || exit 1

    fi

    sudo dpkg -EGi *.deb || sudo aptitude -yf install || exit 1

    popd >/dev/null

    echo -e "Installing snaps...\n"

    if [ "$DISTRIB_CODENAME" != "xenial" ]; then

        sudo snap install slack --classic
        sudo snap install caprine --classic

    fi

fi

echo -e "Installing npm packages...\n"
[ "$CLI_ONLY" -eq "0" ] && { sudo npm install -g jslint || exit 1; }

# Sublime Text expects "jsl" to be on the path, so make it so
[ "$CLI_ONLY" -eq "0" ] && { command -v jsl >/dev/null 2>&1 || sudo ln -s /usr/bin/jslint /usr/local/bin/jsl; }

echo -e "Updating all npm packages...\n"
sudo npm update -g || exit 1

#echo -e "Installing flatpack packages...\n"
#flatpak install -y flathub org.baedert.corebird || exit 1

#echo -e "Updating all flatpak packages...\n"
#flatpak update || exit 1

if [ "$CLI_ONLY" -eq "0" ]; then

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
    applyPhpSetting "$INI" xdebug.profiler_enable 0
    applyPhpSetting "$INI" xdebug.profiler_enable_trigger 1
    applyPhpSetting "$INI" xdebug.remote_enable 1
    applyPhpSetting "$INI" xdebug.remote_connect_back 0

    [ -d /usr/local/lib/php/extensions ] && find /usr/local/lib/php/extensions -name '*.so' -type f | while read EXTENSION; do

        if [ "$(basename "$EXTENSION")" != "xdebug.so" -a "$(basename "$EXTENSION")" != "opcache.so" ]; then

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

if [ "$CLI_ONLY" -eq "0" ]; then

    echo -e "Configuring VNC...\n"

    if [ ! -f "$HOME/.vnc/passwd" ]; then

        echo -e "\nNo password has been set for VNC. Please provide one.\n\n"
        x11vnc -storepasswd

    fi

    # x11vnc can't currently be configured to start before login on bionic; see http://c-nergy.be/blog/?p=8984
    if [ "$DISTRIB_CODENAME" == "xenial" -o "$XDG_CURRENT_DESKTOP" == "XFCE" ]; then

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

    if [ "$XDG_CURRENT_DESKTOP" == "Unity" ]; then

        gsettings set com.canonical.Unity.Launcher launcher-position Bottom

        apt_get \
            caffeine \
            indicator-multiload \
            unity-tweak-tool \

    elif [ "$XDG_CURRENT_DESKTOP" == "ubuntu:GNOME" ]; then

        gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM
        gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
        gsettings set org.gnome.desktop.default-applications.terminal exec /usr/bin/tilix.wrapper
        gsettings set org.gnome.desktop.default-applications.terminal exec-arg '-e'

        apt_get \
            caffeine \
            gnome-tweak-tool \
            indicator-multiload \

        apt_remove \
            gnome-shell-extension-pixelsaver \
            gnome-shell-extension-system-monitor \

        sudo apt-get -y install libappindicator-dev && sudo PERL_MM_USE_DEFAULT=1 cpan -i Gtk2::AppIndicator

    elif [ "$XDG_CURRENT_DESKTOP" == "XFCE" ]; then

        apt_get \
            autorandr \
            disper \
            docky \
            indicator-multiload \

    fi

    do_apt_get

    sudo systemctl stop cups-browsed
    sudo systemctl disable cups-browsed

fi

echo -e "\n\nDone. To complete the installation of libdvdcss, you may need to run: sudo dpkg-reconfigure libdvd-pkg"

if [ "$DRIVER_ERRORS" -ne "0" ]; then

    echo -e "\nIMPORTANT: an error was encountered while installing missing drivers. Run 'ubuntu-drivers autoinstall' to try again."

fi

