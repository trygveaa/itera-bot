class String
  def camelize
    gsub(/((^\w)|(_\w))/) { $1[-1,1].upcase }
  end
end
