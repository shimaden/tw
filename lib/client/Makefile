include ../../common.mk

#RUBY = apilimit.rb auth.rb blocks_ids_cursor.rb client.rb configuration.rb custom_friends_and_followers_ids.rb direct_messages.rb followers_ids.rb followers_ids_cursor.rb friends_ids_cursor.rb lists.rb mutes_ids_cursor.rb new-auth.rb singletweet.rb stream.rb stream_message.rb user_ids_cursor.rb user_list_cursor.rb usergetter.rb users_lookup.rb
RUBY = apilimit.rb auth.rb blocks_ids_cursor.rb cacheable_friends_and_followers_ids.rb client.rb configuration.rb direct_messages.rb error.rb followers_ids_cursor.rb friends_ids_cursor.rb lists.rb mutes_ids_cursor.rb new_auth.rb reply-bot.rb retweeters_ids_cursor.rb single_tweet.rb stream.rb stream_message.rb twitter_configuration.rb twitter_requester.rb user_getter.rb user_ids_cursor.rb user_list_cursor.rb users_lookup.rb

client    = client
container = container
timeline  = timeline
CLIENTDIR = $(LIBDIR)/$(client)

install: $(RUBY)
	mkdir -m 2750 -p $(CLIENTDIR)
	cp -p --update $(RUBY) $(CLIENTDIR)
	chgrp -R staff $(CLIENTDIR)
	chmod 0640 $(CLIENTDIR)/*.rb
	cd $(container) && $(MAKE) install
	cd $(timeline) && $(MAKE)  install

.PHONY: uninstall
uninstall:
	cd $(container) && $(MAKE) uninstall
	cd $(timeline) && $(MAKE)  uninstall
	\rm $(CLIENTDIR)/*
	\rmdir $(CLIENTDIR)

.PHONY: clean
clean:
	cd $(container) && $(MAKE) clean	
	cd $(timeline) && $(MAKE) clean	
	rm -f *~
