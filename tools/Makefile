include ../common.mk

RUBY = rpfmt color-test rpfmt-old

install: $(RUBY)
	mkdir -m 2750 -p $(TOOLSDIR)
	cp -p --update $(RUBY) $(TOOLSDIR)
	chgrp -R staff $(TOOLSDIR)
	chmod 0750 $(TOOLSDIR)/*

.PHONY: uninstall
uninstall:
	cd $(TOOLSDIR) && \rm -f *
	\rmdir $(TOOLSDIR)

.PHONY: clean
clean:
	rm -f *~
