class MakeAdminsModerators < ActiveRecord::Migration
  def self.up
    User.where(admin: true).each {|u| u.update_attribute :moderator, true}
  end

  def self.down
  end
end
