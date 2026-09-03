namespace :user do
  # Usage:
  #   bin/rails "user:create[alice,s3cretpassword,admin]"
  # or with prompts:
  #   bin/rails user:create
  desc "Create a user (args: username, password, role[default member])"
  task :create, %i[username password role] => :environment do |_t, args|
    username = args[:username] || prompt("Username: ")
    password = args[:password] || prompt("Password: ", echo: false)
    role     = args[:role].presence || "member"

    user = User.new(username: username, password: password, role: role)

    if user.save
      puts "Created user '#{user.username}' (id: #{user.id})"
    else
      abort "Could not create user: #{user.errors.full_messages.join(', ')}"
    end
  end

  def prompt(label, echo: true)
    require "io/console"
    print label
    value = echo ? $stdin.gets&.chomp : $stdin.noecho(&:gets)&.chomp
    puts unless echo
    value.to_s.strip
  end
end
