ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../../Gemfile", __dir__)
ENV["SERVICE_NAME"] ||= "triagem"
require "bundler/setup"
require "bootsnap/setup"
