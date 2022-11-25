FROM debian

RUN apt update -y && \
    apt install -y golang git

RUN mkdir /app

WORKDIR /app

RUN git clone https://github.com/fg33140/GroupieTracker.git

WORKDIR /app/GroupieTracker

CMD [ "go", "run", "main.go" ]
