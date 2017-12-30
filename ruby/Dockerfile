FROM ruby:2.4-alpine3.7

RUN mkdir /app
WORKDIR /app

# Need these libraries present to compile nokogiri
RUN apk add --no-cache build-base libxml2-dev libxslt-dev

ENV NOKOGIRI_USE_SYSTEM_LIBRARIES 1
ADD Gemfile /app
ADD Gemfile.lock /app
RUN bundle install

ENV STDOUT=1
ADD get_mods.rb /app

ENTRYPOINT ["bundle", "exec", "ruby", "get_mods.rb"]
