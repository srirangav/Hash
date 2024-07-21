# Makefile for Hash

# project settings

PROJNAME   = Hash
PROJEXT    = app
PROJVERS   = 1.3.2
BUNDLEID   = "org.calalum.ranga.$(PROJNAME)"

# Help bundle directory

HELP_EN_DIR = Docs/Hash.help/Contents/Resources/en.lproj/

# Help index file

HELP_INDEX = help.helpindex

# extra files to include in the package

SUPPORT_FILES = Docs/README.txt Docs/LICENSE.txt

# code signing information

include ../sign.mk

# build and packaging tools

XCODEBUILD = /usr/bin/xcodebuild
XCRUN      = /usr/bin/xcrun
HIUTIL     = /usr/bin/hiutil
ALTOOL     = $(XCRUN) altool
NOTARYTOOL = xcrun notarytool
STAPLER    = $(XCRUN) stapler
HDIUTIL    = /usr/bin/hdiutil
CODESIGN   = /usr/bin/codesign
STRIP      = /usr/bin/strip
GPG        = /opt/local/bin/gpg

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

# strip arguments

STRIP_ARGS = -rSTx

# build results directory

BUILD_RESULTS_DIR = build/Release/$(PROJNAME).$(PROJEXT)
BUILD_RESULTS_APP = $(BUILD_RESULTS_DIR)/Contents/MacOS/$(PROJNAME)
BUILD_RESULTS_FRAMEWORKS_DIR = $(BUILD_RESULTS_DIR)/Contents/Frameworks/

# build the app

all: helpindex release release_strip

# generate / update the helpindex

helpindex:
	cd $(HELP_EN_DIR) && $(HIUTIL) -Caf ./$(HELP_INDEX) .

# build a release version of the project

release:
	$(XCODEBUILD) -project $(PROJNAME).xcodeproj -configuration Release

# strip the main binary
# based on: https://www.emergetools.com/blog/posts/how-xcode14-unintentionally-increases-app-size
# TODO: strip frameworks

release_strip:
	$(STRIP) $(STRIP_ARGS) $(BUILD_RESULTS_APP)

# sign the app

sign: sign_frameworks
	$(CODESIGN) $(CODESIGN_ARGS) $(BUILD_RESULTS_DIR)

# sign any included frameworks (not always needed)

sign_frameworks: all
	if [ -d $(BUILD_RESULTS_FRAMEWORKS_DIR) ] ; then \
        $(CODESIGN) $(CODESIGN_ARGS) \
                    $(BUILD_RESULTS_FRAMEWORKS_DIR) ; \
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

# Xcode13 notarization
# See: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow?preferredLanguage=occ
#      https://scriptingosx.com/2021/07/notarize-a-command-line-tool-with-notarytool/
#      https://indiespark.top/programming/new-xcode-13-notarization/
#      https://developer.apple.com/documentation/technotes/tn3147-migrating-to-the-latest-notarization-tool

notarize: sign_dmg
	$(NOTARYTOOL) submit $(PROJNAME)-$(PROJVERS).dmg \
                  --apple-id $(USERID) --team-id $(TEAMID) \
                  --wait

# Pre-Xcode13 notarization

notarize_old: sign_dmg
	$(ALTOOL) --notarize-app \
              --primary-bundle-id $(BUNDLEID) \
              --username $(USERID) \
              --file $(PROJNAME)-$(PROJVERS).dmg

# staple the ticket to the dmg

staple: notarize
	$(STAPLER) staple $(PROJNAME)-$(PROJVERS).dmg
	$(STAPLER) validate $(PROJNAME)-$(PROJVERS).dmg

# sign the dmg with a gpg public key

clearsign: staple
	$(GPG) -asb $(PROJNAME)-$(PROJVERS).dmg

clean:
	/bin/rm -rf ./build \
                $(PROJNAME)-$(PROJVERS) \
                $(PROJNAME)-$(PROJVERS).dmg \
                $(PROJNAME)-$(PROJVERS).dmg.asc \
                $(HELP_EN_DIR)/$(HELP_INDEX)
	$(XCODEBUILD) -project $(PROJNAME).xcodeproj -alltargets clean

