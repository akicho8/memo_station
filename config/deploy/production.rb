# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

role :app, %w[ deploy@localhost ]
role :web, %w[ deploy@localhost ]
role :db,  %w[ deploy@localhost ]

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

server "localhost", user: "deploy", roles: %w[ web app ], my_property: :my_value

set :rails_env, "production"
