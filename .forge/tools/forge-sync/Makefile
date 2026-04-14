.PHONY: build build-linux build-mac build-windows build-all clean

BINARY_DIR = ../../bin
BINARY_NAME = forge-sync
LDFLAGS = -s -w

build:
	go build -trimpath -ldflags="$(LDFLAGS)" -o $(BINARY_DIR)/$(BINARY_NAME) .

build-linux:
	GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="$(LDFLAGS)" -o $(BINARY_DIR)/$(BINARY_NAME)-linux .

build-mac:
	GOOS=darwin GOARCH=arm64 go build -trimpath -ldflags="$(LDFLAGS)" -o $(BINARY_DIR)/$(BINARY_NAME)-mac .

build-windows:
	GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="$(LDFLAGS)" -o $(BINARY_DIR)/$(BINARY_NAME)-windows.exe .

build-all: build build-linux build-mac build-windows

clean:
	rm -f $(BINARY_DIR)/$(BINARY_NAME)*
