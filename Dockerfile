# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t test_app .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name test_app test_app

# For a self-contained dev environment with an embedded PostgreSQL (single
# container, nothing else to install; never deploy this), build the dev stage:
# docker build --target dev -t test_app-dev .
# docker run -d -p 3000:80 --name test_app-dev test_app-dev

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.9
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment variables and enable jemalloc for reduced memory usage and latency.
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libvips libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY vendor/* ./vendor/
COPY Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    # -j 1 disable parallel compilation to avoid a QEMU bug: https://github.com/rails/bootsnap/issues/495
    bundle exec bootsnap precompile -j 1 --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times.
# -j 1 disable parallel compilation to avoid a QEMU bug: https://github.com/rails/bootsnap/issues/495
RUN bundle exec bootsnap precompile -j 1 app/ lib/


# Dev-only stage (not the default build target — plain `docker build` still
# produces the production image below). Adds an embedded PostgreSQL server so
# a single `docker run` needs no external services. RAILS_ENV=dev has no gem
# group, so the bundle installed with BUNDLE_WITHOUT=development boots it.
FROM build AS dev

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y postgresql && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="dev" \
    PGDATA="/var/lib/postgresql/data"

# PostgreSQL refuses to run as root, so this stage also runs as the rails
# user, which must own the app, the cluster data dir, and the socket dir.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p "$PGDATA" /var/run/postgresql && \
    chown -R rails:rails "$PGDATA" /var/run/postgresql /rails

USER 1000:1000

# Entrypoint boots PostgreSQL, prepares the database, starts DJ workers.
ENTRYPOINT ["/rails/bin/docker-entrypoint-dev"]

EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]


# Final stage for app image
FROM base

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

# Copy built artifacts: gems, application
COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
