# Class: test_wo
#
# This module manages test_wo
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class test_wo {
  
  $wo = hiera_hash("workorder")

  file { 'test_wo':
     path    => '/tmp/test_wo',
     ensure  => file,
     content  => $wo["rfcCi"]["ciName"]
  }

}
