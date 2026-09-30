class ApplicationService
  Result = Struct.new(:record, :success?, keyword_init: true) do
    def failure?
      !success?
    end
  end

  private

  def success(record)
    Result.new(record:, success?: true)
  end

  def failure(record)
    Result.new(record:, success?: false)
  end
end
