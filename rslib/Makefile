rslib.h:
	cbindgen --config cbindgen.toml --crate rslib --output $@
	# dstep $@ -o $*.d

build:
	cargo build

clean:
	$(RM) -f rslib.h
	cargo clean

