class ColophonController < ApplicationController

	def who
	  @chapters = Chapter.all
	end
	
	def how
	end

	def community
	  
	  @social = Social.where('start_time > ?',Time.now).first
	  @gig = Gig.where('end_time > ?',Time.now).order("start_time DESC").first
	
	end
	
	def calendar
	  
	  @socials = Social.where('start_time > ?',Time.now).order("start_time DESC")
  	@gigs = Gig.where('end_time > ?',Time.now).order("start_time DESC")
	  
	end

end