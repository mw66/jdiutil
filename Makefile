build:
	make clean
	dub test
	make clean
	dub build

clean:
	dub clean


