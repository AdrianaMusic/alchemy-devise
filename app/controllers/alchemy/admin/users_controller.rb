module Alchemy
  module Admin
    class UsersController < ResourcesController

      filter_access_to [:edit, :update, :destroy], :attribute_check => true, :load_method => :load_user, :model => Alchemy::User
      filter_access_to [:index, :new, :create], :attribute_check => false

      before_filter :set_roles_and_genders, :except => [:index, :destroy]

      handles_sortable_columns do |c|
        c.default_sort_value = :login
      end

      def index
        if !params[:query].blank?
          users = User.where([
           "login LIKE ? OR email LIKE ? OR firstname LIKE ? OR lastname LIKE ?",
           "%#{params[:query]}%",
           "%#{params[:query]}%",
           "%#{params[:query]}%",
           "%#{params[:query]}%"
         ])
        else
          users = User.scoped
        end
        @users = users.page(params[:page] || 1).per(per_page_value_for_screen_size).order(sort_order)
      end

      def create
        @user = User.create(params[:user])
        render_errors_or_redirect(
          @user,
          admin_users_path,
          _t("User created", :name => @user.name)
        )
      end

      def update
        # User is fetched via before filter
        params[:user].delete(:alchemy_roles) unless permitted_to?(:update_roles)
        if params[:user][:password].present?
          @user.update_attributes(params[:user])
        else
          @user.update_without_password(params[:user])
        end
        render_errors_or_redirect(
          @user,
          admin_users_path,
          _t("User updated", :name => @user.name)
        )
      end

      def destroy
        # User is fetched via before filter
        name = @user.name
        if @user.destroy
          flash[:notice] = _t("User deleted", :name => name)
        end
        respond_to do |format|
          format.html { redirect_to admin_users_path }
          format.js do
            @redirect_url = admin_users_path
            render action: 'redirect'
          end
        end
      end

      private

      def load_user
        @user = User.find(params[:id])
      end

      def set_roles_and_genders
        @user_roles = User::ROLES.map { |role| [User.human_rolename(role), role] }
        @user_genders = User.genders_for_select
      end

    end
  end
end
