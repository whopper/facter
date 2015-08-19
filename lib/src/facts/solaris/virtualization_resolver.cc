#include <internal/facts/solaris/virtualization_resolver.hpp>
#include <facter/facts/vm.hpp>
#include <facter/facts/scalar_value.hpp>
#include <facter/facts/collection.hpp>
#include <facter/facts/fact.hpp>
#include <leatherman/execution/execution.hpp>
#include <leatherman/util/regex.hpp>
#include <leatherman/logging/logging.hpp>
#include <boost/algorithm/string.hpp>
#include <map>

using namespace std;
using namespace facter::facts;
using namespace leatherman::util;
using namespace leatherman::execution;

namespace facter { namespace facts { namespace solaris {

    string virtualization_resolver::get_hypervisor(collection& facts)
    {
        // works for both x86 & sparc.
        bool success;
        string output, none;
        tie(success, output, none) = execute("/usr/bin/zonename");
        if (success && output != "global") {
            return vm::zone;
        }

        auto isa = facts.get<string_value>(fact::hardwareisa);
        if (!isa) {
            return {};
        }

        string guest_of;

        if (isa->value() == "i386") {
            static map<boost::regex, string> virtual_map = {
                {boost::regex("VMware"),     string(vm::vmware)},
                {boost::regex("VirtualBox"), string(vm::virtualbox)},
                {boost::regex("Parallels"),  string(vm::parallels)},
                {boost::regex("KVM"),        string(vm::kvm)},
                {boost::regex("HVM domU"),   string(vm::xen_hardware)},
                {boost::regex("oVirt Node"), string(vm::ovirt)}
            };

            // Use the same timeout as in Facter 2.x
            const uint32_t timeout = 20;
            try {
                each_line(
                    "/usr/sbin/prtdiag",
                    [&](string& line) {
                        for (auto const& it : virtual_map) {
                            if (re_search(line, it.first)) {
                                guest_of = it.second;
                                return false;
                            }
                        }
                        return true;
                    },
                    nullptr,
                    timeout);
            } catch (timeout_exception const&) {
                LOG_WARNING("execution of prtdiag has timed out after %1% seconds.", timeout);
            }
        } else if (isa->value() == "sparc") {
            // Uses hints from
            // http://serverfault.com/questions/153179/how-to-find-out-if-a-solaris-machine-is-virtualized-or-not
            // interface stability is uncommited. Should we use it?
            string role;

            static boost::regex domain_role_root("Domain role:.*(root|guest)");
            each_line("/usr/sbin/virtinfo", {"-a"}, [&] (string& line) {
                    if (re_search(line, domain_role_root, &role)) {
                        if (role != "root") {
                            guest_of = vm::ldom;
                        }
                        return false;
                    }
                    if (line.find("virtinfo can only be run from the global zone") != string::npos) {
                        guest_of = vm::zone;
                        return false;
                    }
                    // virtinfo can alsy reply:
                    // Virtual machines are not supported
                    return true;
            });
        }
        return guest_of;
    }
}}}  // namespace facter::facts::solaris
