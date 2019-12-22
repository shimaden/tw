# encoding: utf-8

module Tw

  # Tweet クラスに実装するよりも外部で実装した方が
  # よさそうな機能。（ツイートの生データを汚さない
  # ため）。

  module TweetHelper

    def hidden_prefix?
      return self.new_140_count_feature? && self.display_text_range[0] > 0
    end

    def hidden_mentions?
      return self.hidden_prefix? && self.entities.user_mentions?
    end

    def hidden_mentions()
      return [] if !self.hidden_mentions?
      result = []
      self.entities.user_mentions.each do |user_mention|
        break if user_mention.indices[1] > self.display_text_range[1]
        result.push(user_mention)
      end
      return result
    end

    def hidden_suffix?
      return self.new_140_count_feature? \
          && self.display_text_range[1] < self.full_text.length \
          && self.extended_entities? # && self.extended_entities.media?
    end

    def text_in_range()
      if self.new_140_count_feature? then
        range = self.display_text_range()
        return self.full_text[range[0]..range[1]]
      else
        return self.text
      end
    end

  end

end
