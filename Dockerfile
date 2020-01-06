FROM debian:jessie

LABEL maintainer="agitoktay@gmail.com"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --fix-missing \ 
    && apt-get -y install curl net-tools


ARG DOWNLOAD_URL=https://downloadsapachefriends.global.ssl.fastly.net/7.4.1/xampp-linux-x64-7.4.1-0-installer.run

RUN curl -o xampp.run $DOWNLOAD_URL \
    && chmod +x xampp.run \ 
    && bash -c './xampp.run' \
    && ln -sf /opt/lampp/lampp /usr/bin/lampp

# Enable XAMPP web interface(remove security checks)
# Enable includes of several configuration files

RUN sed -i.bak s'/Require local/Require all granted/g' /opt/lampp/etc/extra/httpd-xampp.conf \
    && mkdir /opt/lampp/apache2/conf.d \
    && echo "IncludeOptional /opt/lampp/apache2/conf.d/*.conf" >> /opt/lampp/etc/httpd.conf


# Create a /www folder and a symbolic link to it in /opt/lampp/htdocs. It'll be accessible via http://localhost:[port]/www/
# This is convenient because it doesn't interfere with xampp, phpmyadmin or other tools in /opt/lampp/htdocs
RUN mkdir /www && ln -s /www /opt/lampp/htdocs/
# RUN ln -s /www /opt/lampp/htdocs/

# SSH server
RUN apt-get install -y -q supervisor openssh-server \
    && mkdir -p /var/run/sshd

# Output supervisor config file to start openssh-server
RUN echo "[program:openssh-server]" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf \
    && echo "command=/usr/sbin/sshd -D" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf  \
    && echo "numprocs=1" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf  \
    && echo "autostart=true" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf  \
    && echo "autorestart=true" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf 


# Allow root login via password
# root password is: root
RUN sed -ri 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# Set root password
# password hash generated using this command: openssl passwd -1 -salt xampp root
RUN sed -ri 's/root\:\*/root\:\$1\$xampp\$5\/7SXMYAMmS68bAy94B5f\./g' /etc/shadow

# Few handy utilities which are nice to have
# RUN apt-get -y install nano vim less --no-install-recommends \
#     && apt-get clean

VOLUME [ "/var/log/mysql/", "/var/log/apache2/" ]

# Write a startup script
RUN echo '/opt/lampp/lampp start' >> /startup.sh
RUN echo '/usr/bin/supervisord -n' >> /startup.sh

CMD ["sh", "/startup.sh"]
