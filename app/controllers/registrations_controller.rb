class RegistrationsController < Devise::RegistrationsController
  
  before_filter :fetch_associations, :only => [:new, :create, :edit, :update]
  before_filter :fetch_secret_user, :only => [:claim, :activate, :reactivate]
  prepend_before_filter :authenticate_scope!, :only => [:activity, :edit, :update, :destroy]
  
  def new
  
   #select>
	 #	<option></option>
	 #	<optgroup label="United Kingdom">
	 #		<option>Southwest</option>
	 #		<option>North</option>
	 #	</optgroup>
	 #	<optgroup label="International">
	 #		<option>France</option>
	 #		<option>Japan</option>
	 #	</optgroup>
	 #</select>
    resource = build_resource({})
    respond_with resource
    
  end
  
  def edit
    render :edit
  end
  
  # We're overwriting the default create and update
  # so we can call save_talents - better way of doing this?
  def create
    build_resource
    if resource.save
      
      save_talents
      save_gig_activity
      AdminMailer.new_user(resource).deliver
      
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
      
    else
      clean_up_passwords resource
      respond_with resource
    end
  end
  
  def update
    if resource.update_attributes(params[resource_name])
      set_flash_message :notice, :updated
      sign_in resource_name, resource, :bypass => true
      save_talents
      save_gig_activity
      redirect_to after_update_path_for(resource)
    else
      clean_up_passwords(resource)
      render_with_scope :edit
    end
  end
    
  def claim
    if @user.nil?
      not_found
    end
  end
  
  def reactivate
    if @user.nil?
      not_found
    end
  end
  
  def activate
     
    if @user.nil? || params[:user][:password].empty?
      render :claim
    else 
      if @user.reset_password!(params[:user][:password], params[:user][:password_confirmation])
        @user.activated = true
        @user.save!
        flash[:notice] = "Account activated!"
        sign_in 'user', @user, :bypass => true
        redirect_to after_update_path_for(@user)
      else
        render :claim
      end
    end
    
  end 
  
  def activity
    @past_gigs = Gig.past
  end
  
  protected
    
    def fetch_secret_user
          
      if params[:secret].nil? or params[:id].nil?
        nil
      else
        @user = User.joins(:ning_profile).where("ning_profiles.id = #{params[:secret]} && users.activated = false && users.id = #{params[:id]}").first
      end
      
    end
    
    def fetch_associations
      @skills = Skill.all
      @locations = ["South","North"]
    end
    
    def save_talents
      if params[:skill]
        resource.talents.delete_all
        params[:skill].each do |i,skill|
          @skill = Skill.find(i)
          resource.talents.create(:skill_id => @skill.id, :level => skill)
        end
      end
    end
    
    def save_gig_activity
      if params[:gigs]
        
        resource.slots.each do |slot|
          slot.users.delete(resource) unless slot.gig_id.nil? || slot.gig.future?
        end
        
        params[:gigs].each do |gig|
          @gig = Gig.find(gig)
          @gig.slots.first.users << resource
        end
        
      end
    end
    
    def after_update_path_for(resource)
       member_path(resource)
    end
    
    def after_sign_up_path_for(resource)
       member_path(resource)
    end
  
end