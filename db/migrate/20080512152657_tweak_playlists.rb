class TweakPlaylists < ActiveRecord::Migration
  def self.up
    Playlist.where(description: '').each do |playlist|
      playlist.description = playlist.title
      playlist.save
    end
    
    Playlist.where(private: nil).each do |playlist|
      playlist.private = false
      playlist.save
    end
  end

  def self.down
  end
end
