# Peribot [![Build Status](https://travis-ci.org/ahamlinman/peribot.svg?branch=master)](https://travis-ci.org/ahamlinman/peribot)

Peribot is a message processing framework in Ruby, designed mainly to
facilitate the creation of IRC-style bots for services like GroupMe. That is,
it is explicitly designed to provide a common set of services for multiple
"groups" at once (in contrast with frameworks like Hubot that generally operate
with a single set of users).

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

As of version 0.8, I consider Peribot to be of more-or-less release candidate
quality, and I am not currently planning any major breaking changes to the
framework. That being said, it is not widely tested or deployed outside of two
bots that I personally operate, and breaking changes may still be possible in
the future.

In the event that breaking changes are made to Peribot, I use a form of semantic
versioning to help reduce their impact. As the `MAJOR` version of Peribot is
currently 0, I typically increment the `MINOR` version on breaking changes and
the `PATCH` version on new features. When maintaining a bot, a version specifier
such as `~> 0.8.0` in your Gemfile is recommended.

## Documentation

Framework classes are [pretty
well-documented](http://www.rubydoc.info/github/ahamlinman/peribot/master), and
may be a good start toward understanding Peribot. I have also made several
resources available on the [Peribot
wiki](https://github.com/ahamlinman/peribot/wiki), including the [Zero to
Peribot](https://github.com/ahamlinman/peribot/wiki/Zero-to-Peribot) tutorial
(which is designed to help you set up a basic bot with Peribot). I plan on
creating additional guides in the future. Stay tuned!

## Contributing

I highly encourage bug reports and pull requests on GitHub at
https://github.com/ahamlinman/peribot. Please ensure that contributions are
tested!

I also welcome helpful comments and criticism regarding the framework. My
contact information is listed on my GitHub profile at
https://github.com/ahamlinman.

## License

Peribot is available under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
