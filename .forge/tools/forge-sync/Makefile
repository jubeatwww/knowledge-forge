.PHONY: build clean

BINARY_DIR = ../../bin
BINARY_NAME = forge-sync

build:
	go build -o $(BINARY_DIR)/$(BINARY_NAME).exe .

build-linux:
	GOOS=linux GOARCH=amd64 go build -o $(BINARY_DIR)/$(BINARY_NAME)-linux .

build-mac:
	GOOS=darwin GOARCH=arm64 go build -o $(BINARY_DIR)/$(BINARY_NAME)-mac .

build-all: build build-linux build-mac

clean:
	rm -f $(BINARY_DIR)/$(BINARY_NAME)*