require "active_model"
require "active_support/core_ext"
require "chronic"

module AmericanDateParsing
  mattr_accessor :delimiter do
    "[/|-]{1}"
  end

  def self.default_format
    @default_format ||= %r{\d{1,2}#{delimiter}\d{1,2}#{delimiter}\d{2,4}}
  end

  mattr_accessor :date_format do
    @date_format ||= default_format
  end

  def parse_as_americanized_date(*attributes)
    options = attributes.extract_options!

    if !defined?(ActiveRecord::Base) || !(self < ActiveRecord::Base)
      send(:include, AmericanDateParsing::Accessors)
    end

    attributes.each do |attribute|
      attr_accessor :"_raw_#{attribute}"

      if options[:validate].present?
        validates attribute, 'american_date_parsing/american_date' => options[:validate]
      end

      define_method "#{attribute}=" do |date_string|
        parsed = if date_string.respond_to?(:strftime)
          date_string.to_date
        else
          DateParser.parse(date_string.to_s)
        end

        send(:"_raw_#{attribute}=", date_string)
        write_attribute(attribute, parsed)
      end
    end
  end

  module Accessors
    def write_attribute(attribute, value)
      instance_variable_set("@#{attribute}", value)
    end

    def read_attribute(attribute)
      instance_variable_get("@#{attribute}")
    end
  end

  class AmericanDateValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      Validation.new({
        value:   record.read_attribute(attribute),
        raw:     record.send(:"_raw_#{attribute}"),
        options: options
      }).errors.each do |error, opts|
        opts = opts.respond_to?(:keys) ? opts : {}
        record.errors.add(attribute, error, opts)
      end
    end

    class Validation
      def initialize(options)
        @value   = options[:value]
        @raw     = options[:raw]
        @options = options[:options]
      end

      def errors
        [format_error, presence_error].compact
      end

      private

      attr_reader :value, :raw, :options

      def presence_error
        [:blank, options[:presence]] if validate_presence? && blank?
      end

      def format_error
        [:invalid, options[:format]] if validate_format? && format_mismatch?
      end

      def blank?
        value.blank? && raw.blank?
      end

      def format_mismatch?
        raw.present? &&
        value.blank? &&
        raw !~ AmericanDateParsing.date_format
      end

      def validate_format?
        options[:format]
      end

      def validate_presence?
        options[:presence]
      end
    end
  end

  class DateParser
    def self.parse(string)
      new(string).parse
    end

    def initialize(string)
      self.string     = string
    end

    def parse
      american_date
    end

    private

    attr_accessor :string

    def american_date
      Date.new(year, month, day) rescue nil
    end

    def components
      string.split(Regexp.new(AmericanDateParsing.delimiter))
    end

    def year
      Year.new(components[2]).to_i
    end

    def month
      components[0].to_i
    end

    def day
      components[1].to_i
    end

    class Year
      def initialize(string)
        self.base = string
      end

      def to_i
        if    zero?      then nil
        elsif two_digit? then four_digit_year
        else                  base.to_i
        end
      end

      private

      attr_accessor :base

      def zero?
        base.to_i.zero?
      end

      def two_digit?
        base.length == 2
      end

      def four_digit_year
        [
          Date.today.year.to_s[0..1],
          base
        ].join.to_i
      end
    end
  end
end
