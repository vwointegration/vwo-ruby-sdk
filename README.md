# VWO Ruby SDK

This open source library allows you to A/B Test your Website at server-side.

## Requirements

* Works with 2.5.1+

## Installation

```bash
gem install vwo_sdk
```

## Basic usage

**Importing and Instantiation**

```ruby
require vwo_sdk

# Initialize client
vwo_client_instance = VWO.new(account_id, sdk_key)

# Initialize client with all parameters(explained in next section)
vwo_client_instance = VWO.new(account_id, sdk_key, custom_logger, UserProfileService.new, true, settings_file)

# Get Settings
vwo_client_instance.get_settings

# Activate API
variation_name = vwo_client_instance.activate(campaign_test_key, user_id')

# GetVariation API
variation_name = vwo_client_instance.get_variation(campaign_test_key, user_id')

# Track API
vwo_client_instance.track(campaign_test_key, user_id', goal_identified, revenue_value)

```

1. `account_id` - Account for which sdk needs to be initialized
1. `sdk_key` - SDK key for that account
1. `custom_logger` - If you need to pass custom logger. Check documentation below
1. `UserProfileService.new` - An object allowing `lookup` and `save` for maintaining user profile
1. `development_mode` - on/off (true/false). Default - false
1. `settings_file` - Settings file if already present during initialization. Its stringified JSON format.


**API usage**

**Custom Logger**

There are two ways you can use your own custom logging

1. Override Existing Logging

    ```
    class VWO
      class CustomLogger
        def initialize(logger_instance)
          # Override this two create your own logging instance
          # Make sure log method is defined on it
          # i.e @@logger_instance = MyLogger.new(STDOUT)
          @@logger_instance = logger_instance || Logger.new(STDOUT)
        end

        # Override this method to handle logs in a custom manner
        def log(level, message)
          # Modify level & Message here
          # i.e message = "Custom message #{message}"
          @@logger_instance.log(level, message)
        end
      end
    end
    ```

2. Pass your own logger during client initialization

`vwo_client_instance = VWO.new(account_id, sdk_key, custom_logger)`

***Note*** - Make sure your custom logger instance has `log` method which takes `(level, message)` as arguments.

**User Profile**

To profile a user you can override UserProfile methods. i.e -

    ```
    class VWO
      # Abstract class encapsulating user profile service functionality.
      # Override with your own implementation for storing
      # And retrieving the user profile.

      class UserProfile

        # Abstract method, must be defined to fetch the
        # User profile dict corresponding to the user_id.
        #
        # @param[String]        :user_id            ID for user whose profile needs to be retrieved.
        # @return[Hash]         :user_profile_obj   Object representing the user's profile.
        #
        def lookup(user_id)
          # example code to fetch it from DB column
          JSON.parse(User.find_by(vwo_id: user_id).vwo_profile)
        end

        # Abstract method, must be to defined to save
        # The user profile dict sent to this method.
        # @param[Hash]    :user_profile_obj     Object representing the user's profile.
        #
        def save(user_profile_obj)
            # example code to save it in DB
           User.update_attributes(vwo_id: user_profile_obj.userId, vwo_profile: JSON.generate(user_profile_obj))
        end
      end
    end

    # Now use it to initiate VWO client instance
    vwo_client_instance = VWO.new(account_id, sdk_key, custom_logger, UserProfile.new)
    ```



## Documentation

Refer [Official VWO Documentation](https://developers.vwo.com/reference#server-side-introduction)


## Code syntax check

```
bundle exec rubocop lib
```

## Running Unit Tests

```bash
ruby tests/*.rb
```


## Credits

Pending

## Contributing

Pending

## Code of Conduct

Pending

## License

```text
    MIT License

    Copyright (c) 2019 Wingify Software Pvt. Ltd.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
```
