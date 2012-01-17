require 'spec_helper'
require 'backgrounder/orm/mongoid'
require 'backgrounder/workers/mongoid/process_asset'

# Needed so we can actually find a class for the parent record
class User; end

describe worker = CarrierWave::Workers::Mongoid::ProcessAsset do

  context "on main document" do
    before do
      @user   = mock('User')
      @image  = mock('UserAsset')
      @worker = worker.new(@user, '22', :image)
    end

    context "#perform" do
      it 'processes versions' do
        @user.expects(:find).with('22').returns(@user).once
        @user.expects(:image).once.returns(@image)
        @user.expects(:process_image_upload=).with(true).once

        @image.expects(:recreate_versions!).once.returns(true)
        @user.expects(:respond_to?).with(:image_processing).once.returns(true)
        @user.expects(:update_attribute).with(:image_processing, nil).once

        @worker.perform
      end
    end
  end

  context "inverse of" do
    before do
      @user     = mock('User')
      @image    = mock('Image')
      @photo    = mock('Photo')
      @photos   = [@image]
      options   = { :embedded_in => :user, :inverse_of => :photos, :embedded_in_id => '22' }
      @worker   = worker.new(@photo, '1', :image, options)
    end

    context "#perform" do
      it 'processes versions' do
        User.expects(:find).with('22').once.returns(@user)
        @user.expects(:photos).once.returns(@photos)
        @photos.expects(:find).with('1').returns(@image)
        @image.expects(:process_image_upload=).with(true).once

        @image.expects(:image).once.returns(@image)
        @image.expects(:recreate_versions!).once.returns(true)
        @image.expects(:respond_to?).with(:image_processing).once.returns(true)
        @image.expects(:update_attribute).with(:image_processing, nil).once

        @worker.perform
      end
    end
  end

  context "embeds one" do
    before do
      @user   = mock('User')
      @profile  = mock('Profile')
      @image  = mock('Image')
      options  = { :embedded_in => :user, :embeds_one => :profile, :embedded_in_id => '22' }
      @worker  = worker.new(@photo, '1', :image, options)
    end

    context "#perform" do
      it 'processes versions' do
        User.expects(:find).with('22').once.returns(@user)
        @user.expects(:profile).once.returns(@profile)
        @profile.expects(:process_image_upload=).with(true).once
        @profile.expects(:image).once.returns(@image)
        @image.expects(:recreate_versions!).once.returns(true)
        @profile.expects(:respond_to?).with(:image_processing).once.returns(true)
        @profile.expects(:update_attribute).with(:image_processing, nil).once

        @worker.perform
      end
    end

  end
end

