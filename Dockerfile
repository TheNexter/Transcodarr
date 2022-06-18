FROM alpine:latest

RUN apk update --no-cache && apk add ffmpeg bash --no-cache
ADD transcodarr.sh /

ENTRYPOINT ["/transcodarr.sh"]
