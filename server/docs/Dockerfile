FROM alpine:latest

ENV HUGO_VERSION 0.37
ENV HUGO_BINARY hugo_${HUGO_VERSION}_linux-64bit

RUN mkdir /usr/local/docs && mkdir /usr/local/hugo

ADD repositories /etc/apk/repositories
RUN apk update && \
    apk --no-cache upgrade && \
    apk --no-cache add bash openssh git py-pygments

ADD https://github.com/spf13/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY}.tar.gz /usr/local/hugo/
RUN tar xzf /usr/local/hugo/${HUGO_BINARY}.tar.gz -C /usr/local/hugo/ \
	&& ln -s /usr/local/hugo/hugo /usr/local/bin/hugo \
	&& rm /usr/local/hugo/${HUGO_BINARY}.tar.gz
    
WORKDIR /usr/local/docs
EXPOSE 1313
CMD ["tail", "-f", "/etc/apk/repositories"]
