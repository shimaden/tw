# encoding: UTF-8

module Tw

  # ツイートの種類を扱うクラス
  #
  # ツイートの種類
  #   1. 単発ツイート
  #   2. リツイート（単発ツイートを内包しているツイート）
  #   3. リツイート・メソッドの結果として戻ってくるツイート
  #
  class TweetKind

    def initialize(tweet)
      @tweet = tweet
    end

    # ふつうのツイート
    # （リツイートではない && リツイートAPIの戻り値でもない）
    def regular_tweet?()
      return !@tweet.retweeted_status? && !@tweet.result_of_retweet?
    end

    # リツイートを内包するツイート
    # （リツイートである && リツイートAPIの戻り値ではない）
    # （公式や多くのクライアントでは外の殻は見せない）
    def retweet?()
      return @tweet.retweeted_status? && !@tweet.result_of_retweet?
    end

    # Twitter::Client#retweet() メソッドの戻り値であるツイート  # Obsolete
    def result_of_retweet?()
      return @tweet.retweeted_status? && @tweet.result_of_retweet?
    end

  end

end
