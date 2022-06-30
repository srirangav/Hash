# Makefile for Hash

# project settings

PROJNAME   = Hash
PROJEXT    = app
PROJVERS   = 1.1.23
BUNDLEID   = "org.calalum.ranga.$(PROJNAME)"

# Help bundle directory

HELP_EN_DIR = Docs/Hash.help/Contents/Resources/en.lproj/

# Help index file

HELP_INDEX = help.helpindex

# extra files to include in the package

SUPPORT_FILES = Docs/README.txt Docs/LICENSE.txt

# code signing information

include sign.mk

# build and packaging tools

XCODEBUILD = /usr/bin/xcodebuild
XCRUN      = /usr/bin/xcrun
HIUTIL     = /usr/bin/hiutil
ALTOOL     = $(XCRUN) altool
STAPLER    = $(XCRUN) stapler
HDIUTIL    = /usr/bin/hdiutil
CODESIGN   = /usr/bin/codesign

# code sign arguments
# based on:
# https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow
# https://stackoverflow.com/questions/53112078/how-to-upload-dmg-file-for-notarization-in-xcode

CODESIGN_ARGS = --force \
                --verify \
                --verbose \
                --timestamp \
                --options runtime \
                --sign $(SIGNID)

# build results directory

BUILD_RESULTS_DIR = build/Release/$(PROJNAME).$(PROJEXT)

# build the app

all: helpindex
	$(XCODEBUILD) -project $(PROJNAME).xcodeproj -configuration Release

# sign the app, if frameworks are included, then sign_frameworks should
# be the pre-requisite target instead of "all" 

sign: sign_frameworks
	$(CODESIGN) $(CODESIGN_ARGS) $(BUILD_RESULTS_DIR)

# sign any included frameworks (not always needed)

sign_frameworks: all
	if [ -d $(BUILD_RESULTS_DIR)/Contents/Frameworks/ ] ; then \
        $(CODESIGN) $(CODESIGN_ARGS) \
                    $(BUILD_RESULTS_DIR)/Contents/Frameworks/* ; \
    fi

# sign the disk image

sign_dmg: dmg
	$(CODESIGN) $(CODESIGN_ARGS) $(PROJNAME)-$(PROJVERS).dmg

# create a disk image with the signed app

dmg: clean all sign
	/bin/mkdir $(PROJNAME)-$(PROJVERS)
	/bin/mv $(BUILD_RESULTS_DIR) $(PROJNAME)-$(PROJVERS)
	/bin/cp $(SUPPORT_FILES) $(PROJNAME)-$(PROJVERS)
	$(HDIUTIL) create -srcfolder $(PROJNAME)-$(PROJVERS) \
                      -format UDBZ $(PROJNAME)-$(PROJVERS).dmg

# notarize the signed disk image

notarize: sign_dmg
	$(ALTOOL) --notarize-app \
              --primary-bundle-id $(BUNDLEID) \
              --username $(USERID) \
              --file $(PROJNAME)-$(PROJVERS).dmg

# staple the ticket to the dmg, but notarize needs to complete first,
# so we can't list notarize as a pre-requisite target

staple: 
	$(STAPLER) staple $(PROJNAME)-$(PROJVERS).dmg
	$(STAPLER) validate $(PROJNAME)-$(PROJVERS).dmg

# generate / update the helpindex

helpindex:
	cd $(HELP_EN_DIR) && $(HIUTIL) -Caf ./$(HELP_INDEX) .
    
clean:
	/bin/rm -rf ./build \
                $(PROJNAME)-$(PROJVERS) \
                $(PROJNAME)-$(PROJVERS).dmg \
                $(PROJNAME)-$(PROJVERS).dmg.asc \
                $(HELP_EN_DIR)/$(HELP_INDEX)
	$(XCODEBUILD) -project $(PROJNAME).xcodeproj -alltargets clean

