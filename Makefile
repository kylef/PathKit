.PHONY = clean update build test bootstrap
PARAM = SWIFTPM_DEVELOPMENT=YES

clean:
	if [ -e Package.resolved ]; then rm Package.resolved; fi

test:
	$(PARAM) swift test

update: clean
	$(PARAM) swift package update

build:
	$(PARAM) swift build

bootstrap: build
	$(PARAM) swift package generate-xcodeproj

