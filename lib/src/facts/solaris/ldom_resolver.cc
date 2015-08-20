#include <internal/facts/solaris/ldom_resolver.hpp>
#include <leatherman/execution/execution.hpp>
#include <leatherman/util/regex.hpp>

using namespace std;
using namespace facter::facts;
using namespace leatherman::execution;

namespace facter { namespace facts { namespace solaris {

    ldom_resolver::data ldom_resolver::collect_data(collection& facts)
    {

        data result;

        /*
         * Note: `virtinfo` is an uncomitted interface. Should we use it?
         */
        each_line("/usr/sbin/virtinfo", { "-a", "-p"  }, [&](string& line) {
            if (result.domain_type.empty()) {
                re_search(line, boost::regex("DOMAINROLE\\|.*impl=([a-zA-Z]*)"), &result.domain_type);
            }
            if (result.control_role.empty()) {
                re_search(line, boost::regex("DOMAINROLE\\|.*control=([a-zA-Z]*)"), &result.control_role);
            }
            if (result.io_role.empty()) {
                re_search(line, boost::regex("DOMAINROLE\\|.*io=([a-zA-Z]*)"), &result.io_role);
            }
            if (result.service_role.empty()) {
                re_search(line, boost::regex("DOMAINROLE\\|.*service=([a-zA-Z]*)"), &result.service_role);
            }
            if (result.root_io_role.empty()) {
                re_search(line, boost::regex("DOMAINROLE\\|.*root=([a-zA-Z]*)"), &result.root_io_role);
            }
            if (result.domain_name.empty()) {
                re_search(line, boost::regex("DOMAINNAME\\|name=(.*)"), &result.domain_name);
            }
            if (result.domain_uuid.empty()) {
                re_search(line, boost::regex("DOMAINUUID\\|uuid=(.*)"), &result.domain_uuid);
            }
            if (result.domain_control_name.empty()) {
                re_search(line, boost::regex("DOMAINCONTROL\\|name=(.*)"), &result.domain_control_name);
            }
            if (result.chassis_serial_number.empty()) {
                re_search(line, boost::regex("DOMAINCHASSIS\\|serialno=(.*)"), &result.chassis_serial_number);
            }
        });

        return result;
    }

}}}  // namespace facter::facts::solaris
