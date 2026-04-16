FROM azul/zulu-openjdk-alpine:11 AS base

LABEL maintainer="boyland@uwm.edu"
LABEL version="1.0.0"

ARG SCALA_VERSION="2.13.16"
ARG BISON_VERSION="3.8.2"
ARG SCALA_BISON_JAR_URL="https://github.com/boyland/scala-bison/releases/download/v1.2/scala-bison-2.13.jar"

WORKDIR /usr/lib

RUN apk add --no-cache bash make gcompat build-base m4 perl flex \
  && apk add --no-cache --virtual=build-dependencies wget ca-certificates

RUN wget -q "https://github.com/scala/scala/releases/download/v${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz" -O - | gunzip | tar x

ENV SCALAHOME="/usr/lib/scala-$SCALA_VERSION"
ENV PATH="$SCALAHOME/bin:$PATH"

RUN wget -q "https://ftp.gnu.org/gnu/bison/bison-${BISON_VERSION}.tar.gz" -O - | gunzip | tar x \
  && cd "bison-${BISON_VERSION}" \
  && ./configure \
  && make \
  && make install

WORKDIR /usr/local
COPY . .
RUN chmod +x cmd/*
ENV PATH="/usr/local/cmd:$PATH"

RUN wget -q "${SCALA_BISON_JAR_URL}" -O scala-bison.jar \
  && make boot \
  && make compile \
  && make \
  && make boot \
  && make compile \
  && make \
  && mkdir -p lib \
  && cp scala-bison.jar lib/scala-bison-2.13.jar

WORKDIR /usr/local/examples
RUN scala-bison Calc && \
    scalac CalcParserBase.scala CalcScanner.scala CalcParser.scala CalcTokens.scala Calc.scala && \
    echo "scala-bison Calc test passed"

WORKDIR /root
