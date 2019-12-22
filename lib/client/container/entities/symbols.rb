# encoding: UTF-8
require 'forwardable'

module Tw

  #==================================================================
  # Symbols クラス
  #==================================================================
  class Symbols < DelegateClass(Array)
    extend ::Forwardable
    def_delegators :@array, :size, :[], :each, :select, :reject, :find,
                      :to_a, :collect, :map

    def initialize(symbols)
      @array = symbols.collect {|elem| Tw::SymbolsElem.new(elem)}
    end

    def to_a(*a)
      return @array.to_a(*a)
    end

    def to_json(*a)
      @array.to_json(*a)
    end

  end

  #==================================================================
  # SymbolsElem クラス
  #==================================================================
  class SymbolsElem
    attr_reader :id, :screen_name, :name, :indices

    def initialize(elem)
      if elem.nil? then
        return
      end
      #if elem.is_a?(Twitter::Entity::Symbol) then # Obsolete
      #  raise TypeError.new("Obsolete type: #{elem.class}.")
      #  @text        = elem.text
      #  @indices     = elem.indices
      #elsif elem.is_a?(Hash) then
      if elem.is_a?(Hash) then
        @text        = elem[:text]
        @indices     = elem[:indices]
      else
        raise TypeError.new("elem must be a Hash but #{elem.class}.")
      end

    end

    def to_json(*a)
      {
        :text        => @text,
        :indices     => @indices
      }.to_json(*a)
    end

  end

end
