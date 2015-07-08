class SetPositionToReflectDate < ActiveRecord::Migration
  def self.up
    User.all.each do |user|
      if user.playlists.size > 0
        user.playlists.where(:order => 'created_at ASC').each do |playlist|
          playlist.insert_at
        end
      end
    end
  end

  def self.down
  end
end
