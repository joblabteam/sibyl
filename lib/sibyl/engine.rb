require_relative "../../app/models/sibyl/trigger"

module Sibyl
  class Engine < ::Rails::Engine
    isolate_namespace Sibyl

    # initializer "sibyl.initialize_constants", before: "sibyl.load_custom_files" do |app|
      # ::Sibyl::TRIGGERS = {}
    # end
    # initializer "sibyl.load_custom_files" do |app|
      # Dir[app.root.join("lib/sibyl/**/*.rb")].each { |f| require f }
    # end
  end
end
