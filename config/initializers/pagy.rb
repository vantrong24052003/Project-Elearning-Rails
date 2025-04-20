# frozen_string_literal: true

# Load Pagy
require 'pagy'

# Pagy configuration
Pagy::DEFAULT[:items] = 12
Pagy::DEFAULT[:size]  = [1, 4, 4, 1]
Pagy::DEFAULT[:overflow] = :last_page
