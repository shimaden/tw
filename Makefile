include common.mk

SHELL = /bin/sh

CONF_DIR = '/usr/local/etc/us'

.PHONY: install
install:
	cd bin         && $(MAKE) install
	#cd doc         && $(MAKE) install
	cd lib         && $(MAKE) install
	cd samples     && $(MAKE) install
	cd tools       && $(MAKE) install

.PHONY: uninstall
uninstall:
	cd bin         && $(MAKE) uninstall
	#cd doc         && $(MAKE) uninstall
	cd lib         && $(MAKE) uninstall
	cd samples     && $(MAKE) uninstall
	cd tools       && $(MAKE) uninstall

.PHONY: clean
clean:
	rm -f *~
	cd bin         && $(MAKE) clean
	#cd doc         && $(MAKE) clean
	cd lib         && $(MAKE) clean
	cd samples     && $(MAKE) clean
	cd tools       && $(MAKE) clean
