FROM ubuntu:20.04
MAINTAINER rharter

# Set correct environment variables
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Configure user nobody to match unRAID's settings
RUN \
  usermod -u 99 nobody && \
  usermod -g 100 nobody && \
  usermod -d /home nobody && \
  chown -R nobody:users /home

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Install software
RUN \
  apt-get update && \
  apt-get install -y software-properties-common && \
  \
  add-apt-repository -y ppa:stebbins/handbrake-releases && \
  apt-get install -y handbrake-cli libdvd-pkg && \
  dpkg-reconfigure libdvd-pkg && \
  \
  add-apt-repository -y ppa:heyarje/makemkv-beta && \
  apt-get install -y makemkv-bin makemkv-oss
 
# Move Files
COPY root/ /
RUN chmod +x /etc/my_init.d/*.sh
