# aws-quickwork-2api —— 多阶段构建
# 原作者没有提供 Dockerfile,这里补一个(只是打包,不改它的代码)
FROM golang:1.26-bookworm AS builder

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download

COPY . .
# CGO 关掉:纯 Go 项目,静态二进制更好搬
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/quickproxy ./cmd/quickproxy

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /out/quickproxy /app/quickproxy
COPY config.json /app/config.json
RUN mkdir -p /app/data
# 配置里 addr 是 127.0.0.1:8080,容器内要监听 0.0.0.0 才能被宿主机访问 —— 用 env 覆盖不了,
# 所以进容器后由 compose 挂一个改好的 config.json。
EXPOSE 8080
ENTRYPOINT ["/app/quickproxy"]
CMD ["server", "--config", "/app/config.json"]
