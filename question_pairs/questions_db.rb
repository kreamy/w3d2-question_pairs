require 'sqlite3'
require 'singleton'

class QuestionDB < SQLite3::Database
  include Singleton

  def initialize
    super('questionDB2.db')
    self.type_translation = true
    self.results_as_hash = true
  end

end

###############################################################

class User
  attr_accessor :id, :fname, :lname

  def liked_questions
    QuestionFollows.liked_questions_for_user_id(@id)
  end

  def followed_questions
    QuestionFollows.followed_questions_for_user_id(@id)
  end

  def self.find_by_id(id)
    user = QuestionDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL

    return nil unless user.length > 0

    User.new(user.first)
  end

  def self.find_by_name(fname, lname)
    user = QuestionDB.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL

    return nil unless user.length > 0

    User.new(user.first)
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

end

###############################################################

class Question
  attr_accessor :id, :title, :body, :author_id

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def self.find_by_author_id(author_id)
    questions = QuestionDB.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL
    return nil unless questions.length > 0
    questions.map do |question|
      Question.new(question)
    end
  end

  def followers
    QuestionFollows.followers_for_question_id(@id)
  end

  def self.find_by_id(id)
    question = QuestionDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL

    return nil unless question.length > 0

    Question.new(question.first)
  end

  def author
    User.find_by_id(@author_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end
end

###############################################################

class QuestionFollows
  attr_accessor :id, :user_id, :question_id

  def self.most_followed_questions(n)
    questions = QuestionDB.instance.execute(<<-SQL, n)
      SELECT
        question_id
      FROM
        question_follows
      GROUP BY
        question_id
      ORDER BY
        COUNT(*) DESC
      LIMIT ?
    SQL

    return nil unless questions.length > 0
    questions.map do |question|
      Question.find_by_id(question['question_id'])
    end
  end

  def self.find_by_id(id)
    follows = QuestionDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        id = ?
    SQL

    return nil unless follows.length > 0

    QuestionFollows.new(follows.first)
  end

  def self.followers_for_question_id(question_id)
    user_ids = QuestionDB.instance.execute(<<-SQL, question_id)
      SELECT
        users.id
      FROM
        users JOIN question_follows ON users.id = question_follows.user_id
      WHERE
        question_follows.question_id = ?
    SQL

    p user_ids
    return nil unless user_ids.length > 0

    user_ids.map do |id_hash|
      User.find_by_id(id_hash['id'])
    end
  end

  def self.followed_questions_for_user_id(user_id)
    question_ids = QuestionDB.instance.execute(<<-SQL, user_id)
      SELECT
        question_id
      FROM
        -- users JOIN question_follows ON users.id = question_follows.user_id
        question_follows --JOIN users ON question_follows.user_id = users.id
      WHERE
        question_follows.user_id = ?
    SQL

    p question_ids
    return nil unless question_ids.length > 0

    question_ids.map do |id_hash|
      Question.find_by_id(id_hash['question_id'])
    end
  end

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
end

###############################################################

class Reply
  attr_accessor :id, :question_id, :body, :parent_reply_id, :author_id

  def self.find_by_user_id(user_id)
    replies = QuestionDB.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL

    return nil unless replies.length > 0

    replies.map { |reply| Reply.new(reply) }
  end

  def self.find_by_question_id(question_id)
    replies = QuestionDB.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL

    return nil unless replies.length > 0

    replies.map { |reply| Reply.new(reply) }
  end

  def self.find_by_id(id)
    replies = QuestionDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL

    return nil unless replies.length > 0

    Reply.new(replies.first)
  end

  def author
    User.find_by_id(author_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply_id
    Reply.find_by_id(parent_reply_id)
  end

  def child_replies
    reply = QuestionDB.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_reply_id = ?
    SQL
    return nil unless reply.length > 0

    Reply.new(reply.first)
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @body = options['body']
    @parent_reply_id = options['parent_reply_id']
    @author_id = options['author_id']
  end
end

###############################################################

class QuestionLikes
  attr_accessor :id, :user_id, :question_id

  def self.most_liked_questions(n)
    questions = QuestionDB.instance.execute(<<-SQL, n)
      SELECT
        DISTINCT question_id
      FROM
        question_likes
      GROUP BY
        question_id
      ORDER BY
        COUNT(user_id) DESC
      LIMIT ?
    SQL

    return nil unless questions.length > 0

    questions.map do |id_hash|
      Question.find_by_id(id_hash['question_id'])
    end
  end

  def self.likers_for_question_id(question_id)
    user_ids = QuestionDB.instance.execute(<<-SQL, question_id)
      SELECT
        users.id
      FROM
        users JOIN question_likes ON users.id = question_likes.user_id
      WHERE
        question_likes.question_id = ?
    SQL

    return nil unless user_ids.length > 0

    user_ids.map do |id_hash|
      User.find_by_id(id_hash['id'])
    end
  end

  def self.num_likes_for_question_id(question_id)
    user_ids = QuestionDB.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(*)
      FROM
        question_likes
      WHERE
        question_id = ?
    SQL
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionDB.instance.execute(<<-SQL, user_id)
      SELECT
        question_id
      FROM
        questions_liked --JOIN question_likes ON users.id = question_likes.user_id
      WHERE
        question_likes.user_id = ?
    SQL

    questions.map do |question_hash|
      Question.find_by_id(question_hash['question_id'])
    end
  end

  def self.find_by_id(id)
    likes = QuestionDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        id = ?
    SQL

    return nil unless likes.length > 0

    QuestionLikes.new(likes.first)
  end

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
end
