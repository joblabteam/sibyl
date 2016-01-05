require 'test_helper'

module Sibyl
  class WebhooksControllerTest < ActionController::TestCase
    setup do
      @routes = Engine.routes
    end

    test "should get webhook" do
      get :webhook
      assert_response :success
    end

  end
end
