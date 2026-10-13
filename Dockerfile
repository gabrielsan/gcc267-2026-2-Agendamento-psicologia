# syntax = docker/dockerfile:1
ARG RUBY_VERSION=3.2.3
FROM ruby:${RUBY_VERSION}-slim

WORKDIR /rails

ENV BUNDLE_PATH="/usr/local/bundle" \
    RAILS_ENV="development"

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git libpq-dev postgresql-client libvips pkg-config && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
RUN chmod +x /rails/bin/*

EXPOSE 3000

CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
