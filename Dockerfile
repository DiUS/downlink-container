FROM ubuntu:trusty
MAINTAINER Kevin Littlejohn <kevin@littlejohn.id.au>
RUN apt-get -yq update && apt-get -yq upgrade \
  && apt-get -yq install autoconf bison build-essential libssl-dev libyaml-dev \
    libreadline6-dev zlib1g-dev libncurses5-dev curl git openssl \
    openssh-client openssh-server

# Ruby
WORKDIR /usr/local/src

RUN git clone https://github.com/sstephenson/ruby-build.git \
  && cd ruby-build \
  && ./install.sh
RUN /usr/local/bin/ruby-build 2.1.5 /usr/local/ruby
ENV GEM_HOME /usr/local/ruby/lib/ruby/gems/2.1.0
ENV GEM_PATH /usr/local/ruby/lib/ruby/gems/2.1.0
RUN /usr/local/ruby/bin/gem install bundler --no-ri --no-rdoc \
    && /usr/local/ruby/bin/bundle config --global jobs 4
RUN addgroup ruby \
  && chgrp -R ruby /usr/local/ruby \
  && chmod -R g+w /usr/local/ruby \
  && find /usr/local/ruby -type d -exec chmod g+s {} \;

RUN mkdir /var/run/sshd
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN echo '\nAllowUsers downlink\n' >> /etc/ssh/sshd_config
RUN echo '\nexport PATH=/usr/local/ruby/bin:$PATH\n' >> /etc/bash.bashrc

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

RUN useradd -m -s /usr/local/ruby/bin/dshell -G sudo downlink
RUN echo 'downlink:password' | chpasswd
RUN rm -f /etc/update-motd.d/*

ADD id_rsa /home/downlink/.ssh/id_rsa
ADD id_rsa.pub /home/downlink/.ssh/authorized_keys
RUN chown -R downlink.downlink /home/downlink/.ssh
RUN mkdir -p /var/downlink

ONBUILD ADD config.yml /etc/downlink/config.yml

RUN /usr/local/ruby/bin/gem install dshell -s https://repo.fury.io/silarsis/ -v 0.1.6
