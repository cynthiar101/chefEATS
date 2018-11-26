require "sinatra"
require_relative "authentication.rb"

require "stripe"

set :publishable_key, 'pk_test_mzXwQqbmVbSviHEp6BkidTiM'
set :secret_key,'sk_test_ge9Vg0cxAdguvj4B14dgnXxi'

Stripe.api_key = settings.secret_key

# need install dm-sqlite-adapter
# if on heroku, use Postgres database
# if not use sqlite3 database I gave you
if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

class Video
	include DataMapper::Resource

	property :id, Serial

	#fill in the rest
	property :title, String
	property :description, String
	property :video_url, String
	property :pro, Boolean, :default  => false
	
end

DataMapper.finalize
User.auto_upgrade!
Video.auto_upgrade!

#make an admin user if one doesn't exist!
if User.all(administrator: true).count == 0
	u = User.new
	u.email = "admin@admin.com"
	u.password = "admin"
	u.administrator = true
	u.save
end

#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

get "/" do
	erb :index
end


get "/videos" do
	authenticate!

	if current_user.pro || current_user.administrator
 		@videos = Video.all
 	
 	else 
 		@videos = Video.all(pro: false)
 	end

 	erb :videos


end


post "/videos/create" do
	authenticate!
	if current_user.administrator == true

		title = params["title"]
		description = params["description"]
		video_url = params["video_url"]
		if params["pro"] == "on"
			pro = true
		end

		if title !=nil && description !=nil && video_url != nil
			
			#video = Video.new(title, description, video_url, pro)
			video = Video.new
			video.title = title
			video.description = description
			video.video_url = video_url
			if pro == true
				video.pro = pro
			end
			video.save

		    #else
	        #video = Video.new(title, description, video_url)

	        #video.save
	        #end
	        
			return "Successfully added video!"
		else

			return "Error: Missing information"
		end

	end
end 
get "/videos/new" do
	authenticate!
	if current_user.administrator == true
	erb :new_video
	else
		redirect "/"
	end
end



get "/upgrade" do
	authenticate!
	if !current_user.administrator && !current_user.pro
		erb :upgrade
	else
		redirect "/"
	end
end 


post "/charge" do



@amount = 500

  customer = Stripe::Customer.create(
    :email => 'customer@example.com',
    :source  => params[:stripeToken]
  )

  charge = Stripe::Charge.create(
    :amount      => @amount,
    :description => 'Sinatra Charge',
    :currency    => 'usd',
    :customer    => customer.id
  )

		current_user.pro =true
		current_user.save
		
  erb :charge



end








