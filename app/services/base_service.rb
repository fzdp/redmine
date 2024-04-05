class BaseService
  def self.call(*args, &block)
    begin
      new(*args, &block).call
    rescue => e
      error_res(message: e.message.presence || "service error")
    end
  end

  def self.error_res(message: 'something is wrong')
    OpenStruct.new(data: nil, message: message, success: false)
  end

  def error_res(message: 'something is wrong')
    self.class.error_res(message: message)
  end

  def self.success_res(data: nil)
    OpenStruct.new(data: data, message: 'ok', success: true)
  end

  def success_res(data: nil)
    self.class.success_res(data: data)
  end
end