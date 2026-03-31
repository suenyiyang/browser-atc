.PHONY: build bundle install clean run

build:
	swift build -c release

bundle: build
	bash scripts/bundle.sh

install: bundle
	mkdir -p ~/Applications
	rm -rf ~/Applications/BrowserATC.app
	cp -r build/BrowserATC.app ~/Applications/BrowserATC.app
	@echo "Installed to ~/Applications/BrowserATC.app"
	@echo "Open the app once, then set it as default browser in System Settings > Default Browser"

clean:
	rm -rf .build build

run: bundle
	open build/BrowserATC.app
