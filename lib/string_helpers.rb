class String
  def camelize
    gsub(/((^\w)|(_\w))/) { $1[-1,1].upcase }
  end

  def constantize
    Object.const_get(self.camelize)
  end
end
