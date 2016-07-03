require 'fileutils'

@dir = File.expand_path(__dir__)

# Set the working application directory
# working_directory "/path/to/your/app"
working_directory @dir

# Create subdirectories if they don't exist
FileUtils.mkdir_p('tmp/pids') unless File.exists?('tmp/pids')
FileUtils.mkdir_p('tmp/sockets') unless File.exists?('tmp/sockets')
FileUtils.mkdir_p('log') unless File.exists?('log')

# Unicorn PID file location
# pid "/path/to/pids/unicorn.pid"
pid "#{@dir}/tmp/pids/unicorn.pid"

# Path to logs
# stderr_path "/path/to/logs/unicorn.log"
# stdout_path "/path/to/logs/unicorn.log"
stderr_path "#{@dir}/log/unicorn.stderr.log"
stdout_path "#{@dir}/log/unicorn.stdout.log"

# Unicorn socket
# listen "/tmp/unicorn.[app name].sock"
listen "#{@dir}/tmp/sockets/unicorn.sock", :backlog => 64

# Number of processes
# worker_processes 4
worker_processes 2

# Time-out
timeout 30

preload_app true
