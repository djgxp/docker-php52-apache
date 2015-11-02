FROM debian:squeeze

MAINTAINER Gael TREBOS <gael.trebos@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root

RUN apt-get update
RUN apt-get install -y -q --force-yes apt-utils
RUN apt-get install -y -q --force-yes acl vim wget curl git subversion acl htop zip cron openssh-server memcached

# config ssh for easy access
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/\#PermitRootLogin yes/PermitRootlogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd
RUN echo 'SSHD: ALL' >> /etc/hosts.allow
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
RUN echo 'root:password' | chpasswd
RUN mkdir -p /root/.ssh

# install supervisor
RUN apt-get install -y supervisor
RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/run/sshd /var/log/supervisor

# Set locale
RUN apt-get -qqy install locales
RUN sed -i 's/# fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen
RUN /usr/sbin/locale-gen
ENV LANG fr_FR.UTF-8
ENV LANGUAGE fr_FR:fr
ENV LC_ALL fr_FR.UTF-8

# Add devel user for deployment
RUN useradd --system --uid=1000 -s /bin/bash -m -d /home/devel devel
RUN addgroup devel sudo
RUN echo 'devel:password' | chpasswd
RUN mkdir -p /home/devel/.ssh
RUN chown -R devel:devel /home/devel

# php5 from squeeze => 5.2
RUN echo "deb http://archive.debian.org/debian lenny main contrib non-free" > /etc/apt/sources.list.d/php.list
RUN echo "Package: php5 php-apc php-http php-http-request php-net-socket php-net-url php-pear php5-cli php5-common php5-curl php5-dev php5-gd php5-ldap php5-mcrypt php5-mysql php5-xsl" > /etc/apt/preferences.d/lenny
RUN echo "Pin: release n=lenny*" >> /etc/apt/preferences.d/lenny
RUN echo "Pin-Priority: 999" >> /etc/apt/preferences.d/lenny
RUN apt-get update
RUN apt-get install -y php-apc php-http php-http-request php-net-socket php-net-url php-pear php5-cli php5-common php5-curl php5-dev php5-gd php5-ldap php5-mcrypt php5-mysql php5-xsl

# Install PHP HttpRequest
RUN apt-get install -y libcurl4-openssl-dev make
RUN ln -s /usr/share/libtool/config/ltmain.sh /usr/share/libtool/ltmain.sh
RUN ln -s /usr/share/aclocal/libtool.m4 /usr/share/libtool/libtool.m4
RUN cd /usr/share/aclocal/ && cat lt~obsolete.m4 ltoptions.m4 ltsugar.m4 ltversion.m4 >> libtool.m4
RUN apt-get install -y libpcre3-dev build-essential libpng-dev libmcrypt-dev libmcrypt4 libmhash-dev \
    libmysqlclient-dev \
    libjpeg-dev \
    zlib1g-dev \
    libfreetype6-dev \
    libfontconfig1-dev

# Build module pecl_http
ADD tools/ /tmp
RUN cd /tmp && \
    tar xfz pecl_http-1.7.6.tgz && \
    cd pecl_http-1.7.6 && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    rm -rf /tmp/install
RUN echo "extension=http.so" > /etc/php5/conf.d/30_http.ini

ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

# install apache
RUN apt-get install -y apache2
RUN a2enmod rewrite
RUN a2enmod proxy
RUN a2enmod proxy_http
RUN a2enmod proxy_connect
RUN echo "umask 002" >> /etc/apache2/envvars

# PHP5.2 for apache
RUN echo "\nPackage: libapache2-mod-php5" >> /etc/apt/preferences.d/lenny
RUN echo "Pin: release n=lenny*" >> /etc/apt/preferences.d/lenny
RUN echo "Pin-Priority: 999" >> /etc/apt/preferences.d/lenny
RUN apt-get install -y libapache2-mod-php5

# Add user devel to group www-data
RUN usermod -a -G www-data devel

EXPOSE 80 22

ADD run.sh /run.sh
RUN chmod +x /run.sh
CMD ["/run.sh"]