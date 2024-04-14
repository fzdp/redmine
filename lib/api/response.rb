module Api
  module Response
    extend ActiveSupport::Concern
    Res = Struct.new(:message, :data, :success)

    included do
      def success_res(data: nil)
        self.class.success_res(data: data)
      end

      def error_res(message: 'something is wrong', data: nil)
        self.class.error_res(message: message, data: data)
      end
    end

    class_methods do
      def error_res(message: 'something is wrong', data: nil)
        Res.new(message, data, false)
      end

      def success_res(data: nil)
        Res.new("ok", data, true)
      end
    end
  end
end