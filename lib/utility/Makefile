include ../../common.mk

RUBY = array_extension.rb boolean.rb cgi_escape.rb error_helper.rb \
	file_cacheable_array.rb force.rb locale_inspector.rb mash_extension.rb \
	not_nil.rb shell_escape_sequence.rb string_extension.rb utility.rb

utility = utility
webaccess = web-access
UTILDIR = $(LIBDIR)/$(utility)

install: $(RUBY)
	mkdir -m 2750 -p $(UTILDIR)
	cp -p --update $(RUBY) $(UTILDIR)
	chgrp -R staff $(UTILDIR)
	chmod 0640 $(UTILDIR)/*.rb
	make -C $(webaccess) install

.PHONY: uninstall
uninstall:
	cd $(UTILDIR) && \rm -f *
	\rmdir $(UTILDIR)
	make -C $(webaccess) uninstall

.PHONY: clean
clean:
	rm -f *~
	make -C $(webaccess) clean

