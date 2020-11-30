FROM alpine:3.12 AS builder
RUN apk --no-cache add ca-certificates curl make zip

WORKDIR /app
COPY . /app
RUN make archives


FROM pandoc/latex:2.11.2

RUN apk --no-cache add make \
  && tlmgr install preprint

COPY --from=builder /app/dist/pandoc-scholar /opt/pandoc-scholar

ENV PANDOC_SCHOLAR_PATH=/opt/pandoc-scholar

ENTRYPOINT ["/usr/bin/make"]
