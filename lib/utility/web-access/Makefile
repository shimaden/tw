include ../../../common.mk

RUBY = twitter_scraper.rb

utility = utility
UTILDIR = $(LIBDIR)/$(utility)
WEBACCESSDIR = $(UTILDIR)/web-access

install: $(RUBY)
	mkdir -m 2750 -p $(WEBACCESSDIR)
	cp -p --update $(RUBY) $(WEBACCESSDIR)
	chgrp -R staff $(WEBACCESSDIR)
	chmod 0640 $(WEBACCESSDIR)/*.rb

.PHONY: uninstall
uninstall:
	cd $(WEBACCESSDIR) && \rm -f *
	\rmdir $(WEBACCESSDIR)

.PHONY: clean
clean:
	rm -f *~
