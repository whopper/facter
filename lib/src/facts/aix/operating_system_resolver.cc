#include <internal/facts/aix/operating_system_resolver.hpp>
#include <internal/util/regex.hpp>
#include <facter/facts/os.hpp>
#include <facter/execution/execution.hpp>

#include <sstream>
#include <algorithm>

using namespace std;
namespace execution=facter::execution;

string getattr(string object, string field)
{
    string result;
    execution::each_line(
        "/usr/sbin/lsattr", {"-El", object, "-a", field},
        [&](string& line) {
            if(!line.empty()) {
                vector<string> tokens;
                istringstream iss(line);
                // istream_iterator is a great way to tokenize your life
                copy(istream_iterator<string>(iss),
                     istream_iterator<string>(),
                     back_inserter(tokens));
                result = tokens[1];
                return false;
            }
            return true;
        },
        nullptr,
        0);

    return result;
}

namespace facter { namespace facts { namespace aix {
    operating_system_resolver::data operating_system_resolver::collect_data(collection& facts)
    {
        // Default to the base implementation
        auto result = posix::operating_system_resolver::collect_data(facts);
        result.architecture = getattr("proc0", "type");
        result.hardware = getattr("sys0", "modelname");
        return result;
    }
}}}
