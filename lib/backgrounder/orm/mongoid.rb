require 'backgrounder/workers/mongoid'
require 'active_support/concern'

module CarrierWave
  module Backgrounder
    module ORM

      ##
      # Mongoid specific ORM
      module Mongoid
        extend ActiveSupport::Concern

        module ClassMethods

          ##
          # User#process_in_background will process and create versions in a background process.
          #
          # class Photo
          #   include Mongoid::Document
          #   include CarrierWave::Backgrounder::ORM::Mongoid
          #
          #   embedded_in :user, :inverse_of => :photos
          #
          #   mount_uploader :image, ImageUploader
          #   process_in_background :image, :embedded_in => :user, :inverse_of => :photos
          # end
          #
          # class Profile
          #   include Mongoid::Document
          #   include CarrierWave::Backgrounder::ORM::Mongoid
          #
          #   embedded_in :user, :inverse_of => :profile
          #
          #   mount_uploader :avatar, AvaterUploader
          #   process_in_background :avatar, :embedded_in => :user, :embeds_one => :photo
          # end
          #
          # class User
          #   include Mongoid::Document
          #
          #   embeds_many :photos
          #   embeds_one  :profile
          # end
          #
          # The above adds a Photo#process_image method which can be used at times when you want to bypass
          # background storage and processing.
          #
          #   @photo.process_image = true
          #   @photo.save
          #
          # In addition you can also add a field to the class appended by _processing with a type of boolean
          # which can be used to check if processing is complete.
          #
          #   class Photo
          #     include Mongoid::Document
          #     include CarrierWave::Backgrounder::ORM::Mongoid
          #     ...
          #     field :image_processing, :Boolean
          #   end
          #
          def process_in_background(column, options={})
            send :before_save, :"set_#{column}_processing", :if => :"trigger_#{column}_background_processing?"
            send :after_save,  :"enqueue_#{column}_background_job", :if => :"trigger_#{column}_background_processing?"

            class_eval do
              attr_accessor :"process_#{column}_upload"

              define_method :"set_#{column}_processing" do
                self.send("#{column}_processing=", true) if respond_to?(:"#{column}_processing")
              end

              define_method :"trigger_#{column}_background_processing?" do
                send(:"process_#{column}_upload") != true
              end

              define_method :"enqueue_#{column}_background_job" do
                options.merge!(:embedded_in_id => self.send(options[:embedded_in]).id) if options[:embedded_in]
                ::Delayed::Job.enqueue ::CarrierWave::Workers::Mongoid::ProcessAsset.new(self.class, id, send(column).mounted_as, options)
              end
            end
          end

          ##
          # #store_in_background  will process, version and store uploads in a background process.
          #
          # class Photo
          #   include Mongoid::Document
          #   include CarrierWave::Backgrounder::ORM::Mongoid
          #
          #   embedded_in :user, :inverse_of => :photos
          #
          #   mount_uploader :image, ImageUploader
          #   store_in_background :image, :embedded_in => :user, :inverse_of => :photos
          # end
          #
          # class Profile
          #   include Mongoid::Document
          #   include CarrierWave::Backgrounder::ORM::Mongoid
          #
          #   embedded_in :user, :inverse_of => :profile
          #
          #   mount_uploader :avatar, AvaterUploader
          #   store_in_background :avatar,:embedded_in => :user, :embeds_one => :photo
          # end
          #
          # class User
          #   include Mongoid::Document
          #
          #   embeds_many :photos
          #   embeds_one  :profile
          # end
          #
          # The above adds a Profile#process_avatar method which can be used at times when you want to bypass
          # background storage and processing.
          #
          #   @profile.process_avatar = true
          #   @profile.save
          #
          def store_in_background(column, options={})
            send :after_save, :"enqueue_#{column}_background_job", :if => :"trigger_#{column}_background_storage?"

            class_eval do
              attr_accessor :"process_#{column}_upload"

              define_method :"write_#{column}_identifier" do
                super() and return if send(:"process_#{column}_upload")
                self.send(:"#{column}_tmp=", _mounter(:"#{column}").cache_name)
              end

              define_method :"store_#{column}!" do
                super() if send(:"process_#{column}_upload")
              end

              define_method :"trigger_#{column}_background_storage?" do
                send(:"process_#{column}_upload") != true
              end

              define_method :"enqueue_#{column}_background_job" do
                options.merge!(:embedded_in_id => self.send(options[:embedded_in]).id) if options[:embedded_in]
                ::Delayed::Job.enqueue ::CarrierWave::Workers::Mongoid::StoreAsset.new(self.class, id, send(column).mounted_as, options)
              end
            end
          end
        end # ClassMethods

      end # Mongoid

    end #ORM
  end #Backgrounder
end #CarrierWave

