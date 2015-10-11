FROM centos:centos6.7

MAINTAINER j3l11234

# -----------------------------------------------------------------------------
# Base Install
# -----------------------------------------------------------------------------

RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN rpm -ivh http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm
RUN yum install -y \
	lrzsz \
	nginx \
	openssh-server \
	sudo \
	supervisor \
	wget \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

# -----------------------------------------------------------------------------
# ssh
# -----------------------------------------------------------------------------

ADD etc/ssh/sshd_config /etc/ssh/
ADD ssh-bootstrap /ssh-bootstrap
RUN rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_rsa_key \
    && ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_ecdsa_key \
    && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key \
    && chmod 600 /etc/ssh/sshd_config \
    && chmod +x /ssh-bootstrap

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
ADD etc/supervisord.conf /etc/
RUN mkdir -p /var/log/supervisor

# -----------------------------------------------------------------------------
# nginx
# -----------------------------------------------------------------------------
ADD etc/nginx/nginx.conf /etc/nginx/
ADD etc/nginx/conf.d/bjtu.conf /etc/nginx/conf.d/

# -----------------------------------------------------------------------------
# Purge
# -----------------------------------------------------------------------------
RUN rm -rf /etc/ld.so.cache \ 
	; rm -rf /sbin/sln \
	; rm -rf /usr/{{lib,share}/locale,share/{man,doc,info,gnome/help,cracklib,il8n},{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive} \
	; rm -rf /var/cache/{ldconfig,yum}/*

ENV AUTHORIZED_KEYS **None**
ENV ROOT_PASS nimda

EXPOSE 22
EXPOSE 80

CMD ["/usr/bin/supervisord"]