module Sibyl
  class ApplicationController < ActionController::Base
    http_basic_authenticate_with(
      name: "sibyl",
      password: (ENV["SIBYL_PASSWORD"] || "12345678"),
      except: [:webhook]
    )
  end
end
