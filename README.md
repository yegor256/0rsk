# Online Risk Manager

[![EO principles respected here](https://www.elegantobjects.org/badge.svg)](https://www.elegantobjects.org)
[![DevOps By Rultor.com](https://www.rultor.com/b/yegor256/0rsk)](https://www.rultor.com/p/yegor256/0rsk)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/0rsk/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/0rsk/actions/workflows/rake.yml)
[![PDD status](https://www.0pdd.com/svg?name=yegor256/0rsk)](https://www.0pdd.com/p?name=yegor256/0rsk)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/0rsk.svg)](https://codecov.io/github/yegor256/0rsk?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/51006993d98c150f21fc/maintainability)](https://codeclimate.com/github/yegor256/0rsk/maintainability)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/0rsk)](https://hitsofcode.com/view/github/yegor256/0rsk)
[![Availability at SixNines](https://www.sixnines.io/b/6ea3)](https://www.sixnines.io/h/6ea3)

This is an online risk manager, where you register all know risks
  in your project, assign probabilities
  and impacts, and then create mitigation and avoidance
  plans for them.
Using this information the system generates an agenda of
  the most critical tasks for you.

Read this blog post, it explains it all in details:
  [0rsk.com: Cause + Risk + Effect][blog].

Here you can find some inspiration: [yegor256/awesome-risks].

It's free for everybody.

## How to contribute

- Read these [guidelines].
- Use Devcontainer to setup your environment quickly or do it manually as suggested below.
- Make sure your build is green before you contribute your pull request.

You will need to have [Ruby] 2.3+, Java 8+, Maven 3.2+, PostgreSQL 10+,
  and [Bundler] installed.
Then:

```bash
bundle install
bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.

To run a single unit test you should first do this:

```bash
bundle exec rake run
```

And then, in another terminal (for example):

```bash
ruby test/test_risks.rb -n test_adds_and_fetches
```

If you want to test it in your browser, open `http://localhost:9292`. If you
want to login as a test user, just open this: `http://localhost:9292?glogin=test`.

Should work.

[blog]: https://www.yegor256.com/2019/05/14/cause-risk-effect.html
[yegor256/awesome-risks]: https://github.com/yegor256/awesome-risks
[guidelines]: https://www.yegor256.com/2014/04/15/github-guidelines.html
[Ruby]: https://www.ruby-lang.org/en/
[Bundler]: https://bundler.io/
