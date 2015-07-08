class Comment < ActiveRecord::Base
  
  scope :recent,             -> { order('id DESC') }
  scope :only_public,        -> { recent.where(:is_spam => false).where(:private => false) }
  scope :by_member,          -> { recent.where('commenter_id IS NOT NULL') }
  scope :include_private,    -> { recent.where(:is_spam => false) }
  scope :public_or_private,  ->(has_access) { has_access ? include_private : only_public }
  scope :spam,               -> { recent.where(:is_spam => true) }
  scope :on_track,           -> { where(:commentable_type => 'Asset') }
  scope :last_5_private,     -> { on_track.include_private.limit(5).preload(:commenter => :pic, :commentable => {:user => :pic})}
  scope :last_5_public,      -> { on_track.only_public.limit(5).preload(:commenter => :pic, :commentable => {:user => :pic}) }
  scope :made_between,       ->(start, finish) {where('comments.created_at BETWEEN ? AND ?', start, finish)}

  has_many :replies, :as  => :commentable, :class_name => 'Comment'

  # optional user who made the comment
  belongs_to :commenter, :class_name => 'User'

  # optional user who is *recieving* the comment
  # this helps simplify a user lookup of all comments across tracks/playlists/whatever
  belongs_to :user

  belongs_to :commentable, :polymorphic => true, :touch => true
  validates_length_of :body, :within => 1..2000
  validates :commentable_id, presence: true
  
  before_create :disallow_dupes, :set_spam_status, :set_user
  after_create :deliver_comment_notification, :increment_counters
  
  attr_accessible :body, :remote_ip, :commentable_type, :commentable_id, :private, 
    :commenter_id, :user_agent, :referrer, :commenter, :user_id, :commentable

  before_save :truncate_user_agent


  include Rakismet::Model
  rakismet_attrs  :author =>        proc { author_name },
                  :author_email =>  proc { commenter.email if commenter },
                  :content =>       proc { body },
                  :permalink =>     proc { commentable.try(:full_permalink) }

  def duplicate?
    Comment.where(:remote_ip => remote_ip, :body => body).first.present?
  end
  
  def disallow_dupes
    return false if duplicate?
  end
  
  def set_user
    self.user = commentable.user if commentable.respond_to? :user
    true
  end
  
  def set_spam_status
    self.is_spam = spam? # makes API request
    true
  end
  
  def author_name
    if commenter
      commenter.login
    else
      'guest'
    end
  end

  def user_logged_in
    !!commenter_id 
  end
  
  def deliver_comment_notification
    CommentNotification.new_comment(self, commentable).deliver_now if is_deliverable?
  end
  
  def increment_counters
    if commentable.is_a? Asset
      User.increment_counter(:comments_count, commentable.user) 
      Asset.increment_counter(:comments_count, commentable) 
    end
  end
  
  def is_deliverable?
    !is_spam? and commentable.class == Asset and 
      user.wants_email? and user != commenter
  end

  def truncate_user_agent
    self.user_agent = self.user_agent.try(:slice, 0, 255)
  end
end
