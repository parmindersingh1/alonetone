class KillListensWithoutAsset < ActiveRecord::Migration
  def self.up
    # I forgot to tell listens to destroy themselves when the asset is deleted
    Listen.all.select{|l| !l.asset}.each(&:destroy)
    
    # Let's kill playlists with no permalink too
    Playlist.all.select{|p| !p.permalink}.each(&:destroy)
  end

  def self.down
  end
end
