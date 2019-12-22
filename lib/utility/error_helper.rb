# encoding: UTF-8

def blderr(file, line, *arg)
  ret = "In #{bn(file)}:#{line}:"
  if arg.size >= 2 then
    method  = arg[0]
    message = arg[1]
    ret += "#{method}: #{message}"
  elsif arg.size >= 1 then
    message = arg[0]
    ret += " #{message}"
  end
  return ret
end

# Explain error
def experr(file, line, e, more_info = "")
  if e.is_a?(StandardError) then
    ret = "Catched at #{bn(file)}:#{line}:#{e.class}:#{e.message}:#{e.inspect}:#{more_info}"
  else
    raise TypeError.new("#{bn(__FILE__)}:#{__LINE__}: " \
                        "e must be a StandardError.")
  end
  return ret
end
