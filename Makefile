build:
	d++ --preprocess-only --parse-as-cpp --keep-pre-cpp-files --keep-d-files ./source/jdiutil/memory.dpp
	sed -i "s/class SharedCArrayI(T)/interface SharedCArrayI(T)/g" ./source/jdiutil/memory.d
	make clean
	dub test
	make clean
	dub build

clean:
	dub clean


