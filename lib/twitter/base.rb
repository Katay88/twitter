require 'forwardable'
require 'twitter/null_object'

module Twitter
  class Base
    extend Forwardable
    attr_reader :attrs
    alias to_h attrs
    alias to_hash attrs
    alias to_hsh attrs
    def_delegators :attrs, :delete, :update

    # Define methods that retrieve the value from an initialized instance variable Hash, using the attribute as a key
    #
    # @param attrs [Array, Symbol]
    def self.attr_reader(*attrs)
      attrs.each do |attr|
        define_attribute_method(attr)
        define_predicate_method(attr)
      end
    end

    # Create a new object (or NullObject) from attributes
    #
    # @param klass [Symbol]
    # @param key1 [Symbol]
    # @param key2 [Symbol]
    def self.object_attr_reader(klass, key1, key2=nil)
      define_attribute_method(key1, klass, key2)
      define_predicate_method(key1)
    end

    # Dynamically define a method for an attribute
    #
    # @param key1 [Symbol]
    # @param klass [Symbol]
    # @param key2 [Symbol]
    def self.define_attribute_method(key1, klass=nil, key2=nil)
      define_method(key1) do
        memoize(key1) do
          if klass.nil?
            @attrs[key1]
          else
            if @attrs[key1]
              if key2.nil?
                Twitter.const_get(klass).new(@attrs[key1])
              else
                attrs = @attrs.dup
                value = attrs.delete(key1)
                Twitter.const_get(klass).new(value.update(key2 => attrs))
              end
            else
              Twitter::NullObject.new
            end
          end
        end
      end
    end

    # Dynamically define a predicate method for an attribute
    #
    # @param key [Symbol]
    def self.define_predicate_method(key)
      define_method(:"#{key}?") do
        !!send(key)
      end
    end

    # Construct an object from a response hash
    #
    # @param response [Hash]
    # @return [Twitter::Base]
    def self.from_response(response={})
      new(response[:body])
    end

    # Initializes a new object
    #
    # @param attrs [Hash]
    # @return [Twitter::Base]
    def initialize(attrs={})
      @attrs = attrs || {}
    end

    # Fetches an attribute of an object using hash notation
    #
    # @param method [String, Symbol] Message to send to the object
    def [](method)
      send(method)
    rescue NoMethodError
      nil
    end

    def memoize(key, &block)
      ivar = :"@#{key}"
      return instance_variable_get(ivar) if instance_variable_defined?(ivar)
      result = block.call
      instance_variable_set(ivar, result)
    end

  private

    # @param attr [Symbol]
    # @param other [Twitter::Base]
    # @return [Boolean]
    def attr_equal(attr, other)
      self.class == other.class && !other.send(attr).nil? && send(attr) == other.send(attr)
    end

    # @param other [Twitter::Base]
    # @return [Boolean]
    def attrs_equal(other)
      self.class == other.class && !other.attrs.empty? && attrs == other.attrs
    end

  end
end
