FROM ruby:2.5

# Install gems
ENV APP_HOME /app
ENV HOME /root
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY Gemfile $APP_HOME/
RUN bundle install

# Upload source
COPY . $APP_HOME
ENTRYPOINT [ "bundle", "exec", "rake"]
CMD [ "start" ]