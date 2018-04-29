require_relative "../config/boot"
require "job_tomate/data/token"
require "job_tomate/data/user"

require "google/apis/sheets_v4"
require "googleauth"

# This script implements the one-way synchronization from a shared
# Google Sheets to the local database.
#
# This enables updating the app's configuration by updating the Google
# Sheet, instead of updating database records directly. This eases
# the maintenance of the configuration and enables other persons to
# manage the configuration without having to access the application
# running in production.

OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "JobTomate".freeze
CLIENT_SECRETS_PATH = "client_secret.json".freeze
SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY

class CustomTokenStore
  class << self
    attr_accessor :default
  end

  def load(id)
    token = JobTomate::Data::Token.where(token_id: id).first
    token ? token.value : nil
  end

  def store(id, token)
    t = load(id)
    if t != nil
      t.value = token
      t.save!
    else
      JobTomate::Data::Token.create!(token_id: id, value: token)
    end
  end

  def delete(id)
    token = load(id)
    if token != nil
      token.destroy
    end
  end
end
        
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.new(ENV["GOOGLE_AUTH_ID"], ENV["GOOGLE_AUTH_SECRET"])
  token_store = CustomTokenStore.new
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
    puts 'Open the following URL in the browser and enter the ' \
         'resulting code after authorization:\n' + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

# Initialize the API
service = Google::Apis::SheetsV4::SheetsService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

# Prints the names and majors of students in a sample spreadsheet:
# https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit
spreadsheet_id = ENV["GOOGLE_SHEETS_CONFIGURATION_ID"]
range = "User!A1:G"
response = service.get_spreadsheet_values(spreadsheet_id, range)

rows = response.values
columns = rows.first

rows[1..-1].each do |row|
  user_fields = {}
  columns.each_with_index do |column, index|
    user_fields[column] = row[index]
  end
  
  # We use `slack_username` to find existing records as its almost always filled
  slack_username = row[columns.index("slack_username")]
  user = JobTomate::Data::User.where(slack_username: slack_username).first
  if user != nil
    user.fields = user_fields
    user.save!
    JobTomate::LOGGER.info "Updated user with Slack username `#{slack_username}` from Google Sheets document"

  else
    JobTomate::Data::User.create!(user_fields)
    JobTomate::LOGGER.info "Created user with Slack username `#{slack_username}` from Google Sheets document"
  end
end
