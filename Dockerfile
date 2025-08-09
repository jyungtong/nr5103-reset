FROM alpine:latest

RUN apk add --no-cache curl jq tzdata moreutils

WORKDIR /app

COPY main.sh .

RUN chmod +x main.sh

CMD ["./main.sh"]
