# SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

FROM ruby:3.3-slim

RUN apt-get update && apt-get install -y postgresql-client libpq-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 9292

CMD ["bundle", "exec", "ruby", "0rsk.rb", "-p", "9292"]
