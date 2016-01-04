module Sibyl
  module EventsHelper
    def hash_to_list(hash)
      content_tag(:ul) do
        html = ""
        hash.each_with_index do |kv, i|
          k, v = kv
          v = "{...}" if v.is_a? Hash
          html += content_tag(:li, "#{content_tag :i, k}: #{v}".html_safe)
          if i == 4 && hash.size > 5
            html += content_tag(:li, "...")
            break
          end
        end
        html.html_safe
      end.html_safe
    end

    def nested_hash_to_list(hash)
      content_tag(:ul) do
        html = ""
        hash.each do |k, v|
          v = nested_hash_to_list(v) if v.is_a? Hash
          html += content_tag(:li, "#{content_tag :i, k}: #{v}".html_safe)
        end
        html.html_safe
      end.html_safe
    end
  end
end
