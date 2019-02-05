FROM ubuntu:16.04
ENTRYPOINT [ "/bin/bash", "-l", "-i", "-c" ]

# a few minor docker-specific tweaks
# see https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap
RUN set -xe \
    \
# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L40-L48
    && echo '#!/bin/sh' > /usr/sbin/policy-rc.d \
    && echo 'exit 101' >> /usr/sbin/policy-rc.d \
    && chmod +x /usr/sbin/policy-rc.d \
    \
# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L54-L56
    && dpkg-divert --local --rename --add /sbin/initctl \
    && cp -a /usr/sbin/policy-rc.d /sbin/initctl \
    && sed -i 's/^exit.*/exit 0/' /sbin/initctl \
    \
# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L71-L78
    && echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup \
    \
# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L85-L105
    && echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean \
    && echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean \
    && echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean \
    \
# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L109-L115
    && echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages \
    \
# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L118-L130
    && echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes \
    \
# https://github.com/docker/docker/blob/9a9fc01af8fb5d98b8eec0740716226fadb3735c/contrib/mkimage/debootstrap#L134-L151
    && echo 'Apt::AutoRemove::SuggestsImportant "false";' > /etc/apt/apt.conf.d/docker-autoremove-suggests

# delete all the apt list files since they're big and get stale quickly
RUN rm -rf /var/lib/apt/lists/*
# this forces "apt-get update" in dependent images, which is also good
# (see also https://bugs.launchpad.net/cloud-images/+bug/1699913)

# enable the universe
RUN sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list

# make systemd-detect-virt return "docker"
# See: https://github.com/systemd/systemd/blob/aa0c34279ee40bce2f9681b496922dedbadfca19/src/basic/virt.c#L434
RUN mkdir -p /run/systemd && echo 'docker' > /run/systemd/container

# Python installation
RUN apt-get update
RUN apt-get update --fix-missing
RUN apt-get install -y software-properties-common vim
RUN add-apt-repository ppa:jonathonf/python-3.5
RUN apt-get update
RUN export PATH
RUN apt-get install -y build-essential python3.5 python3.5-dev python3-pip python-pip
RUN apt-get install -y git
RUN apt-get update
RUN pip3 install --upgrade pip
RUN pip3 install -U tensorflow
RUN apt-get update
RUN pip3 install --no-cache-dir numpy scipy pandas matplotlib
RUN pip3 install neo4j-driver

# NLTK
RUN pip3 install nltk
RUN python3 -c "import nltk; nltk.download('stopwords')"
RUN cp -r /root/nltk_data /usr/share/nltk_data

# Set python 3.5 as the default for the container
RUN unlink /usr/bin/python
RUN ln -s /usr/bin/python3.5 /usr/bin/python

RUN apt-get install bc

# Set root password
RUN echo "root:##rmarkbio%%" | chpasswd

# Install sudo
RUN apt-get update && apt-get -y install sudo

# overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]

# Create and boot into a development user instead of working as root
RUN groupadd -r rmarkbio -g 901
RUN useradd -u 901 -r -g rmarkbio rmarkbio
RUN echo "rmarkbio:##rmarkbio%%" | chpasswd
RUN adduser rmarkbio sudo
RUN mkdir /home/rmarkbio
RUN mkdir /home/rmarkbio/project
RUN mkdir /home/rmarkbio/logs
RUN chown -R rmarkbio /home/rmarkbio
USER rmarkbio
WORKDIR /home/rmarkbio/project


