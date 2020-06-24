FROM ruby:2.6-alpine3.11 as builder

RUN apk add --no-cache --virtual \\
    #
    # required
    bash tzdata build-base libffi-dev \\
    #
    # nice to haves
    curl git

FROM builder as phaedra-app

# This is to fix an issue on Linux with permissions issues
ARG USER_ID=${USER_ID:-1000}
ARG GROUP_ID=${GROUP_ID:-1000}
ARG DOCKER_USER=${DOCKER_USER:-user}
ARG APP_DIR=${APP_DIR:-/home/user/phaedra-app}

# Change with --build-arg PHAEDRA_ENV=production
ARG PHAEDRA_ENV=development
ENV PHAEDRA_ENV=$PHAEDRA_ENV

# Create a non-root user
RUN addgroup -g $GROUP_ID -S $GROUP_ID
RUN adduser --disabled-password -G $GROUP_ID --uid $USER_ID -S $DOCKER_USER

# Create and then own the directory to fix permissions issues
RUN mkdir -p $APP_DIR
RUN chown -R $USER_ID:$GROUP_ID $APP_DIR

# Define the user running the container
USER $USER_ID:$GROUP_ID

# . now == $APP_DIR
WORKDIR $APP_DIR

# COPY is run as a root user, not as the USER defined above, so we must chown it
COPY --chown=$USER_ID:$GROUP_ID Gemfile* ./
RUN gem install bundler
RUN bundle install

COPY --chown=$USER_ID:$GROUP_ID . .

EXPOSE 8080

CMD ["bundle", "exec", "rackup", "-p", "8080", "-o", "0.0.0.0"]
