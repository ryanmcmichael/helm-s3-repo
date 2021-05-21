FROM ubuntu:18.04

#RUN apk --no-cache add git
RUN apt-get update && apt-get install -y git curl wget python3-pip
RUN pip install awscli

COPY src/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
