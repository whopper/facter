#include <internal/facts/aix/kernel_resolver.hpp>
#include <facter/facts/collection.hpp>
#include <facter/execution/execution.hpp>
#include <sys/utsname.h>

using namespace std;
using namespace facter::execution;

namespace facter { namespace facts { namespace aix {

    kernel_resolver::data kernel_resolver::collect_data(collection& facts)
    {
        data result;
        result.name = "AIX"; // this is an aix-specific implementation anyway

        struct utsname name;
        if (uname(&name) == -1) {
          LOG_WARNING("uname failed: %1% (%2%): kernel facts are unavailable.", strerror(errno), errno);
          return result;
        }

        result.name = name.sysname;
        result.release = name.release;
        result.version = name.version;
        return result;
    }

}}}  // namespace facter::facts::aix
