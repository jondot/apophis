require "apophis/version"
require 'appium_lib'

module Apophis
  # Your code goes here...
  BANNER =<<'EOF'
                            .__    .__.
_____  ______   ____ ______ |  |__ |__| ______
\__  \ \____ \ /  _ \\____ \|  |  \|  |/  ___/
 / __ \|  |_> >  <_> )  |_> >   Y  \  |\___ \
(____  /   __/ \____/|   __/|___|  /__/____  >
     \/|__|          |__|        \/        \/
EOF
end

require 'apophis/dotty_timeout'
require 'apophis/appium_runner'
require 'apophis/genymotion_runner'
require 'apophis/runner'


