require 'vienna/adapter'

module Vienna
  class Model
    def self.url(url = nil)
      url ? @url = url : @url
    end
  end
end

module Vienna
  # Adapter for a REST backend
  class RESTAdapter < Adapter
    def create_record(record, &block)
      url = record_url(record)
      options = { dataType: "json", payload: record.as_json }
      HTTP.post(url, options) do |response|
        if response.ok?
          loaded_model = record.class.load_json response.body
          record.class.trigger :ajax_success, response
          record.did_update
          record.class.trigger :change, record.class.all
        else
          record.trigger_events :ajax_error, response
        end
      end
      
      block.call(record) if block
    end

    def delete_record(record, &block)
      options = { dataType: "json" }
      url = record_url(record)

      HTTP.delete(url, options) do |response|
        if response.ok?
          record.did_destroy
          record.class.trigger :ajax_success, response
          record.class.trigger :change, record.class.all
        else
          record.class.trigger :ajax_error, response
        end
      end

      block.call(record) if block
    end

    def record_url(record)
      return record.to_url if record.respond_to? :to_url

      if klass_url = record.class.url
        return "#{klass_url}/#{record.id}"
      end

      raise "Model does not define REST url: #{record}"
    end
  end
end

