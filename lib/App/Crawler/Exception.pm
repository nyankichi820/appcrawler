package App::Crawler::Exception;
use strict;
use warnings;


package App::Crawler::Exception::AllProxyDeadNoneException;
use base "Error::Simple";

package App::Crawler::Exception::ContentParseException;
use base "Error::Simple";

package App::Crawler::Exception::NetworkException;
use base "Error::Simple";

package App::Crawler::Exception::InvalidContentException;
use base "Error::Simple";

package App::Crawler::Exception::AccessLimitationException;
use base "Error::Simple";

package App::Crawler::Exception::InternalErrorExepction;
use base "Error::Simple";

1;
