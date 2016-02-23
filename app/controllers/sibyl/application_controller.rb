module Sibyl
  class ApplicationController < ActionController::Base
    http_basic_authenticate_with(
      name: "sibyl",
      password: (ENV["SIBYL_PASSWORD"] || "12345678"),
      except: [:webhook]
    )

    private

    def to_csv(records)
      if records.is_a?(Hash)
        if records.key?(:funnel)
          "#{records[:funnel].first.keys.join(',')}\n#{records[:funnel].map { |v| v.values.join(',') }.join("\n")}"
        else
          "id,count\n#{records.map { |v| v.join(',') }.join("\n")}"
        end
      elsif records.is_a?(Numeric)
        "#{(params[:funnel][0] || params[:funnel][:"0"])[:operation]}\n#{records}"
      elsif records.is_a?(Numeric)
      else
        "#{records.first.as_json.keys.join(',')}\n#{records.map do |r|
          (r.is_a?(Hash) ? r : r.serializable_hash).values.join(',')
        end.join("\n")}"
      end
    end
  end
end
