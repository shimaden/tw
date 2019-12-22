# encoding: UTF-8
require 'getoptlong.rb'
# require 'optparse' http://d.hatena.ne.jp/zariganitosh/20140819/ruby_optparser_true_power

#--------------------------------------------------------------------
# String class but has the func attribute.
# ただの文字列に、メソッドを格納する @func を追加。
#--------------------------------------------------------------------
class StringWithFunction < ::String
  attr_reader :func
  def initialize(s, func)
    super(s)
    @func = func
  end
end

#--------------------------------------------------------------------
# Return an instance of StringWithFunction class (an extended String class).
#   Arguments:
#     option_name: string that designates an option.
#     executor   : instance of Executor class.
#     func       : name of a method belonging to executor in Symbol.
#--------------------------------------------------------------------
def sf(option_name, executor, method_name_of_executor)
  return StringWithFunction.new(option_name, executor.method(method_name_of_executor))
end

#--------------------------------------------------------------------
# Tw::App module
#--------------------------------------------------------------------
module Tw; end
module Tw::App

  #------------------------------------------------------------------
  # AbstractExecutor
  #   Execute an appropriate function according to command line.
  #------------------------------------------------------------------
  class AbstractExecutor
    private_class_method :new
    attr_accessor :parser, :renderer, :client
    #attr_reader   :logger

    class CmdOptionError < ::ArgumentError
    end

    REQARG = GetoptLong::REQUIRED_ARGUMENT
    OPTARG = GetoptLong::OPTIONAL_ARGUMENT
    NOARG  = GetoptLong::NO_ARGUMENT

    HELP_CONFIGURATION_CACHE_MODE     = 0600
    HELP_CONFIGURATION_CACHE_INTERVAL = 1 * 60 * 60

    FOLLOWERS_CACHE_PERMISSON = 0600
    FOLLOWERS_CACHE_INTERVAL  = 1 * 60 * 60
    BLOCKS_CACHE_PERMISSON    = 0600
    BLOCKS_CACHE_INTERVAL     = 1 * 60 * 60
    MUTES_CACHE_PERMISSON     = 0600
    MUTES_CACHE_INTERVAL      = 1 * 60 * 60

    # Default values of options
    DEFAULT_REPLY_DEPTH   = 0
    DEFAULT_OUTPUT_FORMAT = 'color'

    # Timelines.
    DEFAULT_TL_COUNT      = 20

    #----------------------------------------------------------------
    # Initializer
    #----------------------------------------------------------------
    def initialize()
      super()
    end

    protected

    def self.parse(executor)
      e = executor
      e.parser.set_options(

        #-------------------------
        # Main operation
        #-------------------------

        # Account manipulation.
        ['--account', '--as',                                   '-a', REQARG],
        [sf('--account-add',  e, :account_add),                       REQARG],
        [sf('--account-list', e, :account_list),                      NOARG ],
        [sf('--account-set-default', e, :account_set_default),        REQARG],

        # Tweet
        [sf('--tweet',  e, :tweet),                            '-t',  REQARG],

        # Download and print a tweet(s).
        [sf('--status', e, :status),                '--id',     '-i', REQARG],

        # Print tweets in JSON files.
        [sf('--json-file', e, :print_tweets_from_files),        '-J', REQARG],

        # Tweet from standard input.
        [sf('--pipe', e, :pipe),                                      NOARG ],

        # Retweet & Favorite.
        [sf('--retweet',  e, :retweet),            '--rt',      '-s', REQARG],
        [sf('--unretweet',  e, :unretweet),        '--unrt',          REQARG],
        [sf('--favorite', e, :favorite),           '--fav',     '-f', REQARG],
        [sf('--unfavorite', e, :unfavorite),       '--ufav',          REQARG],

        # Get conversation.
        [sf('--conversation', e, :conversation),                      REQARG],
        # Get nitification.
        [sf('--notifications', e, :notifications),                    NOARG ],

        # Print retweeters or favoriters of a specified tweet.
        [sf('--retweeters',  e, :retweeters),                         REQARG],

        # Delete a tweet.
        [sf('--delete',  e, :destroy_status),                         REQARG],

        # Read timelines.
        [sf('--timeline-home',           e, :timeline_home),
                                                    '--th',           NOARG ],
        [sf('--timeline-mentions',       e, :timeline_mentions),
                                                    '--tm',           NOARG ],
        [sf('--timeline-user',           e, :timeline_user),
                                                    '--tu',           REQARG],
        [sf('--timeline-retweets-of-me', e, :timeline_retweets_of_me),
                                                    '--tr',           NOARG ],
        [sf('--timeline-list',           e, :timeline_list),
                                                    '--tl',           REQARG],
        [sf('--timeline-search',         e, :timeline_search),
                                                    '--ts',           REQARG],
        [sf('--timeline-favorites',      e, :timeline_favorites),
                                                    '--tf',           REQARG],

        # Lists
        [sf('--lists-ownerships',  e, :lists_ownerships),  '--lists-own',     '-l', REQARG],
        [sf('--lists-memberships', e, :lists_memberships), '--lists-added',   '-L', REQARG],
        [sf('--lists-members',     e, :lists_members),                REQARG],
        [sf('--lists-add-member',  e, :lists_add_member),             REQARG],
        [sf('--lists-remove-member', e, :lists_remove_member),        REQARG],

        # Following & Followed users of specified user.
        [sf('--followings-users', e, :followings_users), '--friends-users', OPTARG],
        [sf('--followers-users',  e, :followers_users),               OPTARG],

        # Following & Followed user IDs of specified user.
        [sf('--followings-ids', e, :followings_users_ids), '--friends-ids', OPTARG],
        [sf('--followers-ids',  e, :followers_users_ids),                   OPTARG],

        # Blocking & mutes users of me.
        [sf('--blocks-users',  e, :blocks_users),                     NOARG ],
        [sf('--mutes-users',   e, :mutes_users),                      NOARG ],

        # Bolocking & mutes user IDs of me.
        [sf('--blocks-ids',  e, :blocks_users_ids),                   NOARG ],
        [sf('--mutes-ids',  e, :mutes_users_ids),                     NOARG ],

        # Stream
        [sf('--stream', e, :stream),                '--st',           NOARG ],
        [sf('--filter-stream', e, :filter_stream),  '--fst',          NOARG ],
        ['--filter-stream-follow',                                    REQARG],

        # Show information of a user.
        [sf('--user', e, :user),                                '-u', REQARG],

        # API.
        [sf('--api', e, :api),                                        OPTARG],
#        [sf('--configuration', e, :configuration),                    NOARG ],

        # Help and Version.
        [sf('--help', e, :help),                                '-h', NOARG ],
        [sf('--version', e, :version),                          '-v', NOARG ],

        # Read direct messages.
        [sf('--direct-messages', e, :direct_messages),
                                                     '--dm',    '-d', NOARG ],
        # Send a direct message.
        [sf('--direct-message-to', e, :direct_message_to),
                                                      '--dmto', '-D', REQARG],

        # Create a us/tm command line for reply or mention from an input tweet.
        [sf('--reply-format', e, :reply_format),     '--rf',          REQARG],
        [sf('--mention-format', e, :mention_format), '--mf',          REQARG],

        #-------------------------------------------------------------
        # Operation modifires
        #   NOTE: If you the names of these options, don't forget
        #         change the Options class in lib/app/executor/options.rb .
        #-------------------------------------------------------------

        # Additional options.
        ['--count',                                             '-c', REQARG],
        ['--max-id',   '--max',                                       REQARG],
        ['--since-id', '--since',                                     REQARG],
        ['--reply-depth',                            '--rd',          REQARG],
        ['--format',                                            '-F', REQARG],
        ['--no-retweets', '--nort',                                   NOARG ],

        ['--in-reply-to',                                       '-R', REQARG],
        ['--in-reply-to-new',                                   '-r', REQARG],
        ['--exclude-reply-user-ids',                            '-x', REQARG],
        ['--disaboe-auto-populate-reply', '--old-style-reply',        NOARG ],
        ['--media1', '--media',                                       REQARG],
        ['--media2',                                                  REQARG],
        ['--media3',                                                  REQARG],
        ['--media4',                                                  REQARG],
        ['--media-ids',                                               REQARG],
        ['--video',                                                   REQARG],
        ['--additional-owners',                                 '-o', REQARG],
        ['--quote-tweet',                                       '-q', REQARG],

        ['--save-as-json',                                            REQARG],
        ['--save-as-text',                                            REQARG],
        ['--save-directory', '--save-dir',                            REQARG],
        ['--message',                                           '-m', REQARG],
        ['--command-line-only',                                       NOARG ],
        ['--cc',                                                      NOARG ],

        ['--geo',                                                     NOARG ],

        ['--dont-get-tweet',                                          NOARG ],
        ['--from-cache',                                              NOARG ],

        ['--assume-yes',                            '--yes',    '-y', NOARG ],
        ['--force',                                                   NOARG ],
      )
    end

    #----------------------------------------------------------------
    # Creator
    #----------------------------------------------------------------
    def self.create(renderer, client, logger)
      #logger.debug("Enger: Tw::App::AbstractExecutor.create()")

      begin
        Executor.public_class_method(:new)
        executor = Executor.new(logger)
      ensure
        Executor.private_class_method(:new)
      end
      executor.renderer = renderer
      executor.client   = client
      executor.parser   = GetoptLong.new()
      AbstractExecutor.parse(executor)

      #logger.debug("Exit : Tw::App::AbstractExecutor.create()")
      return executor
