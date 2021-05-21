FROM ubuntu:latest

#RUN apk --no-cache add git
RUN DEBIAN_FRONTEND="noninteractive" apt-get update && apt-get install -y git curl wget awscli

COPY src/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
