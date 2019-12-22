include ../common.mk

RUBY = conf.rb requirer.rb version.rb

app     = app
client  = client
#setting_files = setting_files
key     = key
utility = utility
uri     = utility/uri

APPDIR    = $(LIBDIR)/$(app)
CLIENTDIR = $(LIBDIR)/$(client)
KEYDIR    = $(LIBDIR)/$(keydir)
UTILDIR   = $(LIBDIR)/$(utility)

install: $(RUBY)
	mkdir -m 2750 -p $(LIBDIR)
	cp -p --update $(RUBY) $(LIBDIR)
	chmod 0640 $(LIBDIR)/*.rb
	chmod 0640 $(LIBDIR)/conf.rb
	chgrp -R staff $(LIBDIR)
	cd $(app)     && $(MAKE) install
	cd $(client)  && $(MAKE) install
	cd $(key)     && $(MAKE) install
	cd $(utility) && $(MAKE) install

.PHONY:
uninstall:
	cd $(app)     && $(MAKE) uninstall
	cd $(client)  && $(MAKE) uninstall
	cd $(key)     && $(MAKE) uninstall
	cd $(utility) && $(MAKE) uninstall
	cd $(LIBDIR) && \rm -f $(RUBY)
	\rmdir $(LIBDIR)

.PHONY: clean
clean:
	rm -f *~
	cd $(app)     && $(MAKE) clean
	cd $(client)  && $(MAKE) clean
	cd $(key)     && $(MAKE) clean
	cd $(utility) && $(MAKE) clean
