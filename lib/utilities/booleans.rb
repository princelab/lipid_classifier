class TrueClass
  def to_s
    "1"
  end
  def to_i
    1
  end
  def <=(number)
    self.to_i <= number
  end
  def >(n)
    self.to_i > n
  end
end

class FalseClass
  def to_s
    "0"
  end
  def to_i
    0
  end
  def <=(number)
    self.to_i <= number
  end
  def >(n)
    self.to_i > n
  end
end
