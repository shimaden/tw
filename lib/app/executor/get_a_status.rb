# encoding: UTF-8
module Tw::App

  class Executor < AbstractExecutor

    #protected
    public

    #----------------------------------------------------------------
    # Get a status (tweet).
    #
    # Return value:
    #   Tw::Tweet if success.
    #----------------------------------------------------------------
    def get_a_status(status_id)
      #self.logger.debug("Enter: Tw::App::Executor.get_a_status()")

      result = nil

      if !((status_id =~ /^[0-9]+$/) || status_id.is_a?(Integer)) then
        $stderr.puts("Status id must be an integer or " \
                     "an integer-convertible string .")
        return result
      end

      begin
        self.client.new_auth(@account)
        status_id   = Integer(status_id)
        reply_depth = @options.reply_depth()
        user_info   = nil
        twTweet, exceptions = self.client.get_a_status(
                                  status_id,
                                  reply_depth,
                                  user_info)
        if twTweet.nil? && !!exceptions then
          exceptions.each do |e|
            $stderr.puts("#{e.message} (Status: #{status_id})")
          end
        else
          result = twTweet
        end
      rescue Tw::Error => e
        if @options.force? then
          result = nil
        else
          raise
        end
      end
      #self.logger.debug("Exit : Tw::App::Executor.status(): " \
      #                  "ID: #{result.nil? ? nil : result.id}")
      return result
    end

  end

end
