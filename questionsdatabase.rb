require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
    attr_accessor :id, :fname, :lname
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map { |datum| User.new(datum) }
  end

  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL

    User.new(user.first)
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def create
    raise "#{self} is already in the database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
        INSERT INTO
            users (fname, lname)
        VALUES
            (?,?)
        SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} is not in the database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
        UPDATE
            users 
        SET
            fname = ?, lname = ?
        WHERE
            id = ?
        SQL
  end
  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL

    User.new(user.first)
  end
  def self.authored_questions(id)
    Question.find_by_author_id(id)
  end
  def self.authored_replies(id)
    Reply.find_by_user_id(id)
  end
  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end
  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end
end

class Question #all, find by id, init, create, find by title, find question, update
    attr_accessor :id, :title, :body, :author_id
    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
        data.map { |datum| Question.new(datum) }
    end
    def self.find_by_id(id)
        question = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                questions
            WHERE
                id = ?
            SQL
        
        Question.new(question.first)
    end
    
    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @author_id = options['author_id']
    end

    def create 
        raise "#{self} is already in the database" if @id
        QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
        INSERT INTO
            questions (fname, lname, author_id)
        VALUES
            (?,?,?)
        SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update
        raise "#{self} is not in the database" unless @id
        QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
            UPDATE
                questions
            SET
                title = ?, body = ?, author_id = ?
            WHERE
                id = ?
            SQL
    end

    def self.find_by_author_id(author_id)
        question = QuestionsDatabase.instance.execute(<<-SQL, author_id)
            SELECT
                *
            FROM
                questions
            WHERE
                author_id = ?
            SQL
        
        # Question.new(question.first)
        question.map { |datum| Question.new(datum) }
    end
    def author
        User.find_by_id(@author_id)
    end
    def replies
        Reply.find_by_question_id(@id)
    end
    def followers 
        QuestionFollow.followers_for_question_id(@id)
    end

    def self.most_followed(n)
        QuestionFollow.most_followed_question(n)
    end
    def likers
        QuestionLike.likers_for_question_id(@id)
    end
    def num_likes
        QuestionLike.num_likes_for_question_id(@id)
    end
end

#all, find by id, init, create, question_id, author_id, update
class QuestionFollow
    attr_accessor :id, :questions_id, :users_id
    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
        data.map { |datum| QuestionFollow.new(datum) }
    end

    def self.find_by_id(id)
        questions_follow = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                questions_follows
            WHERE
                id = ?
            SQL
        
        Question.new(questions_follow.first)
    end

    def initialize(options)
        @id = options['id']
        @users_id = options['users_id']
        @questions_id = options['questions_id']
    end

    def create 
        raise "#{self} is already in the database" if @id
        QuestionsDatabase.instance.execute(<<-SQL, @questions_id, @users_id)
        INSERT INTO
            question_follows(questions_id, users_id)
        VALUES
            (?,?)
        SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update
        raise "#{self} is not in the database" unless @id
        QuestionsDatabase.instance.execute(<<-SQL, @questions_id, @users_id)
            UPDATE
                question_follows
            SET
                questions_id = ?, users_id = ?
            WHERE
                id = ?
            SQL
    end

    def self.followers_for_question_id(questions_id)
        users = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
        SELECT
            *
        FROM
            USERS
        JOIN question_follows ON users.id = question_follows.users_id
        WHERE
            questions_id = ?
        SQL

        users.map { |datum| User.new(datum) }
    end

    def self.followed_questions_for_user_id(users_id)
        questions = QuestionsDatabase.instance.execute(<<-SQL, users_id)
        SELECT
            *
        FROM
            questions
        JOIN question_follows ON questions.id = question_follows.questions_id
        WHERE
            users_id = ?
        SQL
        questions.map { |datum| Question.new(datum)}
    end
    def self.most_followed_question(n)
        questions = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT 
            * 
        FROM 
            questions 
        JOIN question_follows ON question_follows.questions_id = questions.id 
        GROUP BY questions_id 
        ORDER BY COUNT(*) desc
        LIMIT 
            ?
        SQL
        questions.map {|datum| Question.new(datum)}
    end

end

