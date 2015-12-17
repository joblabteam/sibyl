require 'test_helper'

module Sibyl
  class EventsControllerTest < ActionController::TestCase
    setup do
      @event = sibyl_events(:one)
      @routes = Engine.routes
    end

    test "should get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:events)
    end

    test "should get new" do
      get :new
      assert_response :success
    end

    test "should create event" do
      assert_difference('Event.count') do
        post :create, event: { created_at: @event.created_at, data: @event.data, occurred_at: @event.occurred_at, type: @event.type }
      end

      assert_redirected_to event_path(assigns(:event))
    end

    test "should show event" do
      get :show, id: @event
      assert_response :success
    end

    test "should get edit" do
      get :edit, id: @event
      assert_response :success
    end

    test "should update event" do
      patch :update, id: @event, event: { created_at: @event.created_at, data: @event.data, occurred_at: @event.occurred_at, type: @event.type }
      assert_redirected_to event_path(assigns(:event))
    end

    test "should destroy event" do
      assert_difference('Event.count', -1) do
        delete :destroy, id: @event
      end

      assert_redirected_to events_path
    end
  end
end
