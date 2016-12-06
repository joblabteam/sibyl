require_dependency "sibyl/application_controller"

module Sibyl
  class EventsController < ApplicationController
    before_action :set_event, only: [:show]

    def index
      @events = Event.all

      params_funnel = nil
      if params[:funnel]
        params_funnel = if params[:funnel].is_a?(Array)
                          params[:funnel].map(&:to_unsafe_h)
                        else
                          params[:funnel].to_unsafe_h
                        end
      end
      if params_funnel&.size&.> 1 # we are in a funnel!
        funnel = params_funnel.first
        funnel = funnel.last if funnel.is_a? Array

        if funnel[:group].blank? # dropoffs funnel
          funnel_relation = Event.all.from("sibyl_events AS a0")
          funnel_results = { funnel: [] }
          first_value = nil

          params_funnel&.each_with_index do |funnel, i|
            funnel = funnel.last if funnel.is_a? Array
            last_index = params_funnel.is_a?(Array) ? i - 1 : :"#{i - 1}"
            last_funnel = params_funnel[last_index]
            last_funnel = last_funnel.last if last_funnel.is_a? Array

            funnel_relation = Event.all.where_funnel(i, funnel[:property], last_funnel[:property], funnel_relation, funnel[:previous_to]) if i > 0
            funnel_relation = general_filters("a#{i}", funnel_relation, funnel)

            value = funnel_relation.operation("a#{i}", funnel[:operation], Event.property_query("a#{i}", funnel[:property]), funnel[:order])
            p value
            first_value = value unless first_value
            percent = [(100.0 / first_value) * value, 100.0].min

            funnel_results[:funnel] << {
              value: value,
              percent: percent,
              label: funnel[:title].blank? ? funnel[:kind] : funnel[:title]
            }
          end

          @events = funnel_results
        else # multi calculation funnel
          params_funnel&.each_with_index do |funnel, i|
            funnel = funnel.last if funnel.is_a? Array

            relation = Event.all.from("sibyl_events AS a#{i}")
            relation = relation.from("(#{funnel_relation.to_sql}) a#{i - 1}") if i > 0
            relation = general_filters("a#{i}", relation, funnel)
            if i == 0
              funnel_relation = relation.operation("a#{i}", funnel[:operation], Event.property_query("a#{i}", funnel[:property]), funnel[:order], primitive: false)
            else
              funnel_relation = relation.operation("a#{i}", funnel[:operation], funnel[:group], funnel[:order], primitive: false)
            end
            funnel_relation = funnel_relation.group_by("a#{i}", funnel[:group], funnel[:order]) unless funnel[:group].blank? if i < params_funnel.size - 1

            if i == params_funnel.size - 1
              @events = funnel_relation.to_a[0][funnel[:operation]]
            end
          end
        end
      elsif params_funnel # just a single value query
        funnel = params_funnel
        funnel = funnel.is_a?(Hash) ? funnel[:"0"] : funnel[0]
        relation = Event.all

        relation = general_filters(relation, funnel)
        unless funnel[:group].blank?
          relation = relation.group_by(funnel[:group], funnel[:order])
        end
        relation = relation.operation(funnel[:operation], Event.property_query(funnel[:property]), funnel[:order])
        @events = relation
      else
        relation = Event.all
        @events = general_filters(relation, {})
      end

      respond_to do |format|
        format.json do
          render json: @events
        end
        format.html {}
        format.csv { render text: to_csv(@events) }
      end
    end

    def kinds
      @kinds = Event.select(:kind).distinct.order(:kind)
    end

    def create
      @event = Event.new

      respond_to do |format|
        format.json do
          if @event.from_json(event_params).save
            render json: @event, status: :created # , location: @user
          else
            render json: @event.errors, status: :unprocessable_entity
          end
        end
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def event_params
      params.require(:event).permit(:type, :occurred_at, :data)
    end

    def time_from_seconds(seconds)
      Time.at(Time.now - Time.at(seconds)).to_s
    end

    def safe_limit(funnel)
      limit = funnel[:limit].blank? ? false : funnel[:limit].to_i
      if funnel[:operation].blank?
        limit || 50
      else
        limit
      end
    end

    def general_filters(as = nil, relation, funnel)
      relation = relation.in_kind(as, funnel[:kind])
      relation = relation.order_by(as, funnel[:order])

      funnel[:filters]&.each do |filter|
        filter = filter.last if filter.is_a? Array

        relation = relation.filter_property?(as, filter[:property])
        relation = relation.filter_property_value(
          as, filter[:filter], filter[:property], filter[:value]
        )

        if params[:format] == "csv" && !funnel[:operation]
          relation = relation.select(
            Sibyl::Event.columns.map(&:name).reject { |v| v == "data" } <<
              relation.property_query(filter[:property])
          )
        end
      end

      # ignore dates in later stages of a funnel
      unless as && (m = as.match(/\w(\d+)/)) && m[1].to_i > 0
        relation = relation.date_from funnel[:from] unless funnel[:from].blank?
        relation = relation.date_to funnel[:to] unless funnel[:to].blank?
        relation = relation.date_previous funnel[:previous] unless funnel[:previous].blank?
        relation = relation.date_previous_to funnel[:previous_to] unless funnel[:previous_to].blank?
      end

      limit = safe_limit(funnel)
      relation = relation.limit(limit) unless limit.blank?

      relation = relation.interval(funnel[:interval]) unless funnel[:interval].blank?

      relation
    end
  end
end
