FROM ubuntu:latest

#RUN apk --no-cache add git
RUN apt-get update && apt-get install -y git

COPY src/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
