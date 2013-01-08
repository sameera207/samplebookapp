class Book < ActiveRecord::Base
  attr_accessible :name, :reading, :user_id
  
  after_create :update_book_status
  
  scope :my_books, lambda {|user_id|
    {:conditions => {:user_id => user_id}}  
  }
  
  scope :reading_books, lambda {
    {:conditions => {:reading => 1}}
  }
  
  scope :latest_first, lambda {
    {:order => "created_at DESC"}
  }
  
  scope :new_books, lambda {|created_date|
    {:conditions => "created_at > '#{created_date}'"}
  }
  
  
  
  def my_reading_book(user_id)
    Book.my_books(user_id).reading_books.try(:first)
  end
  
  def update_book_status
    Book.update_reading_book(self.user_id)
  end
  
  def self.update_reading_book(user_id)
     new_book =  Book.new
     currently_reading_book = new_book.my_reading_book(user_id)
     
     if currently_reading_book
        #currently has a reading book, then apply logic
        days_gone = (Date.parse(currently_reading_book.created_at.to_s) - Date.today).to_i
        unless days_gone > -7
          #current book has passed one week, then move the next book in the list as the currently
          #reading book
          my_books = Book.my_books(user_id).latest_first.new_books(currently_reading_book.created_at)
          my_books.reject!{|book| book.id == currently_reading_book.id} #remove the currently reading book
          
          unless my_books.empty?
            next_book = my_books.last
            #update next book as the reading book
            next_book.update_attribute("reading", 1)
          else
            #create a new dummy book and make it as reading
            Book.create(:name => "sample book", :reading => 1, :user_id => user_id)
          end
          currently_reading_book.update_attribute("reading", 0) #reset the current book as reading book
        end  
     else
       #currently has no reading books, as per our logic there should be a reading book
       #so this means the first book of the user, then make it as the currently reading
       #book
       first_book = Book.my_books(user_id)
       first_book.first.update_attribute("reading", 1) unless first_book.empty?  
     end
  end

end
