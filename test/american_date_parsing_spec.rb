require 'minitest'
require 'minitest/autorun'

require File.expand_path("../../lib/american_date_parsing", __FILE__)

describe AmericanDateParsing do
  class TestModel
    include ActiveModel
    include ActiveModel::Validations
    extend AmericanDateParsing

    attr_accessor :date

    parse_as_americanized_date :date, validate: {
      format: true,
      presence: true
    }
  end

  def with_date(string)
    instance = TestModel.new
    instance.date = string
    instance.date
  end

  def errors(string)
    instance = TestModel.new
    instance.date = string
    instance.valid?
    instance.errors[:date]
  end

  describe "validations" do
    it "accepts a valid american date" do
      errors("12/25/2012").wont_include('is invalid')
    end

    it "accepts hyphen delimiters" do
      errors("12-25-2012").wont_include('is invalid')
    end

    it "accepts abbreviated delimiters" do
      errors("12-25-2012").wont_include('is invalid')
    end

    it "rejects non-delimited dates" do
      errors("12252012").must_include('is invalid')
    end

    it "rejects dates with extraneous delimiters" do
      errors("12/25//2012").must_include('is invalid')
    end

    it "rejects dates with missing delimiters" do
      errors("12/252012").must_include('is invalid')
    end

    it "rejects nonsense dates" do
      errors("cats").must_include('is invalid')
    end

    it "rejects missing dates" do
      errors("").must_include('can\'t be blank')
    end
  end

  describe "setting" do
    it "accepts American style dates" do
      with_date("12/25/2012").must_equal Date.new(2012, 12, 25)
    end

    it "accepts hyphen delimiters" do
      with_date("12-25-2012").must_equal Date.new(2012, 12, 25)
    end

    it "accepts abbreviated years" do
      with_date("12/25/12").must_equal Date.new(2012, 12, 25)
    end

    it "accepts dates" do
      with_date(Date.today).must_equal Date.today
    end

    it "accepts times" do
      with_date(Date.today.to_time).must_equal Date.today
    end

    it "accepts nil" do
      with_date(nil).must_equal nil
    end

    it "sets nonsense dates to nil" do
      with_date("cats").must_equal nil
    end

    # Chronic.parse has some interesting side effects:

    it "accepts words like 'tomorrow'" do
      with_date("tomorrow").must_equal Date.tomorrow
    end

    it "assumes time-like integers are the current date" do
      with_date("2").must_equal Date.today
    end
  end
end
