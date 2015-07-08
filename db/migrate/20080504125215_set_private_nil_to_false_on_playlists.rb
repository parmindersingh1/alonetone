class SetPrivateNilToFalseOnPlaylists < ActiveRecord::Migration
  def self.up
    Playlist.where(private: nil).each do |playlist|
      playlist.private = false
      playlist.save
    end
  end

  def self.down
  end
end
