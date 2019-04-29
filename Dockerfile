FROM ruby:2.5

# Install gems
ENV APP_HOME /app
ENV HOME /root
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY . $APP_HOME
RUN bundle install
ENTRYPOINT [ "bundle", "exec", "rake"]
CMD [ "start" ]
