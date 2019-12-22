include ../common.mk

RUBY = us

install: $(RUBY)
	mkdir -m 2750 -p $(BINDIR)
	cp -p --update $(RUBY) $(BINDIR)
	chgrp -R staff $(BINDIR)
	chmod 0750 $(BINDIR)/us

.PHONY: uninstall
uninstall:
	cd $(BINDIR) && \rm -f $(RUBY)
	\rmdir $(BINDIR)

.PHONY: clean
clean:
	rm -f *~
