include ../../../../common.mk

RUBY = entities_for_tweet.rb entities_for_user.rb hashtags.rb media.rb \
	symbols.rb urls_tweet.rb user_mentions.rb

client    = client
container = container
entities  = entities

ENTDIR = $(LIBDIR)/$(client)/$(container)/$(entities)

install: $(RUBY)
	mkdir -m 2750 -p $(ENTDIR)
	cp -p --update $(RUBY) $(ENTDIR)
	chgrp -R staff $(ENTDIR)
	chmod 0640 $(ENTDIR)/*.rb

.PHONY: uninstall
uninstall:
	cd $(ENTDIR) && \rm -f *
	\rmdir $(ENTDIR)

.PHONY: clean
clean:
	rm -f *~
