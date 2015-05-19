#include <internal/facts/aix/kernel_resolver.hpp>
#include <facter/facts/collection.hpp>
#include <facter/execution/execution.hpp>

using namespace std;
using namespace facter::execution;

namespace facter { namespace facts { namespace aix {
    kernel_resolver::data kernel_resolver::collect_data(collection& facts)
    {
        data result;
        result.name = "AIX"; // this is an aix-specific implementation anyway

        execution::each_line(
            "/usr/bin/oslevel", {"-s"},
            [&](string& line) {
                if(!line.empty()) {
                    result.release = line;
                    return false;
                }
                return true;
            },
            nullptr,
            0);

        result.version = result.release.substr(0, result.release.find('-'));
        return result;
    }
}}}
