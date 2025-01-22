PREFIX ?= /usr/local
OPTDIR ?= /opt

BIN = mkplugin
BINDIR = $(PREFIX)/bin
DATDIR = $(OPTDIR)/$(BIN)

# all: build install

# sudo make install
install:
	mkdir -p $(DATDIR)

	cp ./$(BIN) $(BINDIR)/$(BIN)
	cp ./$(BIN).sh $(DATDIR)/$(BIN).sh

	chmod +x $(BINDIR)/$(BIN)
	chmod +x $(DATDIR)/$(BIN).sh

	echo "Done"

# sudo make uninstall
uninstall:
	rm $(BINDIR)/$(BIN)
	rm -rf $(DATDIR)