module PryRemote
  #
  # Overrides PryRemote::Server
  #
  module ServerExt
    #
    # Override the call to Pry.start to save off current Server, and not
    # teardown the server right after Pry.start finishes.
    #
    def run
      raise("Already running a pry-remote session!") if
        PryByebug.current_remote_server

      PryByebug.current_remote_server = self

      puts "[pry-remote] Waiting for client on #{uri}"
      client.wait

      setup
      Pry.start @object, input: client.input_proxy, output: client.output, steps_out: 5
    end

    def teardown
      return if @torn

      super
      PryByebug.current_remote_server = nil
      @torn = true
    end
  end

  class Server
    prepend ServerExt
  end
end

# Ensure cleanup when a program finishes without another break. For example,
# 'next' on the last line of a program won't hit Byebug::PryProcessor#run,
# which normally handles cleanup.
at_exit do
  PryByebug.current_remote_server.teardown if PryByebug.current_remote_server
end
