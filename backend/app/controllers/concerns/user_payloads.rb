module UserPayloads
  private

  def user_payload(user)
    {
      id: user.id,
      email: user.email,
      display_name: user.display_name,
      title: user.title,
      bio: user.bio,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
