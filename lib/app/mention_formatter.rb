# encoding: UTF-8

module Tw::App

  class MentionFormatter

    def initialize(tweet, format)
      @tweet  = tweet
      @format = format
    end

    def build()
      extendedglob = false
      esc = Sh::Shell::ZshEscapeSequence.new(extendedglob)
      text = esc.append_escape_characters(
                  @tweet.full_text.decode_html()
             ).escape_line_feed()
      mention_text = " RT @#{@tweet.user.screen_name}: #{text}"
      command_name = Tw::Conf::SOFTWARE_NAME

      if @format[:cmd_fmt] == Tw::App::Renderer::FMT_ARRAY then
        return [command_name, mention_text, "-R #{@tweet.id}"]
      else
        return "#{command_name} \"#{mention_text}\" -R #{@tweet.id}"
      end
    end

  end

end
