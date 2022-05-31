rslib.h:
	cbindgen --lang C --cpp-compat --config cbindgen.toml --crate rslib --output $@
	dstep $@ -o $*.d

build:
	cargo build

clean:
	$(RM) -f rslib.h rslib.d
	cargo clean

