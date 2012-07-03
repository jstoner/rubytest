# Instructions for this test: 
# 1. Please clone this gist as a git repo locally
# 2. Create your own github repo called 'rubytest' (or a name of your choice) and add this repo as a new remote to the cloned repo
# 3. Edit this file to answer the questions, and push this file with answers back out to your own 'rubytest' repo. 

# Problem 1. Explain briefly what this code does, fix any bugs, then clean it up however you 
# like and write a unit test using RSpec.

# bracketed_list takes an array of elements and returns a string of them listed in square brackets and separated by ', '. 
# As coded it returns an extra ', ' at the end before the closing ]. It also uses a temp variable in a way that does not add clarity.
# It could be implemeted using the join method on arrays, which also does the string conversion. Also, rspec seems to want classes, 
# so let's give it one. Thus:

class Bracketer
  def self.bracketed_list(values)
    return "[" + values.join(", ") + "]"
  end
end

describe Bracketer do
  it "should return the list of stringified objects" do
    Bracketer.bracketed_list([1,2,3]).should == "[1, 2, 3]"
  end
end

# Problem 2. This is a piece of code found in a fictional Rails controller and model. 
#
# Point out any bugs or security problems in the code, fix them, and refactor the code to
# make it cleaner. Hint: think 'fat model, skinny controller'. Explain in a few sentences
# what 'fat model, skinny controller' means.

# 'Fat model, skinny controller' sounds to me like the 'rich domain  model' concept promoted by 
# Martin Fowler. It makes model objects full-fledged objects in the object-oriented sense, encapsulating
# both persistence and business logic. It would reduce duplication of code, if you are sticking to 
# the object-oriented paradigm rigorously. Looking at the code here, I also see a lot of database 
# interaction in this controller, which belongs in the domain, or at least (what the call in Java)
# the service layer.

# This controller allows any user to break a wheel on any car by specifying the user_id of the user as a 
# parameter (I think), which sounds to me like a security problem. Also there is no relationship defined 
# between a User and a Car, so the find should break. Also there is a reference to a Car's 'name,' but 
# no name defined either.

# I'd note the 'wheel' as a 'component'... not sure I like that, but I don't see a reason to change it now.

# not a fan of having a field for the number of functioning wheels. It's too easy to imagine a bug where
# it gets out of sync. I made it a method, where it's computed dynamically.

# I also don't assume 4 wheels--maybe that's overkill, but it's good to look for those assumptions. It's 
# possible to call this twice and hit the same wheel randomly, so I fixed that. One nice thing: if this breaks
# a wheel it returns true, if all the wheels are broken it returns false (I think). Maybe throwing an exception
# would be better, but that's still an improvement. 

# also there's no validation, though I don't know enough to add it

# it's more correct, a bit less efficient, though with good caching it shouldn't be significant.

class CarsController
 def break_random_wheel 
   @car = Car.get_car(params[:name])

   if functioning_wheel(@car) > 0
     @wheels = Car.get_wheels(@car)

     begin
       random_wheel =  (rand*@wheels.length).round
     end until @wheels[random_wheel].break!
   end
end

class Car < ActiveRecord::Base
  has_many :components
  attr_accessible :name

  def get_car(name)
    myUser.find_or_create(current_user.id)
    Car.find(:first, :conditions => "name = '#{params[:name]}' and user=myUser")
  end

  def get_wheels(@car)
    @car.components.find(:all, :conditions => "type = 'wheel'")
  end

  def functioning_wheels(@car)
    @wheels = get_wheels(@car)
    @wheels.length
  end
end

class Component < ActiveRecord::Base
  attr_accessible :broken
  def break!
    if  !:broken 
      :broken = true
      true
    else
      false
  end
end

class User < ActiveRecord::Base
   has_many :cars
end

# Problem 3. You are running a Rails application with 2 workers (imagine a 2-mongrel cluster or a Passenger with 2 passenger workers). 
# You have code that looks like this

class CarsController
 def start_engine
  @car = Car.first # bonus: there is a bug here. what is it?
  @car.start_engine
 end
end

class Car
 def start_engine
  api_url = "http://my.cars.com/start_engine?id={self.id}"
  RestClient.post api_url
 end
end

# 3a. Explain what possible problems could arise when a user hits this code.

# Hmm... looks like you're always getting the Car with the lowest primary key. It seems like an
# odd thing to do in a multiuser environment. If multiple users hit the controller at the same time, 
# they'll all call that rest URL, which will... start the same car over and over?  

# 3b. Imagine now that we have changed the implementation:

class CarsController
 def start_engine
  sleep(30)
 end
 def drive_away
  sleep(10)
 end
 def status
  sleep(5)
  render :text => "All good!"
 end
