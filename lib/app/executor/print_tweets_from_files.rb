# encoding: utf-8

module Tw::App
  class Executor < AbstractExecutor

    protected

    def print_tweets_from_files(optname, optarg)
      ret_arr = []
      ret = 0
      self.client.new_auth(@account)
      begin
        file = (optarg == '-') ? "/dev/stdin" : optarg
        hash_arr = []
        File.open(file) do |io|
          while json = io.gets do
            hash_arr << JSON.parse(json.strip, :symbolize_names => true)
          end
        end
        tweet_arr = self.client.build_statuses(hash_arr)
        self.renderer.display(tweet_arr, @options.format(), separator: "\n", current_user_id: self.client.current_user_id, no_retweets: @options.no_retweets?)
        ret = 0
      #rescue Errno::ENOENT
      rescue SystemCallError
        raise
      end
      return ret
    end

  end
end
