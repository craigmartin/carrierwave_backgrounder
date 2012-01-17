require 'spec_helper'
require 'backgrounder/orm/mongoid'
require 'backgrounder/workers/mongoid/store_asset'

# Needed so we can actually find a class for the parent record
class User; end

describe worker = CarrierWave::Workers::Mongoid::StoreAsset do

  context "on main document" do

    context "#perform" do
      before do
        @user   = mock('User')
        @image  = mock('UserAsset')
        @worker = worker.new(@user, '22', :image)
      end

      it 'processes versions' do
        File.expects(:open).with('../fixtures/test.jpg').once.returns('apple')
        FileUtils.expects(:rm).with('../fixtures/test.jpg').once
        @user.expects(:find).with('22').once.returns(@user)
        @user.expects(:image_tmp).once.returns('test.jpg')
        @user.expects(:image).once.returns(@image)
        @image.expects(:root).once.returns('..')
        @image.expects(:cache_dir).once.returns('fixtures')
        @user.expects(:process_image_upload=).with(true).once
        @user.expects(:image=).with('apple').once
        @user.expects(:image_tmp=).with(nil).once
        @user.expects(:save!).once.returns(true)

        @worker.perform
      end
    end
  end

  context "inverse of" do
    before do
      @user   = mock('User')
      @image  = mock('Image')
      @photo  = mock('Photo')
      @photos = [@image]
      options = { :embedded_in => :user, :inverse_of => :photos, :embedded_in_id => '22' }
      @worker = worker.new(@photo, '1', :image, options)
    end
    it 'process versions' do
      File.expects(:open).with('../fixtures/test.jpg').once.returns('apple')
      FileUtils.expects(:rm).with('../fixtures/test.jpg').once
      User.expects(:find).with('22').once.returns(@user)
      @user.expects(:photos).once.returns(@photos)
      @photos.expects(:find).with('1').returns(@image)
      @image.expects(:image_tmp).once.returns('test.jpg')
      @image.expects(:image).once.returns(@image)
      @image.expects(:root).once.returns('..')
      @image.expects(:cache_dir).once.returns('fixtures')
      @image.expects(:process_image_upload=).with(true).once
      @image.expects(:image=).with('apple').once
      @image.expects(:image_tmp=).with(nil).once
      @image.expects(:save!).once.returns(true)
      
      @worker.perform
    end

  end

  context "embeds one" do
    before do
      @user    = mock('User')
      @profile = mock('Profile')
      @image   = mock('Image')
      options  = { :embedded_in => :user, :embeds_one => :profile, :embedded_in_id => '22' }
      @worker  = worker.new(@photo, '1', :image, options)
    end
    it 'process versions' do
      File.expects(:open).with('../fixtures/test.jpg').once.returns('apple')
      FileUtils.expects(:rm).with('../fixtures/test.jpg').once
      User.expects(:find).with('22').once.returns(@user)
      @user.expects(:profile).once.returns(@profile)
      @profile.expects(:image_tmp).once.returns('test.jpg')
      @profile.expects(:image).once.returns(@image)
      @image.expects(:root).once.returns('..')
      @image.expects(:cache_dir).once.returns('fixtures')
      @profile.expects(:process_image_upload=).with(true).once
      @profile.expects(:image=).with('apple').once
      @profile.expects(:image_tmp=).with(nil).once
      @profile.expects(:save!).once.returns(true)
      
      @worker.perform
    end

  end
end

