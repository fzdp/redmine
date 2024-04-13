class ApplicationService
  include Api::Response

  def self.call(*args, &block)
    begin
      new(*args, &block).call
    rescue => e
      error_res(message: e.message.presence || "service error")
    end
  end
end