end

# Continued...Now you are running your 2-worker app server in production.
#
# Let's say 5 users (call them x,y,z1,z2,z3), hit the following actions in order, one right after the other. 
# x: goes to start_engine
# y: goes to drive_away
# z1: goes to status
# z2: goes to status
# z3: goes to status
#
# Explain approximately how long it will take for each user to get a response back from the server. 
# 
# x will take (worker 1) ~30 seconds
# y will take (worker 2) ~10 seconds
# z1 will take (worker 2, after waiting for y to finish) ~15 seconds
# z2 will take (worker 2, after waiting for y + z1 to finish) ~20 seconds
# z3 will take (worker 2, after waiting for y + z1 + z2 to finish) ~25 seconds

# Example: user 'x' will take about 30 seconds. What about y,z1,z2,z3?
#
# Approximately how many requests/second can your cluster process for the action 'start_engine'? What about 'drive_away'? 

on start_engine you'd process 2 requests every 30 seconds, so that would be a throughput of 1 per fifteen seconds or .0666 per second.
drive_away would be 1 per 5 seconds, or .2 per second.

# What could you do to increase the throughput (requests/second)?
1. sleep less time
2. add workers

# Problem 4. Here's a piece of code to feed my pets. Please clean it up as you see fit.

# this solution takes advantage of polymorphism and optional parameters and allows pets to be fed non-regular food.
# not in love with repeated aliasing to get at the superclass method, but it was what I found. I think if I was 
# learning Ruby in a production environment I'd look for a better way.

cat = Cat.new
dog = Dog.new
cow = Cow.new
my_pets = [cat, dog, cow, ]

my_pets.each do |pet|
 pet.feed()
end

class Pet
 def feed(food)
   puts "thanks!"
 end
end

class Cat < Pet
  alias :super_feed :feed
  def feed(food = :milk)
    super_feed(food)
  end
end

class Dog < Pet
  alias :super_feed :feed
  def feed(food=:dogfood)
    super_feed(food)
  end
end

class Cow < Pet
  alias :super_feed :feed
  def feed(food = :grass)
    super_feed(food)
  end
end

# Problem 5. Improve this code

#first, as above, better to have the data access code in the model.

# second, find_all_by is kind of a hack, as explained here:
# http://www.mokisystems.com/blog/a-couple-rails-find-gotchas/

class ArticlesController < ApplicationController 
 def index
   published_desc
 end
end


class Article < ActiveRecord::Base
  def published_desc
    @articles = Article.find(:all, :conditions= {state => Article::STATES[:published]}, :order => "created_at DESC")
  end
end

# Problem 6. Explain in a few sentences the difference between a ruby Class and Module and when it's appropriate to use either one.

# A module is a collection of methods and constants, with no instance-producing mechanism, and no inheritance. 

# Classes have instances and inheritance. 

# Classes can mix in modules, but classes themselves cannot be mixed into anything.

# Classes are appropriate for object-based code. Modules are appropriate as mix-in libraries for classes. I imagine 
# you could use classes to create data structures through instantion and use modules to organize code in a functional
# style, but that's something I'd have to experiment with.


# Problem 7. Explain the problem with this code

class UsersController
 def find_active_users
  User.find(:all).select {|user| user.active?}
 end
end

# so first you get all the users into memory, represent them as objects, and then you weed through to find the ones you
# want? That's dumb. Better to let the database do the work of finding the particular users you want before retreiving 
# and representing them. Better still to index them and use that to find what you want even faster, again, in the
# database. 

# Problem 8. Explain what's wrong with this code and fix it. (Hint: named_scope)

# Well, it seems to presume that a scope defined for Cars in the User class would return only cars belonging to that user. 
# I can't find documentation that supports that, and I can't seem to get a working rails environment in a timely manner.
# that correction would look something like this:

class User < ActiveRecord::Base
 has_many :cars

 def red_cars
  cars.scoped(:color => :red, :user => self)
 end

 def green_cars
  cars.scoped(:color => :green, :user => self)
 end
end

class Car < ActiveRecord::Base
 belongs_to :user
end

# Problem 9. Here's a piece of code that does several actions. You can see that it has duplicated 
# error handling, logging, and timeout handling. Design a block helper method that will remove
# the duplication, and refactor the code to use the block helper. 

# I'd get rid of the 'name' parameter if I could.

def err_timeout(timeout, name, action) 
  logger.info "About to do " + name
  Timeout::timeout(5) do
   begin
     action.call
   rescue => e
     logger.error "Got error: #{e.message}"
   end
  end
end

err_timeout(6, "action1", action1)
err_timeout(10, "action2", action2)
err_timeout(7, "action3", action3)

