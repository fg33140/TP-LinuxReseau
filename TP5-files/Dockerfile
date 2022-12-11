FROM debian

RUN apt update -y && \
    apt install -y iproute2 iputils-ping ssh sudo openssh-server

RUN useradd -m user -s /bin/bash

RUN printf "root\nroot" | passwd user

RUN mkdir /var/run/sshd

RUN sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config

docker run

EXPOSE 22

CMD [ "/usr/sbin/sshd", "-D" ]