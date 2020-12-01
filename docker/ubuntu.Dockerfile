FROM ubuntu:focal AS builder
RUN apt-get -q --no-allow-insecure-repositories update \
  && DEBIAN_FRONTEND=noninteractive \
     apt-get install --assume-yes --no-install-recommends \
       ca-certificates curl make zip

WORKDIR /app
COPY . /app
RUN make archives


FROM pandoc/ubuntu-latex:2.10.1

RUN apt-get -q --no-allow-insecure-repositories update \
  && DEBIAN_FRONTEND=noninteractive \
     apt-get install --assume-yes --no-install-recommends make \
  && rm -rf /var/lib/apt/lists/* \
  && tlmgr install preprint

COPY --from=builder /app/dist/pandoc-scholar /opt/pandoc-scholar

ENV PANDOC_SCHOLAR_PATH=/opt/pandoc-scholar

ENTRYPOINT ["/usr/bin/make"]
