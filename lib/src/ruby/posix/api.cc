#include <internal/ruby/api.hpp>
#include <vector>

using namespace std;
using namespace facter::util;

namespace facter { namespace ruby {

    dynamic_library api::find_loaded_library()
    {
        return dynamic_library::find_by_symbol("ruby_init");
    }

    vector<string> api::libruby_config_variables()
    {
        return {"libdir", "archlibdir", "sitearchlibdir"};
    }

}}  // namespace facter::ruby
