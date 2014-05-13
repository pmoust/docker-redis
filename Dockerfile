#########################################################################
#
# A container holding Redis
#
#########################################################################

FROM centos

MAINTAINER Panagiotis Moustafellos <pmoust@gmail.com>

# Addind epel (trusted)
RUN rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm

# Install Redis + OpenSSH server + PIP + Tools 
RUN yum install -y 	redis openssh-server python-pip \
		   	htop mtr vim nmap telnet tcpdump

# Keeping container updated with latest security patches
RUN yum install -y yum-security
RUN yum list-security
RUN yum update -y --security

# Install supervisor
RUN pip install pip --upgrade
RUN pip install supervisor
ADD containerconfig/supervisord.conf /etc/supervisord.conf
RUN mkdir /var/log/supervisor

# Let Supervisor daemonize Redis and set overautocommit for memory issues
RUN sed -ri "s/bind/#bind/g" /etc/redis.conf
RUN sed -ri "s/daemonize yes/daemonize no/g" /etc/redis.conf
RUN touch /var/log/redis/redis.log
RUN chown redis /var/log/redis/redis.log
RUN echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf

########################################################################
#       CONFIGURE SSHD inside the container - useful for debugging
########################################################################
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key 
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN sed -ri "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
#RUN echo 'AuthorizedKeysFile	.ssh/authorized_keys' 	>> /etc/ssh/sshd_config
RUN echo 'PermitRootLogin	yes'			>> /etc/ssh/sshd_config
RUN echo 'root:changeme' | chpasswd
# Prepare a .ssh directory so we can optionally add our private key to the host and avoid needing a password to ssh into the container as root
RUN mkdir -p /root/.ssh


########################################################################
#             Expose a Port for each service in this container
########################################################################
EXPOSE 6379 22

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

########################################################################
#                             END
########################################################################
