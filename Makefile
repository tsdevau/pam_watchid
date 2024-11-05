VERSION = 2
LIBRARY_PREFIX = pam_watchid
LIBRARY_NAME = $(LIBRARY_PREFIX).so
DESTINATION = /usr/local/lib/pam
TARGET = apple-darwin$(shell uname -r)
PAM_FILE_BASE = /etc/pam.d/sudo
PAM_TEXT = auth sufficient $(LIBRARY_NAME)
PAM_TID_TEXT = auth       sufficient     pam_tid.so

# Determine if the macOS Sequoia SDK or later is available.
DEFINES =
# Due to the different ways in which the CLT and Xcode structure their SDK paths, one of the following will always be an empty string depending on what is configured by xcode-select. 
CLT_SDK_MAJOR_VER = $(shell xcrun --sdk macosx --show-sdk-path | xargs realpath | xargs basename | sed 's/MacOSX//' | cut -d. -f1)
XCODE_SDK_MAJOR_VER = $(shell xcrun --sdk macosx --show-sdk-path | xargs basename | sed 's/MacOSX//' | cut -d. -f1)
SDK_REQUIRED_MAJOR_VER = 15
ifeq "$(SDK_REQUIRED_MAJOR_VER)" "$(word 1, $(sort $(SDK_REQUIRED_MAJOR_VER) $(XCODE_SDK_MAJOR_VER) $(CLT_SDK_MAJOR_VER)))"
	DEFINES += -DSEQUOIASDK
endif

all:
	swiftc watchid-pam-extension.swift $(DEFINES) -o $(LIBRARY_PREFIX)_x86_64.so -target x86_64-$(TARGET) -emit-library
	swiftc watchid-pam-extension.swift $(DEFINES) -o $(LIBRARY_PREFIX)_arm64.so -target arm64-$(TARGET) -emit-library
	lipo -create $(LIBRARY_PREFIX)_arm64.so $(LIBRARY_PREFIX)_x86_64.so -output $(LIBRARY_NAME)

install: all
	sudo mkdir -p $(DESTINATION)
	sudo install -o root -g wheel -m 444 $(LIBRARY_NAME) $(DESTINATION)/$(LIBRARY_NAME).$(VERSION)

enable: install
ifeq (,$(wildcard $(PAM_FILE_BASE)_local.template))
	$(eval PAM_FILE = $(PAM_FILE_BASE))
	grep $(LIBRARY_NAME) $(PAM_FILE) > /dev/null || sudo sed '2{h;s/.*/$(PAM_TEXT)/;p;g;}' $(PAM_FILE) | sudo tee $(PAM_FILE)
else
	$(eval PAM_FILE = $(PAM_FILE_BASE)_local)
	sudo sh -c '[[ "$(shell cat $(PAM_FILE).template)" != "$(shell cat $(PAM_FILE))" ]] && cat $(PAM_FILE).template >> $(PAM_FILE) || true'
	sudo sed -i ".old" -e '/$(PAM_TID_TEXT)/s/^#//g' $(PAM_FILE)
	sudo sh -c 'echo $(PAM_TEXT) >> $(PAM_FILE)'
endif
