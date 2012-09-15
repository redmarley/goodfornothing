class RegistrationsController < Devise::RegistrationsController
  
  before_filter :fetch_associations, :only => [:new, :create, :edit, :edit_talents, :update]
  prepend_before_filter :authenticate_scope!, :only => [:edit_activity, :edit_talents, :edit_password, :edit, :update, :destroy]
  
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
  
  def edit_password
  end
  
  def edit_talents    
  end
  
  def edit_activity
    @past_gigs = Gig.past
  end

  def create
    
    ning_user = User.joins(:ning_profile).where('users.email = ? && users.activated = ?', params[:user][:email], false).first
    
    unless ning_user.nil?
      
      redirect_to reactivate_path(:email => ning_user.email, :route => "create")
      
    else
      
      build_resource
    
      if resource.save
      
        save_talents(resource)
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
  end
  
  def update
    if resource.update_attributes(params[resource_name])
      set_flash_message :notice, :updated
      sign_in resource_name, resource, :bypass => true
      save_talents(resource)
      save_gig_activity
      redirect_to after_update_path_for(resource)
    else
      clean_up_passwords(resource)
      render_with_scope :edit
    end
  end
    
  def reactivate
    @new_user = params[:route]
    @user = User.where("activated = false && email = '#{params[:email]}'").first
    if @user.nil?
      not_found
    end
  end
  
  def send_reactivation
    @user = User.where("activated = false && email = '#{params[:user][:email]}'").first
    if @user.nil?
      not_found
    else
      UserMailer.reactivate_user(@user).deliver
    end
  end
  
  def claim
    if params[:reset_password_token].blank?
      not_found
    else
      @user = User.new
    end
  end
  
  def activate
    
    params[:reset_password_token] = params[:user][:reset_password_token]
    
    if !params[:user][:password].blank?
    
      @user = User.reset_password_by_token(params[:user])

      if @user.errors.empty?
        @user.activated = true
        @user.save!
        flash_message = @user.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message(:notice, flash_message) if is_navigational_format?
        sign_in(User, @user)
        redirect_to member_path(@user, :welcome=>"yahuh")
      else
        flash[:error] = nil
        render :claim
      end
      
    else
      flash[:error] = "Your password can not be blank"
      render :claim
    end
    
  end 
  
  protected
    
    def fetch_associations
      @skills = Skill.all
      @locations = ["South","North"]
    end
    
    def save_talents(resource)
      
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
       member_path(resource, :welcome=>"yahuh")
    end
  
end