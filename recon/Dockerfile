FROM golang:1.23-alpine

# Install required packages (docker CLI for exec into tool containers)
RUN apk add --no-cache git gcc musl-dev docker-cli

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN mkdir -p /app/temp
RUN chmod -R 777 /app/temp

RUN go build -o recon-engine .

EXPOSE 8443

CMD ["./recon-engine"]
