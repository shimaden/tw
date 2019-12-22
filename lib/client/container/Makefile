include ../../../common.mk

#RUBY = current_user_retweet.rb dmtweet.rb list.rb place.rb tweet.rb tweet_helper.rb user.rb
RUBY = card.rb current_user_retweet.rb dmtweet.rb geo.rb geo_results.rb list.rb tweet.rb tweet_helper.rb tweet_kind.rb user.rb
client       = client
container    = container
entities     = entities
extended_entities = extended_entities
CONTAINERDIR = $(LIBDIR)/$(client)/$(container)
ENTDIR       = $(CONTAINERDIR)/$(entities)

install: $(RUBY)
	cd entities && $(MAKE) install
	mkdir -m 2750 -p $(CONTAINERDIR)
	cp -p --update $(RUBY) $(CONTAINERDIR)
	chgrp -R staff $(CONTAINERDIR)
	chmod 0640 $(CONTAINERDIR)/*.rb
	cd $(extended_entities) && $(MAKE) install

.PHONY: uninstall
uninstall:
	cd $(entities) && make uninstall
	cd $(CONTAINERDIR) && \rm -f *
	\rmdir $(CONTAINERDIR)
	cd $(extended_entities) && $(MAKE) uninstall

.PHONY: clean
clean:
	cd $(entities) && $(MAKE) clean
	cd $(extended_entities) && $(MAKE) clean
	rm -f *~
