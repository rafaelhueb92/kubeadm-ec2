export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
export NO_PROXY="*"

# Run on newer macOS versions to disable the OS_ACTIVITY_MODE environment variable, which can cause issues with forking processes in certain applications.
export OS_ACTIVITY_MODE=disable
