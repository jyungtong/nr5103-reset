FROM alpine:latest

RUN apk add --no-cache curl jq

WORKDIR /app

COPY main.sh .

RUN chmod +x main.sh

CMD ["./main.sh"]
