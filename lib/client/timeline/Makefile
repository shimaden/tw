include ../../../common.mk

#RUBY = home_timeline.rb lists_statuses_timeline.rb mentions_timeline.rb retweets_of_me_timeline.rb search_timeline.rb timeline.rb user_timeline.rb

RUBY = direct_messages_timeline.rb favorites_timeline.rb home_timeline.rb lists_statuses_timeline.rb mentions_timeline.rb retweets_of_me_timeline.rb search_timeline.rb search_universal_timeline.rb timeline.rb user_timeline.rb

client    = client
timeline  = timeline
CLIENTDIR = $(LIBDIR)/$(client)/$(timeline)

install: $(RUBY)
	mkdir -m 2750 -p $(CLIENTDIR)
	cp -p --update $(RUBY) $(CLIENTDIR)
	chgrp -R staff $(CLIENTDIR)
	chmod 0640 $(CLIENTDIR)/*.rb

.PHONY: uninstall
uninstall:
	\rm $(CLIENTDIR)/*
	\rmdir $(CLIENTDIR)

.PHONY: clean
clean:
	rm -f *~
