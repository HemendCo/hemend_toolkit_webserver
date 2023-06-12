FROM alpine:latest

COPY hem_server /

CMD ["/hem_server"]