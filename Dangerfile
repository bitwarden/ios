xcode_summary.ignored_files = '**/SourcePackages/*'
xcode_summary.report 'build/SuthenticatorTests.xcresult'

slather.configure(
  'Authenticator.xcodeproj', 'Authenticator',
  options: {
    binary_basename: [
      'Authenticator',
      'BitwardenAuthenticatorShared',
      'Networking',
    ],
    build_directory: 'build/DerivedData',
    # Ignore Swift Packages
    ignore_list: ['build/DerivedData/SourcePackages/*']
  },
)

slather.notify_if_coverage_is_less_than(minimum_coverage: 80, notify_level: :warning)
slather.notify_if_modified_file_is_less_than(minimum_coverage: 80, notify_level: :warning)
slather.show_coverage
