# encoding: UTF-8
class Array

  def to_hash(options = {})
    arr = []
    self.each do |elem|
      if elem.respond_to?("to_hash") then
        arr.push(elem.to_hash(options))
      else
        arr.push(elem)
      end
    end
    return arr
  end

end