#all, find by id, init, create, body, parent_id, author_id, question_id update
class Reply
    attr_accessor :id, :question_id, :author_id, :body, :parent_id
    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
        data.map { |datum| Reply.new(datum) }
    end

    def self.find_by_id(id)
        reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL

    Reply.new(reply.first)
    end

    def initialize(options)
        @id = options['id']
        @body = options['body']
        @parent_id = options['parent_id']
        @author_id = options['author_id']
        @questions_id = options['questions_id']
    end
    
    def create
        raise "#{self} is already in the database" if @id
        QuestionsDatabase.instance.execute(<<-SQL, @body, @parent_id, @author_id, @question_id)
            INSERT INTO
                replies (body, parent_id, author_id, question_id)
            VALUES
                (?,?,?,?)
            SQL
        @id = QuestionsDatabase.instance.last_insert_row_id
    end
      
    def update
        raise "#{self} is not in the database" unless @id
        QuestionsDatabase.instance.execute(<<-SQL, @body, @parent_id, @author_id, @question_id)
            UPDATE
                users 
            SET
                fname = ?, lname = ?
            WHERE
                id = ?
            SQL
    end

    def self.find_by_user_id(author_id)
        reply = QuestionsDatabase.instance.execute(<<-SQL, author_id)
            SELECT
                *
            FROM
                replies
            WHERE
                author_id = ?
            SQL
        
        # Question.new(question.first)
        reply.map { |datum| Reply.new(datum) }
    end
    def self.find_by_question_id(questions_id)
        reply = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
            SELECT
                *
            FROM
                replies
            WHERE
                questions_id = ?
            SQL
        
        # Question.new(question.first)
        reply.map { |datum| Reply.new(datum) }
    end
    def author
        User.find_by_id(@author_id)
    end
    def question
        Question.find_by_id(@questions_id)
    end
    def parent_reply
        raise "no parent" if @parent_id.nil?
        Reply.find_by_id(@parent_id)
    end
    def child_replies
        #a.child_replies --> b
        reply = QuestionsDatabase.instance.execute(<<-SQL, @id)
            SELECT
                *
            FROM
                replies
            WHERE
                parent_id = ?
            SQL
        
        # Question.new(question.first)
        reply.map { |datum| Reply.new(datum) }
    end
end

class QuestionLike
    attr_accessor :id, :questions_id, :users_id
    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM question_like")
        data.map { |datum| QuestionLike.new(datum) }
    end

    def self.find_by_id(id)
        question_like = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                question_like
            WHERE
                id = ?
            SQL
        
        QuestionLike.new(question_like.first)
    end    

    def initialize(options)
        @id = options['id']
        @questions_id = options['questions_id']
        @users_id = options['users_id']
    end

    def create 
        raise "#{self} is already in the database" if @id
        QuestionsDatabase.instance.execute(<<-SQL, @questions_id, @users_id)
        INSERT INTO
            question_like (questions_id, users_id)
        VALUES
            (?,?)
        SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update
        raise "#{self} is not in the database" unless @id
        QuestionsDatabase.instance.execute(<<-SQL, @questions_id, @users_id)
            UPDATE
                question_like
            SET
                questions_id = ?, users_id = ?
            WHERE
                id = ?
            SQL
    end
    def self.likers_for_question_id(questions_id)
        likers = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
        SELECT * 
        FROM question_like 
        JOIN users ON users.id = question_like.users_id 
        WHERE questions_id = ?;
        SQL
        #num_likes.map { |datum| QuestionLike.new(datum)}
        likers.map {|datum| User.find_by_id(datum['users_id'])}
    end
    def self.num_likes_for_question_id(questions_id)
        num_likes = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
        SELECT COUNT(*) as likes
        FROM question_like 
        GROUP BY questions_id 
        HAVING questions_id = ?;
        SQL
        #num_likes.map { |datum| QuestionLike.new(datum)}
        num_likes.first['likes']
    end
    def self.liked_questions_for_user_id(users_id)
        liked_questions = QuestionsDatabase.instance.execute(<<-SQL, users_id)
        SELECT * 
        FROM question_like 
        WHERE users_id = ?
        SQL
        liked_questions.map {|datum| Question.find_by_id(datum['questions_id'])}
    end

    
end