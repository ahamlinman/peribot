**Peribot is no longer in active development.** Its components are kept on
GitHub in the hope that they may be useful to others, but please keep in mind
that they have not been maintained for some time, and may fail to operate as
originally intended.

**Why?** Peribot was developed as a basis for some GroupMe chatbots that I
personally operated. Those bots are rarely used anymore, and Peribot is not
used elsewhere to my knowledge. Thus, I no longer have much reason to invest in
this project.

Thank you for your interest, and sorry for the bad news. The Peribot README
continues below, but please note that parts of it may become outdated over
time.

---

# Peribot

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

## Documentation

Framework classes are [pretty
well-documented](http://www.rubydoc.info/github/ahamlinman/peribot/master), and
may be a good start toward understanding Peribot. I have also made several
resources available on the [Peribot
wiki](https://github.com/ahamlinman/peribot/wiki), including the [Zero to
Peribot](https://github.com/ahamlinman/peribot/wiki/Zero-to-Peribot) tutorial
(which is designed to help you set up a basic bot with Peribot).

## License

Peribot is available under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
