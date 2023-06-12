FROM alpine:latest

COPY server /usr/local/bin/

CMD ["server"]