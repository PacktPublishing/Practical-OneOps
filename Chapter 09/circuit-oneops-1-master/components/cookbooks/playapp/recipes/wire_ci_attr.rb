#
#  Helper recipe to populate the dbaas ci attributes
#
#  Author : Jayesh Pise 
#  Copyright WalmartLabs, All rights reserved.


ci = node.workorder.rfcCi.ciAttributes

node.set[:playapp][:http_port] = ci['http_port'].to_i
node.set[:playapp][:app_name] = ci['app_name']
node.set[:playapp][:app_secret] = ci['app_secret']
node.set[:playapp][:app_location] = ci['app_location']

