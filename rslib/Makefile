
LIBRUST_INTEROP_D = librust_interop.d

librust_interop.h:
	cbindgen --lang C --cpp-compat --config cbindgen.toml --crate rslib --output $@
	dstep $@ -o $*.d

build:
	cargo build
	make librust_interop.h

clean:
	$(RM) -f librust_interop.h $(LIBRUST_INTEROP_D)
	cargo clean

