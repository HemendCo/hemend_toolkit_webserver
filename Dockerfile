# Build stage

FROM ubuntu:latest AS builder
WORKDIR /build
COPY server /build/server
RUN chmod +x /build/server

# Runtime stage

FROM ubuntu:latest
WORKDIR /
COPY --from=builder /build/server /server
RUN chmod +x /server
CMD ["/server"]