# encoding: utf-8

module Tw

  class Card
    attr_reader :attrs, :binding_values, :card_platform

    class BindingValue
      attr_reader :attrs, :type, :string_value, :value
      def initialize(hash)
        if !hash.is_a?(Hash) then
          raise ::TypeError.new("hash must be Hash but #{hash.class}.")
        end
        @attrs = hash
        @type          = hash[:type]
        @string_value  = hash[:string_value]
        @boolean_value = hash[:boolean_value]
        if @type =~ /^STRING$/i then
          if @string_value =~ /^[0-9]+$/ then
            @value = Integer(@string_value)
          elsif @string_value =~ /^2[0-9]{3}-[0-9]{2}-[0-9]{2}/ then
            @value = Time.parse(@string_value) #.localtime
          else
            @value = @string_value
          end
        elsif @type =~ /^BOOLEAN$/i then
          @value = @boolean_value
        else
          if @string_value =~ /^[0-9]+$/ then
            @value = Integer(@string_value)
          else
            @value = @string_value
          end
        end
      end
      def to_json(*a)
        hash = @attrs.dup
        hash[:value] = @value
        hash[:localtime] = @value.dup.localtime if @value.is_a?(Time)
        return hash.to_json(*a)
      end
    end
    class CardUrl < BindingValue
      def initialize(hash)
        super(hash)
        @scribe_key = hash[:scribe_key]
      end
      def to_json(*a)
        return super(*a)
      end
    end
    class PollResult
      attr_reader :choices, :total_count
      def initialize(binding_values)
        # choices_arr    : 投票の選択肢
        #   {
        #     :label    : String  選択肢の名目
        #     :count    : Integer 投票数
        #     :rate     : Float   投票数合計に対する割合
        #     :percent  : Float
        #     :top_votes: true/false 最大得票
        #     :selected : true/false 自分が投票したかどうか
        #   }
        # @total_count: 投票数合計
        @binding_values = binding_values
        @choice_labels  = @binding_values.choice_labels
        @choice_counts  = @binding_values.choice_counts

        if @binding_values.selected_choice? then
          selected_item_no = @binding_values.selected_choice.value
        else
          selected_item_no = nil
        end

        @total_count = 0
        choices_arr = @choice_labels.map.with_index{|label, i|
          count_value = @choice_counts[i].value
          @total_count += count_value
          {
            :label     => label.value,
            :count     => count_value,
            :rate      => nil,
            :percent   => nil,
            :top_votes => false,
            :selected  => (selected_item_no == i + 1),
          }
        }
        max_count = 0
        choices_arr.each do |choice|
          choice[:rate] = (@total_count > 0) ? choice[:count].to_f / @total_count : 0.0
          choice[:percent] = choice[:rate] * 100
          max_count = choice[:count] if max_count < choice[:count]
        end
        choices_arr.each do |choice|
          choice[:top_votes] = (choice[:count] == max_count)
        end
        @choices = choices_arr
      end
    end
    class BindingValues
      attr_reader :attrs, :choice_labels,
                  :choice1_label, :choice2_label, :choice3_label, :choice4_label,
                  :choice_counts,
                  :choice1_count, :choice2_count, :choice3_count, :choice4_count,
                  :selected_choice, :end_datetime_utc,
                  :last_updated_datetime_utc, :duration_minutes, :api, :card_url
      def initialize(hash)
        if !hash.is_a?(Hash) then
          raise ::TypeError.new("hash must be Hash but #{hash.class}.")
        end
        @attrs = hash

        @choice_labels = []
        4.times do |i|
          if @attrs.has_key?("choice#{i + 1}_label".to_sym) then
            @choice_labels << BindingValue.new(@attrs["choice#{i + 1}_label".to_sym])
          end
        end
        @choice1_label = @choice_labels[0]
        @choice2_label = @choice_labels[1]
        @choice3_label = @choice_labels[2]
        @choice4_label = @choice_labels[3]

        @choice_counts = []
        4.times do |i|
          if @attrs.has_key?("choice#{i + 1}_count".to_sym) then
            @choice_counts << BindingValue.new(@attrs["choice#{i + 1}_count".to_sym])
          end
        end
        @choice1_count = @choice_counts[0]
        @choice2_count = @choice_counts[1]
        @choice3_count = @choice_counts[2]
        @choice4_count = @choice_counts[3]

        if @attrs.has_key?(:selected_choice) then
          @selected_choice         = BindingValue.new(@attrs[:selected_choice])
        end
        if @attrs.has_key?(:end_datetime_utc) then
          @end_datetime_utc        = BindingValue.new(@attrs[:end_datetime_utc])
        end
        if @attrs.has_key?(:counts_are_final) then
         @counts_are_final         = BindingValue.new(@attrs[:counts_are_final])
        end
        if @attrs.has_key?(:last_updated_datetime_utc) then
          @last_updated_datetime_utc = BindingValue.new(@attrs[:last_updated_datetime_utc])
        end
        if @attrs.has_key?(:duration_minutes) then
          @duration_minutes        = BindingValue.new(@attrs[:duration_minutes])
        end
        if @attrs.has_key?(:api) then
          @api                     = BindingValue.new(@attrs[:api])
        end
        @card_url                  = CardUrl.new(@attrs[:card_url])

        @poll_result = PollResult.new(self)
      end
      def selected_choice?()
        return !!@selected_choice
      end
      def counts_are_final?()
        return @counts_are_final.value
      end
      def remaining_time()
        diff = @end_datetime_utc.value - Time.now()
        return {} if diff <= 0
        day  = diff.div(60 * 60 * 24)
        hour = diff.modulo(60 * 60 * 24).div(60 * 60)
        min  = (diff - (day * 60 * 60 * 24 + hour * 60 * 60)).div(60)
        return {:day => day, :hour => hour, :min => min}
      end
      def poll_result()
        return @poll_result
      end
      def to_json(*a)
        hash = @attrs.dup
        hash[:end_datetime_utc] = @end_datetime_utc if !!@end_datetime_utc
        hash[:last_updated_datetime_utc] = @last_updated_datetime_utc if !!@last_updated_datetime_utc
        return hash.to_json(*a)
      end
    end
    class Device
      attr_reader :attrs, :name, :version
      def initialize(hash)
        @attrs = hash
        @name    = hash[:name]
        @version = hash[:version]
      end
      def to_json(*a)
        return @attrs.to_json(*a)
      end
    end
    class Audience
      attr_reader :attrs, :name, :bucket
      def initialize(hash)
        @attrs = hash
        @name   = hash[:name]
        @bucket = hash[:bucket]
      end
      def to_json(*a)
        return @attrs.to_json(*a)
      end
    end
    class Platform
      attr_reader :attrs, :device, :audience
      def initialize(hash)
        @attrs = hash
        @device   = Device.new(hash[:device])
        @audience = Audience.new(hash[:audience])
      end
      def to_json(*a)
        return @attrs.to_json(*a)
      end
    end
    class CardPlatform
      attr_reader :attrs
      def initialize(hash)
        @attrs = hash
        @platform = Platform.new(hash[:platform])
      end
      def to_json(*a)
        return @attrs.to_json(*a)
      end
    end

    def initialize(hash)
      @attrs = hash
      @name           = hash[:name]
      @url            = hash[:url]
      @card_type_url  = hash[:card_type_url]
      @binding_values = BindingValues.new(hash[:binding_values]) if !!hash[:binding_values]
      @card_platform  = CardPlatform.new(hash[:card_platform]) if !!hash[:card_platform]
    end
    def to_json(*a)
      hash = @attrs.dup
      hash[:binding_values] = @binding_values
      hash[:card_platform]  = @card_platform
      return hash.to_json(*a)
    end

  end


end
