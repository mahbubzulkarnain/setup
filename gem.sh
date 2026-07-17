#!/usr/bin/env bash
set -euo pipefail

echo "Install Global Gemfile"

gem install rubocop
gem install rails_best_practices
gem install brakeman
gem install rubycritic
