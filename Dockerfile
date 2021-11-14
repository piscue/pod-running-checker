FROM alpine:3.14

RUN apk add --update --no-cache \
		curl \
		jq

ADD run.sh /run.sh
ENTRYPOINT ["/run.sh"]

