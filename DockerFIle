FROM alpine:latest

COPY hem_server /hem_server

CMD ["/hem_server"]