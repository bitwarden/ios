brew "fastlane"
brew "mint"
brew "swift-protobuf" # used by Bitwarden Authenticator

if ENV["CI"]
    brew "yq"
    brew "xcresultparser"
    brew "coreutils" # using gtimeout in test workflows to stop hanging simulators
end
