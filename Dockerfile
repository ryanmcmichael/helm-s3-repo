FROM ubuntu:latest

#RUN apk --no-cache add git
RUN sudo apt install git

COPY src/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
