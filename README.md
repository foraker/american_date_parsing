# AmericanDateParsing

American-style (e.g 12/25/2014) date parsing for ActiveRecord and ActiveModel.

## Installation

Add this line to your application's Gemfile:

    gem 'american_date_parsing'

And then execute:

    $ bundle

## Usage

Invoke `parse_as_americanized_date` in a model.

```Ruby
class MyModel < ActiveRecord::Base
  parse_as_americanized_date :activates_on, :expires_on
end

instance = MyModel.new

instance.activates_on = "12/25/2012"
instance.activates_on
# => Tue, 25 Dec 2012

instance.expires_on = Date.new(2012, 12, 25)
instance.expires_on
# => Tue, 25 Dec 2012
```

## Validation

Presence and format validations are added by passing options to `parse_as_americanized_date`. Note: make sure to `include ActiveModel::Validations` for `ActiveModel` subclasses.

```Ruby
class MyModel < ActiveRecord::Base
  parse_as_americanized_date :activates_on, validate: {
    presence: true,
    format: true
  }
end

instance = MyModel.new

instance.valid?
instance.errors[:activates_on]
# => ["can't be blank"]

instance.activates_on = "1225-2012"
instance.valid?
instance.errors[:activates_on]
# => ["is invalid"]

instance.activates_on = "12-25-2012"
instance.valid?
instance.errors[:activates_on]
# => []
```

### Custom validation messages

Just as with standard validations, `:validate` accepts a `:message` option.

```Ruby
class MyModel < ActiveRecord::Base
  parse_as_americanized_date :activates_on, validate: {
    presence: {message: "is required"},
    format: {message: "needs to be formatted as MM/DD/YYYY"}
  }
end

instance = MyModel.new

instance.valid?
instance.errors[:activates_on]
# => ["is required"]

instance.activates_on = "1225-2012"
instance.valid?
instance.errors[:activates_on]
# => ["needs to be formatted as MM/DD/YYYY"]
```

Alternatively, custom messaging can be acheived via i18n.


```YAML
en:
  errors:
    attributes:
      activates_on:
        blank: is required
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## About Foraker Labs

<img src="http://assets.foraker.com/foraker_logo.png" width="400" height="62">

This project is maintained by Foraker Labs. The names and logos of Foraker Labs are fully owned and copyright Foraker Design, LLC.

Foraker Labs is a Boulder-based Ruby on Rails and iOS development shop. Please reach out if we can [help build your product](http://www.foraker.com).
