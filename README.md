<img src="http://www.0rsk.com/logo.svg" width="92px" height="92px"/>

[![EO principles respected here](http://www.elegantobjects.org/badge.svg)](http://www.elegantobjects.org)
[![Managed by Zerocracy](https://www.0crat.com/badge/CAZPZR9FS.svg)](https://www.0crat.com/p/CAZPZR9FS)
[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/0rsk)](http://www.rultor.com/p/yegor256/0rsk)
[![We recommend RubyMine](http://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![Build Status](https://travis-ci.org/yegor256/0rsk.svg)](https://travis-ci.org/yegor256/0rsk)
[![PDD status](http://www.0pdd.com/svg?name=yegor256/0rsk)](http://www.0pdd.com/p?name=yegor256/0rsk)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/0rsk.svg)](https://codecov.io/github/yegor256/0rsk?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/51006993d98c150f21fc/maintainability)](https://codeclimate.com/github/yegor256/0rsk/maintainability)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/0rsk)](https://hitsofcode.com/view/github/yegor256/0rsk)

It's an online risk manager.

# How to contribute

Read [these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure you build is green before you contribute
your pull request. You will need to have [Ruby](https://www.ruby-lang.org/en/) 2.3+,
Java 8+, Maven 3.2+, PostgreSQL 10+, and
[Bundler](https://bundler.io/) installed. Then:

```bash
$ bundle update
$ bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.

To run a single unit test you should first do this:

```bash
$ bundle exec rake run
```

And then, in another terminal (for example):

```bash
$ ruby test/test_agenda.rb -n test_adds_and_fetches
```

Should work.
