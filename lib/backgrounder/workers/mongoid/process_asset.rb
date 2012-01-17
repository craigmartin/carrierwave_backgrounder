module CarrierWave
  module Workers
    module Mongoid

      class ProcessAsset < Struct.new(:klass, :id, :column, :options)
    
        def perform
          parent_id = (options) ? options.delete(:embedded_in_id) : nil
          record = if parent_id
                     # You can't access embedded documents directly with Mongoid.
                     # So, we jump through a few hoops...

                     # Find the parent record
                     parent = options[:embedded_in].to_s.classify.constantize.find parent_id

                     # Now, find the actual record to process

                     # If it's an embeds_many...
                     if options[:inverse_of]
                       parent.send(options[:inverse_of]).find id
                     elsif options[:embeds_one]
                       parent.send options[:embeds_one]
                     end
                   else
                     klass.find id
                   end
          record.send(:"process_#{column}_upload=", true)
          if record.send(:"#{column}").recreate_versions! && record.respond_to?(:"#{column}_processing")
            record.update_attribute :"#{column}_processing", nil
          end
        end
        
      end # ProcessAsset
      
    end # Mongoid
  end # Workers
end # Backgrounder

