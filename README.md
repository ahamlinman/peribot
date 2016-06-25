# Peribot [![Build Status](https://travis-ci.org/ahamlinman/peribot.svg?branch=master)](https://travis-ci.org/ahamlinman/peribot)

Peribot is a message processing framework in Ruby, designed mainly to
facilitate the creation of IRC-style bots for services like GroupMe. That is,
it is explicitly designed to provide a common set of services for multiple
"groups" at once (in contrast with frameworks like Hubot).

The framework is designed for responsiveness and ease of development. The
concurrent processing model ensures that individual groups' actions don't lead
to delays for others, while facilities provided by the framework make it easy
to develop powerful, thread-safe services. Configuration is designed to be
simple and fast for bot maintainers.

With [Peribot::GroupMe](https://github.com/ahamlinman/peribot-groupme), running
a GroupMe bot is as simple as running a Ruby script. Thanks to push
notification support, there's no need to run a web server and manage callback
URLs.

## Development Status

I consider Peribot to be beta-quality software. Breaking changes to the
framework are possible at any time. However, I do use a form of semantic
versioning to help reduce the impact of these changes. As the `MAJOR` version
of Peribot is currently 0, I typically increment the `MINOR` version on
breaking changes and the `PATCH` version on new features. When maintaining a
bot, a version specifier such as `~> 0.6.0` will make your life easier.

## Documentation

Framework classes are [pretty
well-documented](http://www.rubydoc.info/github/ahamlinman/peribot/master).
However, I am considering simplified guides for service writers and bot
maintainers as a future project after the completion of Peribot 0.8. Please
stay tuned for updates.

## Roadmap

Peribot is currently at version 0.7.

* For Peribot 0.8, I will be working on a standardized, service-agnostic format
  for messages, as well as changes to how reply sending works and other small
  breaking updates. This will require work on the part of authors of services
  and senders. Services for previous Peribot versions are likely to be fully
  incompatible with 0.8.x.

As I have heard that others are interested in starting to use Peribot for their
own projects, I think that these major changes will help correct some of my
poorer design decisions and provide a positive experience moving forward.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/ahamlinman/peribot. Please ensure that contributions are
tested!

## License

The gem is available under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
