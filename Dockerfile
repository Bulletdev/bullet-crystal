FROM crystallang/crystal:1.10.1-alpine AS build

WORKDIR /app

COPY shard.yml ./
RUN shards install --no-color
COPY src ./src
RUN mkdir -p bin && crystal build --release --no-debug src/app.cr -o bin/app

FROM alpine:3.18

RUN apk add --no-cache libc6-compat libgcc pcre2

WORKDIR /app

COPY --from=build /app/bin/app .

EXPOSE 4444

CMD ["./app"]