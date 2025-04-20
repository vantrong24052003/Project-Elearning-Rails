# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Add audio files to the asset path - for Propshaft
Rails.application.config.assets.paths << Rails.root.join('app/assets/audios')

# The config.assets.precompile setting is not used by Propshaft
# Instead, all assets in the app/assets folder are included automatically