=begin
      executor.parser = GetoptLong.new()
      o = executor
      o.parser.set_options(

        #-------------------------
        # Main operation
        #-------------------------

        # Account manipulation.
        ['--account', '--as',                                   '-a', REQARG],
        [sf('--account-add',  o, :account_add),                       REQARG],
        [sf('--account-list', o, :account_list),                      NOARG ],
        [sf('--account-set-default', o, :account_set_default),        REQARG],

        # Tweet
        [sf('--tweet',  o, :tweet),                            '-t',  REQARG],

        # Download and print a tweet(s).
        [sf('--status', o, :status),                '--id',     '-i', REQARG],

        # Print tweets in JSON files.
        [sf('--json-file', o, :print_tweets_from_files),        '-J', REQARG],

        # Tweet from standard input.
        [sf('--pipe', o, :pipe),                                      NOARG ],

        # Retweet & Favorite.
        [sf('--retweet',  o, :retweet),            '--rt',      '-s', REQARG],
        [sf('--unretweet',  o, :unretweet),        '--unrt',          REQARG],
        [sf('--favorite', o, :favorite),           '--fav',     '-f', REQARG],
        [sf('--unfavorite', o, :unfavorite),       '--ufav',          REQARG],

        # Get conversation.
        [sf('--conversation', o, :conversation),                      REQARG],
        # Get nitification.
        [sf('--notifications', o, :notifications),                    NOARG ],

        # Print retweeters or favoriters of a specified tweet.
        [sf('--retweeters',  o, :retweeters),                         REQARG],

        # Delete a tweet.
        [sf('--delete',  o, :destroy_status),                         REQARG],

        # Read timelines.
        [sf('--timeline-home',           o, :timeline_home),
                                                    '--th',           NOARG ],
        [sf('--timeline-mentions',       o, :timeline_mentions),
                                                    '--tm',           NOARG ],
        [sf('--timeline-user',           o, :timeline_user),
                                                    '--tu',           REQARG],
        [sf('--timeline-retweets-of-me', o, :timeline_retweets_of_me),
                                                    '--tr',           NOARG ],
        [sf('--timeline-list',           o, :timeline_list),
                                                    '--tl',           REQARG],
        [sf('--timeline-search',         o, :timeline_search),
                                                    '--ts',           REQARG],
        [sf('--timeline-favorites',      o, :timeline_favorites),
                                                    '--tf',           REQARG],

        # Lists
        [sf('--lists-ownerships',  o, :lists_ownerships),  '--lists-own',     '-l', REQARG],
        [sf('--lists-memberships', o, :lists_memberships), '--lists-added',   '-L', REQARG],
        [sf('--lists-members',     o, :lists_members),                REQARG],
        [sf('--lists-add-member',  o, :lists_add_member),             REQARG],
        [sf('--lists-remove-member', o, :lists_remove_member),        REQARG],

        # Following & Followed users of specified user.
        [sf('--followings-users', o, :followings_users), '--friends-users', OPTARG],
        [sf('--followers-users',  o, :followers_users),               OPTARG],

        # Following & Followed user IDs of specified user.
        [sf('--followings-ids', o, :followings_users_ids), '--friends-ids', OPTARG],
        [sf('--followers-ids',  o, :followers_users_ids),                   OPTARG],

        # Blocking & mutes users of me.
        [sf('--blocks-users',  o, :blocks_users),                     NOARG ],
        [sf('--mutes-users',   o, :mutes_users),                      NOARG ],

        # Bolocking & mutes user IDs of me.
        [sf('--blocks-ids',  o, :blocks_users_ids),                   NOARG ],
        [sf('--mutes-ids',  o, :mutes_users_ids),                     NOARG ],

        # Stream
        [sf('--stream', o, :stream),                '--st',           NOARG ],
        [sf('--filter-stream', o, :filter_stream),  '--fst',          NOARG ],
        ['--filter-stream-follow',                                    REQARG],

        # Show information of a user.
        [sf('--user', o, :user),                                '-u', REQARG],

        # API.
        [sf('--api', o, :api),                                        OPTARG],
#        [sf('--configuration', o, :configuration),                    NOARG ],

        # Help and Version.
        [sf('--help', o, :help),                                '-h', NOARG ],
        [sf('--version', o, :version),                          '-v', NOARG ],

        # Read direct messages.
        [sf('--direct-messages', o, :direct_messages),
                                                     '--dm',    '-d', NOARG ],
        # Send a direct message.
        [sf('--direct-message-to', o, :direct_message_to),
                                                      '--dmto', '-D', REQARG],

        # Create a us/tm command line for reply or mention from an input tweet.
        [sf('--reply-format', o, :reply_format),     '--rf',          REQARG],
        [sf('--mention-format', o, :mention_format), '--mf',          REQARG],

        #-------------------------------------------------------------
        # Operation modifires
        #   NOTE: If you the names of these options, don't forget
        #         change the Options class in lib/app/executor/options.rb .
        #-------------------------------------------------------------

        # Additional options.
        ['--count',                                             '-c', REQARG],
        ['--max-id',   '--max',                                       REQARG],
        ['--since-id', '--since',                                     REQARG],
        ['--reply-depth',                            '--rd',          REQARG],
        ['--format',                                            '-F', REQARG],
        ['--no-retweets', '--nort',                                   NOARG ],

        ['--in-reply-to',                                       '-R', REQARG],
        ['--in-reply-to-new',                                   '-r', REQARG],
        ['--exclude-reply-user-ids',                            '-x', REQARG],
        ['--disaboe-auto-populate-reply', '--old-style-reply',        NOARG ],
        ['--media1', '--media',                                       REQARG],
        ['--media2',                                                  REQARG],
        ['--media3',                                                  REQARG],
        ['--media4',                                                  REQARG],
        ['--media-ids',                                               REQARG],
        ['--video',                                                   REQARG],
        ['--additional-owners',                                 '-o', REQARG],
        ['--quote-tweet',                                       '-q', REQARG],

        ['--save-as-json',                                            REQARG],
        ['--save-as-text',                                            REQARG],
        ['--save-directory', '--save-dir',                            REQARG],
        ['--message',                                           '-m', REQARG],
        ['--command-line-only',                                       NOARG ],
        ['--cc',                                                      NOARG ],

        ['--dont-get-tweet',                                          NOARG ],
        ['--from-cache',                                              NOARG ],

        ['--assume-yes',                            '--yes',    '-y', NOARG ],
        ['--force',                                                   NOARG ],
      )
=end
      #logger.debug("Exit : Tw::App::AbstractExecutor.create()")
      return executor
    end

  end

end
