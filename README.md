# CanHazEvatr

Ruby gem for validating EU VAT identification numbers against the German eVATr service. Supports both the legacy XML-RPC API and the new REST API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'can_haz_evatr'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install can_haz_evatr

## Usage

### Configuration

Configure the gem with your VAT ID (required for queries):

```ruby
# Configure requester VAT ID (required)
CanHazEvatr::Check.config.requester_vat = 'DE123456789'

# Choose API version (defaults to XML-RPC)
CanHazEvatr.use_rest_api = false  # Use XML-RPC API (default)
# CanHazEvatr.use_rest_api = true  # Use REST API
```

### Direct VAT Check

#### Using the legacy XML-RPC API (default):

```ruby
result = CanHazEvatr::Check.check(
  vat: 'PT123456789',
  name: 'Company Name',
  city: 'Berlin',
  street: 'Main Street 1',
  zip: '10115'
)

# Check if VAT ID is valid
result.valid?  # => true/false

# Check which fields didn't match
result.errors  # => [:city, :street]

# Get individual field results
result.results
# => { name: :ok, city: :no_match, street: :ok, zip: :not_provided }

# Get the checked VAT ID
result.checked_vat_id  # => 'PT123456789'
```

#### Using the new REST API:

```ruby
# Enable REST API
CanHazEvatr.use_rest_api = true
CanHazEvatr::Check.config.requester_vat = 'DE123456789'

# Use the check_class helper to get the right implementation
result = CanHazEvatr.check_class.check(
  vat: 'PT123456789',
  name: 'Company Name',
  city: 'Berlin',
  street: 'Main Street 1',
  zip: '10115'
)

# Check if VAT ID is valid
result.valid?  # => true/false

# Get status code (evatr-0000, evatr-2002, etc.)
result.status_code  # => 'evatr-0000'

# Check which fields didn't match
result.errors  # => [:city, :street]

# Get the checked VAT ID
result.checked_vat_id  # => 'PT123456789'

# Get validity dates (if applicable)
result.valid_from  # => '2026-01-01'
result.valid_to    # => '2026-12-31'

# Get request date
result.request_date  # => '2026-01-12'
```

### ActiveModel Validation

You can use the built-in validator with ActiveModel/ActiveRecord:

```ruby
class Company < ApplicationRecord
  validates :vat_id, evatr: true

  # Define how to map your model attributes to eVATr fields
  def full_name
    name
  end
end
```

#### Custom field mapping:

```ruby
# Configure field mapping (applies to both APIs)
CanHazEvatr::Check.config.mapping = ->(record) {
  {
    name: record.company_name,
    city: record.location,
    street: record.address,
    zip: record.postal_code
  }
}
```

#### Recording responses:

```ruby
# Store API responses in database for audit purposes
CanHazEvatr::Check.config.recorder = 'EvatrResponse'

# Your recorder model should accept these attributes:
# - record_id (ID of the validated record)
# - record_type (Class name of the validated record)
# - response (API response text)
```

### API Versions

#### Legacy XML-RPC API (default)
- Endpoint: `https://evatr.bff-online.de/evatrRPC`
- Format: XML-RPC
- Use when: You need backward compatibility

#### New REST API
- Endpoint: `https://api.evatr.vies.bzst.de/v1/abfrage`
- Format: JSON
- Use when: You want modern REST interface with better status codes

To switch between APIs:

```ruby
# Use legacy XML-RPC API (default)
CanHazEvatr.use_rest_api = false

# Use new REST API
CanHazEvatr.use_rest_api = true

# Get the appropriate class based on configuration
check_class = CanHazEvatr.check_class  # Returns Check or RestCheck
```

### Direct Class Usage

You can also call the API classes directly if you prefer:

```ruby
# Directly use XML-RPC API
CanHazEvatr::Check.config.requester_vat = 'DE123456789'
result = CanHazEvatr::Check.check(vat: 'PT123456789', ...)

# Directly use REST API
CanHazEvatr::RestCheck.config.requester_vat = 'DE123456789'
result = CanHazEvatr::RestCheck.check(vat: 'PT123456789', ...)
```

**Note:** `Check` and `RestCheck` have separate config objects. The `CanHazEvatr.use_rest_api` flag only affects which class is returned by `CanHazEvatr.check_class` - it doesn't prevent you from using either API directly.

### Status Codes (REST API)

The REST API returns detailed status codes:

- `evatr-0000`: VAT ID is valid
- `evatr-2002`: Not currently valid, but becomes valid on a future date (see `valid_from`)
- `evatr-2006`: Was valid within a specific date range (see `valid_from` and `valid_to`)
- `evatr-2008`: Valid with special circumstances/notes

### Field Validation Results

Both APIs return validation results for individual fields:

- `:ok` - Field matches the VAT registry
- `:no_match` - Field doesn't match the VAT registry
- `:not_provided` / `:not_reported` - Field was not checked

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Testing

```bash
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hackersthinkers/can_haz_evatr.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Legal Notice

According to EU law, businesses must validate VAT IDs before invoicing customers. This gem helps you comply with this requirement by providing an interface to the official German eVATr (electronic VAT ID validation) service.

## API Documentation

- Legacy API: https://evatr.bff-online.de/
- REST API: https://api.evatr.vies.bzst.de/api-docs
