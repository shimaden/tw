include ../../common.mk

#RUBY = executor.rb geo.data.rb geo.rb main.rb renderer.rb \
#	reply_formatter.rb tweet_text_colorizer.rb tweet_kind.rb mention_formatter.rb
RUBY = abstract_executor.rb executor.rb executor_exit_code.rb file_saver.rb \
	geo.data.rb geo.rb geo_data_loader.rb main.rb mention_formatter.rb \
	renderer.rb reply_formatter.rb tweet_text_colorizer.rb
TEXT = help.txt

app      = app
executor = executor
APPDIR      = $(LIBDIR)/$(app)

install: $(RUBY) $(TEXT)
	mkdir -m 2750 -p $(APPDIR)
	cp -p --update $(RUBY) $(APPDIR)
	cp -p --update $(TEXT) $(APPDIR)
	chgrp -R staff $(APPDIR)
	chmod 0640 $(APPDIR)/*.rb
	chmod 0640 $(APPDIR)/*.txt
	chmod 0640 $(APPDIR)/geo.rb
	cd $(executor) && $(MAKE) install

.PHONY: uninstall
uninstall:
	cd $(APPDIR) && \rm -f *.rb *.txt
	\rmdir $(APPDIR)
	cd $(executor) && $(MAKE) uninstall

.PHONY: clean
clean:
	rm -f *~
	cd $(executor) && $(MAKE) clean
