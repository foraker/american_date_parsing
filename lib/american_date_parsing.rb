require "active_model"
require "active_support/core_ext"
require "chronic"

module AmericanDateParsing
  mattr_accessor :delimiter do
    "[/|-]{1}"
  end

  def self.default_format
    @default_format ||= %r{\d{1,2}#{delimiter}\d{1,2}#{delimiter}\d{2,4}( \d{1,2}:\d{2}( )?(PM|AM))?}
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
          date_string.to_datetime
        else
          Chronic.parse(date_string.to_s).try(:to_datetime)
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
end
