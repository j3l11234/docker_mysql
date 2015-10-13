FROM centos:centos6.7

MAINTAINER j3l11234

# -----------------------------------------------------------------------------
# Base Install
# -----------------------------------------------------------------------------
RUN yum -y install epel-release
RUN yum install -y \
	lrzsz \
	pwgen \
	sudo \
	wget


# -----------------------------------------------------------------------------
# SSH
# -----------------------------------------------------------------------------
RUN yum -y install openssh-server
ADD etc/ssh/sshd_config /etc/ssh/
ADD setup_ssh.sh /setup_ssh.sh
RUN rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_rsa_key \
    && ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_ecdsa_key \
    && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key \
    && chmod 600 /etc/ssh/sshd_config


# -----------------------------------------------------------------------------
# UTC Timezone
# -----------------------------------------------------------------------------
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime


# -----------------------------------------------------------------------------
# Enable the wheel sudoers group
# -----------------------------------------------------------------------------
RUN sed -i 's/^# %wheel\tALL=(ALL)\tALL/%wheel\tALL=(ALL)\tALL/g' /etc/sudoers


# -----------------------------------------------------------------------------
# supervisor
# -----------------------------------------------------------------------------
RUN yum install -y supervisor
ADD etc/supervisord.conf /etc/
RUN mkdir -p /var/log/supervisor


# -----------------------------------------------------------------------------
# MySql
# -----------------------------------------------------------------------------

RUN yum install -y libaio numactl perl perl-DBI perl-Module-Pluggable perl-Pod-Escapes perl-Pod-Simple perl-libs perl-version
RUN rpm -ivh http://dl.j3l11234.com/mysql-community-common-5.6.27-2.el6.x86_64.rpm \
    && rpm -ivh http://dl.j3l11234.com/mysql-community-libs-5.6.27-2.el6.x86_64.rpm \
    && rpm -ivh http://dl.j3l11234.com/mysql-community-client-5.6.27-2.el6.x86_64.rpm \
    && rpm -ivh http://dl.j3l11234.com/mysql-community-server-5.6.27-2.el6.x86_64.rpm

#RUN rpm -ivh http://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm
#RUN yum install -y mysql-community-server

ADD etc/my.cnf /etc/
ADD setup_mysql.sh /setup_mysql.sh


# -----------------------------------------------------------------------------
# Purge
# -----------------------------------------------------------------------------
RUN yum clean all \
	&& rm -rf /etc/ld.so.cache \ 
	&& rm -rf /usr/{{lib,share}/locale,share/{man,doc,info,gnome/help,cracklib,il8n},{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive} \
	&& rm -rf /var/cache/{ldconfig,yum}/*

ADD run.sh /run.sh
RUN chmod +x /*.sh

ENV AUTHORIZED_KEYS **None**
ENV ROOT_PASS nimda

ENV MYSQL_USER=admin \
    MYSQL_PASS=**Random** \
    ON_CREATE_DB=**False** 

EXPOSE 22
EXPOSE 3306

VOLUME  ["/data"]
CMD ["/run.sh"]
