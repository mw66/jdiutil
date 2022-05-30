build:
	dub build

clean:
	cd rslib && make clean
	dub clean

init-rslib:
	cargo new rslib --lib

