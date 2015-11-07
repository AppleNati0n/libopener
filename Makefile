TARGET = iphone:clang:latest:5.0

APPLEDOCFILES = $(wildcard *.h) $(wildcard prefs/*.h)
DOCS_STAGING_DIR = _docs
DOCS_OUTPUT_PATH = docs

include $(THEOS)/makefiles/common.mk

FRAMEWORK_NAME = Opener
Opener_FILES = $(wildcard *.x) $(wildcard *.m)
Opener_PUBLIC_HEADERS = HBLibOpener.h HBLOHandler.h HBLOHandlerDelegate.h
Opener_FRAMEWORKS = MobileCoreServices UIKit
Opener_PRIVATE_FRAMEWORKS = AppSupport
Opener_EXTRA_FRAMEWORKS = Cephei
Opener_LIBRARIES = rocketbootstrap substrate
Opener_CFLAGS = -include Global.h

SUBPROJECTS = prefs

include $(THEOS_MAKE_PATH)/framework.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-Opener-all::
	# create directories
	mkdir -p $(THEOS_OBJ_DIR)/Opener.framework/Headers

	# copy headers
	rsync -ra $(Opener_PUBLIC_HEADERS) $(THEOS_OBJ_DIR)/Opener.framework/Headers

	# copy to theos lib dir
	rsync -ra $(THEOS_OBJ_DIR)/Opener.framework $(THEOS)/lib

after-Opener-stage::
	# create directories
	mkdir -p $(THEOS_STAGING_DIR)/usr/{include,lib}

	# libopener.dylib -> Opener.framework
	ln -s /Library/Frameworks/Opener.framework/Opener $(THEOS_STAGING_DIR)/usr/lib/libopener.dylib

	# Opener -> Opener.framework/Headers
	ln -s /Library/Frameworks/Opener.framework/Headers $(THEOS_STAGING_DIR)/usr/include/Opener

	# Opener -> libopener.dylib
	mkdir -p $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries
	ln -s /Library/Frameworks/Opener.framework/Opener $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.dylib
	cp libopener.plist $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/libopener.plist

after-install::
ifeq ($(RESPRING),0)
	install.exec "killall Preferences; sleep 0.2; sbopenurl 'prefs:root=Opener'"
else
	install.exec spring
endif

docs::
	# eventually, this should probably be in theos.
	# for now, this is good enough :p

	[[ -d "$(DOCS_STAGING_DIR)" ]] && rm -r "$(DOCS_STAGING_DIR)" || true

	-appledoc --project-name opener --project-company "HASHBANG Productions" --company-id ws.hbang --project-version 1.2 --no-install-docset \
		--keep-intermediate-files --create-html --publish-docset --docset-feed-url "https://hbang.github.io/libopener/xcode-docset.atom" \
		--docset-atom-filename xcode-docset.atom --docset-package-url "https://hbang.github.io/libopener/docset.xar" \
		--docset-package-filename docset --docset-fallback-url "https://hbang.github.io/libopener/" --docset-feed-name opener \
		--index-desc README.md --no-repeat-first-par \
		--output "$(DOCS_STAGING_DIR)" $(APPLEDOCFILES)

	[[ -d "$(DOCS_OUTPUT_PATH)" ]] || git clone -b gh-pages git@github.com:hbang/libopener.git "$(DOCS_OUTPUT_PATH)"
	rsync -ra "$(DOCS_STAGING_DIR)"/{html,publish}/ "$(DOCS_OUTPUT_PATH)"
	rm -r "$(DOCS_STAGING_DIR)"
