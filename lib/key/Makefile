include ../../common.mk

RUBY   = us-keys.rb
key = key
KEYDIR = $(LIBDIR)/$(key)

install: $(RUBY)
	mkdir -m 2750 -p $(KEYDIR)
	cp -p --update $(RUBY) $(KEYDIR)
	chgrp -R staff $(KEYDIR)
	chmod 0640 $(KEYDIR)/*.rb

.PHONY: uninstall
uninstall:
	cd $(KEYDIR) && \rm -f *
	\rmdir $(KEYDIR)

.PHONY: clean
clean:
	rm -f *~
