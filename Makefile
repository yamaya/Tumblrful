.PHONY: all release clean install uninstall

all:
	xcodebuild -activetarget -configuration Debug
	install_name_tool -change "@executable_path/../Frameworks/Growl.framework/Versions/A/Growl" "@loader_path/../Frameworks/Growl.framework/Versions/A/Growl" build/Debug/Tumblrful.bundle/Contents/MacOS/Tumblrful
	cp -r build/Debug/Tumblrful.bundle ~/Library/Application\ Support/SIMBL/Plugins/

release:
	xcodebuild -activetarget -configuration Release
	install_name_tool -change "@executable_path/../Frameworks/Growl.framework/Versions/A/Growl" "@loader_path/../Frameworks/Growl.framework/Versions/A/Growl" build/Release/Tumblrful.bundle/Contents/MacOS/Tumblrful
	cp -r build/Release/Tumblrful.bundle ~/Library/Application\ Support/SIMBL/Plugins/
	rm -f Release/Tumblrful.bundle.zip
	cd build/Release && zip -r Tumblrful.bundle.zip Tumblrful.bundle
	mv build/Release/Tumblrful.bundle.zip Release

clean:
	xcodebuild -alltargets -configuration Debug clean
	xcodebuild -alltargets -configuration Release clean
	rm -fr ./build

install:
	cp -r build/Debug/Tumblrful.bundle ~/Library/Application\ Support/SIMBL/Plugins/

uninstall:
	rm -fr ~/Library/Application\ Support/SIMBL/Plugins/Tumblrful.bundle
