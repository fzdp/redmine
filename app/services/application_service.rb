class ApplicationService
  include Api::Response

  def self.call(*args, &block)
    begin
      new(*args, &block).call
    rescue => e
      p "=============== service error ==========="
      p e.message
      p "=============== backtrace ========"
      puts e.backtrace.join("\n")
      error_res(message: e.message.presence || "service error")
    end
  end
end