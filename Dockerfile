ARG ALPINE_VERSION=3.20

FROM golang:alpine${ALPINE_VERSION} AS builder

RUN apk update \
        && apk upgrade --no-cache \
        && apk add --no-cache git ca-certificates mailcap

WORKDIR /app

COPY . .

# The image should be built with
# --build-arg ST_VERSION=`git describe --tags --always`
ARG ST_VERSION
ARG GOPROXY=direct
RUN go get -a \
        && CGO_ENABLED=0 GOOS=linux go build \
        -ldflags "-s -w \
        -X main.Version=${ST_VERSION:-UNKNOWN_RELEASE}" \
        -a -o smtp_to_telegram

FROM alpine:${ALPINE_VERSION}

ENV ST_SMTP_LISTEN=0.0.0.0:2525

RUN apk update \
        && apk upgrade --no-cache \
        && apk add --no-cache ca-certificates mailcap

COPY --from=builder /app/smtp_to_telegram /smtp_to_telegram

USER daemon

EXPOSE 2525

ENTRYPOINT ["/smtp_to_telegram"]
