class String
  # colorization
  def colorize(color_code=30) #defaults to black
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def pink
    colorize(35)
  end
  def cyan
    colorize 36
  end
  def grey
    colorize 37
  end
end
