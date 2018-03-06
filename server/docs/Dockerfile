FROM alpine:latest

RUN mkdir /usr/local/docs

ADD repositories /etc/apk/repositories
RUN apk update && \
    apk --no-cache upgrade && \
    apk --no-cache add bash openssh hugo git

WORKDIR /usr/local/docs
EXPOSE 1313
CMD ["tail", "-f", "/etc/apk/repositories"]
