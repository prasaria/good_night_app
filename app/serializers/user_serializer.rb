# app/serializers/user_serializer.rb (you may already have this)
class UserSerializer
  def initialize(user, options = {})
    @user = user
    @options = options
  end

  def as_json
    return {} unless @user

    {
      id: @user.id,
      name: @user.name,
      created_at: @user.created_at,
      updated_at: @user.updated_at
    }
  end
end
