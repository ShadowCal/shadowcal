class RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(resource)
    if resource.is_a? User
      path_for nilas_connect(resource)
    else
      super
    end
  end
end
