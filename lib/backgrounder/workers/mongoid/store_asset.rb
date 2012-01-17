module CarrierWave
  module Workers
    module Mongoid

      class StoreAsset < Struct.new(:klass, :id, :column, :options)
    
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
          if tmp = record.send(:"#{column}_tmp")
            asset = record.send(:"#{column}")
            cache_dir  = [asset.root, asset.cache_dir].join("/")
            cache_path = [cache_dir, tmp].join("/")
          
            record.send :"process_#{column}_upload=", true
            record.send :"#{column}=", File.open(cache_path)
            record.send :"#{column}_tmp=", nil
            if record.save!
              FileUtils.rm(cache_path)
            end
          end
        end
        
      end # StoreAsset

    end # Mongoid
  end # Workers
end # Backgrounder

