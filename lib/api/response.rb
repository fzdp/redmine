module Api
  module Response
    extend ActiveSupport::Concern
    Res = Struct.new(:message, :data, :success)

    included do
      def success_res(data: nil)
        self.class.success_res(data: data)
      end

      def error_res(message: 'something is wrong')
        self.class.error_res(message: message)
      end
    end

    class_methods do
      def error_res(message: 'something is wrong')
        Res.new(message, nil, false)
      end

      def success_res(data: nil)
        Res.new("ok", data, true)
      end
    end
  end
end