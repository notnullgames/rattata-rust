NAME=rattata

.PHONY: help clean manager target ffi

help: ## show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

manager: ## run rattata manager
	cargo run --bin manager

runtime: ## run rattata target runtime
	cargo run --bin runtime

clean: ## delete all output files
	cargo clean

build: ## build runtime files for current system in target/release
	# whatever is local
	cargo build --bins --lib --release
	cbindgen . -o target/release/rattata.h --lang C

ffi: ## test lua ffi wrappers
	cargo build --lib
	LD_LIBRARY_PATH=target/debug/ luajit src/example.lua

# group release builder for posix systems
x86_64-unknown-linux-gnu x86_64-apple-darwin arm-unknown-linux-gnueabihf armv7-unknown-linux-gnueabihf &:
	cross build --bins --lib --release --target=$@
	cbindgen . -o target/$@/release/rattata.h --lang C
	cp src/*.lua target/$@/release/
	cd target/$@/release/ && zip $@.zip *.lua runtime manager librattata.so rattata.h && mv $@.zip ../../

# single release builder for windows
x86_64-pc-windows-gnu:
	cross build --bins --lib --release --target=$@
	cbindgen . -o target/$@/release/rattata.h --lang C
	cp src/*.lua target/$@/release/
	cd target/$@/release/ && zip $@.zip *.lua runtime.exe manager.exe librattata.dll rattata.h && mv $@.zip ../../

release: x86_64-unknown-linux-gnu x86_64-apple-darwin arm-unknown-linux-gnueabihf armv7-unknown-linux-gnueabihf x86_64-pc-windows-gnu ## build runtime files for all supported platforms in target/releases
