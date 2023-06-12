FROM alpine:latest

USER root

COPY server /usr/local/bin/
RUN chmod a+x /usr/local/bin/server
CMD ["server"]