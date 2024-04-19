xcode_summary.ignored_files = '**/SourcePackages/*'
xcode_summary.report 'build/AuthenticatorTests.xcresult'

slather.configure(
  'Authenticator.xcodeproj', 'Authenticator',
  options: {
    binary_basename: [
      'Authenticator',
      'AuthenticatorShared',
      'Networking',
    ],
    build_directory: 'build/DerivedData',
    # Ignore Swift Packages
    ignore_list: ['build/DerivedData/SourcePackages/*']
  },
)

slather.notify_if_coverage_is_less_than(minimum_coverage: 25, notify_level: :warning)
slather.notify_if_modified_file_is_less_than(minimum_coverage: 0, notify_level: :warning)
slather.show_coverage
