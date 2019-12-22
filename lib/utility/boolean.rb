# encoding: UTF-8
# This module behaves as an apparent super class of 
# the TrueClass and FalseClass.
#
# Thanks to http://stackoverflow.com/posts/3028378/revisions

module Boolean
end

class TrueClass
  include Boolean
end

class FalseClass
  include Boolean
end

def bool(val)
  not not val
end

# true.is_a?(Boolean) #=> true
# false.is_a?(Boolean) #=> true
# (1 == 1).is_a?(Boolean) #=> true
# (1 == 2).is_a?(Boolean) #=> true
# #kind_of? works the same.
