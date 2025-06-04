# syntax=docker/dockerfile:1
# check=error=true

# Dockerfile cho môi trường production
# Build: docker build -t elearning .
# Run: docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value> --name elearning elearning

ARG RUBY_VERSION=3.4.2
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Build stage
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install --no-install-recommends -y nodejs && \
    corepack enable && \
    corepack prepare yarn@3.6.1 --activate && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Install JavaScript dependencies
RUN yarn install

# Precompile bootsnap
RUN bundle exec bootsnap precompile app/ lib/

# Precompile Vite assets (with dummy secret key)
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/vite build

# Final image
FROM base

# Copy build artifacts
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Set non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Healthcheck with longer timeout and grace period
HEALTHCHECK --interval=10s --timeout=30s --start-period=120s --retries=5 \
  CMD curl --fail http://localhost:3000 || exit 1


# Entrypoint and startup        
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
 CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"] 