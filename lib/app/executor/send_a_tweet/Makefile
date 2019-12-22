include ../../../../common.mk

RUBY = message_printer.rb message_to_post.rb reply_checker.rb send_a_tweet.rb tweet_poster.rb update_options.rb

app      = app
executor = executor
send_a_tweet = send_a_tweet
SEND_A_TWEET = $(LIBDIR)/$(app)/$(executor)/$(send_a_tweet)

install: $(RUBY) $(TEXT)
	mkdir -m 2750 -p $(SEND_A_TWEET)
	cp -p --update $(RUBY) $(SEND_A_TWEET)
	chgrp -R staff $(SEND_A_TWEET)
	chmod 0640 $(SEND_A_TWEET)/*.rb

.PHONY: uninstall
uninstall:
	cd $(SEND_A_TWEET) && \rm -f *.rb
	\rmdir $(SEND_A_TWEET)

.PHONY: clean
clean:
	echo YESTESTES $(SEND_A_TWEET)
	rm -f *~
