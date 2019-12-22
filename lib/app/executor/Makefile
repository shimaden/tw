include ../../../common.mk

RUBY = additional_owners.rb api_limit.rb blocks_users.rb conversation.rb \
	destroy_a_status.rb detectors.rb direct_message_handlers.rb \
	favorite_a_tweet.rb followers_users.rb followings_users.rb functions.rb \
	get_a_status.rb list.rb media_upload.rb mention_format.rb mutes_users.rb \
	notifications.rb options.rb print_tweets_from_files.rb prompt.rb \
	reply_format.rb rescue.rb retweet_a_tweet.rb retweeters.rb \
	show_a_status.rb single_tweet_handlers.rb stream.rb timeline_handlers.rb \
	user_info.rb

app      = app
executor = executor
#EXECUTORDIR = $(LIBDIR)/$(app)/$(executor)
send_a_tweet = send_a_tweet
EXECUTORDIR = $(LIBDIR)/$(app)/$(executor)

install: $(RUBY) $(TEXT)
	mkdir -m 2750 -p $(EXECUTORDIR)
	cp -p --update $(RUBY) $(EXECUTORDIR)
	chgrp -R staff $(EXECUTORDIR)
	chmod 0640 $(EXECUTORDIR)/*.rb
	cd $(send_a_tweet) && $(MAKE) install

.PHONY: uninstall
uninstall:
	cd $(EXECUTORDIR) && \rm -f *.rb
	\rmdir $(EXECUTORDIR)
	cd $(send_a_tweet) && $(MAKE) uninstall

.PHONY: clean
clean:
	rm -f *~
	make -C $(send_a_tweet) clean
