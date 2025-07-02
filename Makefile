VERSION = $(shell cat VERSION)
LIBRARY_PREFIX = pam_watchid
LIBRARY_NAME = $(LIBRARY_PREFIX).so
DESTINATION = /usr/local/lib/pam
LIBRARY_PATH = $(DESTINATION)/$(LIBRARY_NAME).$(VERSION)
TARGET = apple-macosx10.15

all:
	swiftc Sources/pam-watchid/pam_watchid.swift -o $(LIBRARY_NAME) -target arm64-$(TARGET) -emit-library

install: all
	sudo mkdir -p $(DESTINATION)
	sudo install -o root -g wheel -m 444 $(LIBRARY_NAME) $(LIBRARY_PATH)

.PHONY: all install