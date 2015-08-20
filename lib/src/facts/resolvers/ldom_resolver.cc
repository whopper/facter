#include <internal/facts/resolvers/ldom_resolver.hpp>
#include <facter/facts/collection.hpp>
#include <facter/facts/fact.hpp>
#include <facter/facts/scalar_value.hpp>
#include <facter/facts/map_value.hpp>

using namespace std;
using namespace facter::facts;

namespace facter { namespace facts { namespace resolvers {

    ldom_resolver::ldom_resolver() :
        resolver(
            "ldom",
            {
                fact::ldom,
                fact::ldom_domainrole_impl,
                fact::ldom_domainrole_control,
                fact::ldom_domainrole_io,
                fact::ldom_domainrole_service,
                fact::ldom_domainrole_root,
                fact::ldom_domainname,
                fact::ldom_domainuuid,
                fact::ldom_domaincontrol,
                fact::ldom_domainchassis,
            })

    {
    }

    void ldom_resolver::resolve(collection& facts)
    {

        auto isa = facts.get<string_value>(fact::hardware_isa);
        if (isa && isa->value() != "sparc") {
            return;
        }

        auto data = collect_data(facts);

        auto ldom = make_value<map_value>();
        auto role = make_value<map_value>();
        if (!data.domain_type.empty()) {
            facts.add(fact::ldom_domainrole_impl, make_value<string_value>(data.domain_type, true));
            role->add("impl", make_value<string_value>(move(data.domain_type)));
        }
        if (!data.control_role.empty()) {
            facts.add(fact::ldom_domainrole_control, make_value<string_value>(data.control_role, true));
            role->add("control", make_value<string_value>(move(data.control_role)));
        }
        if (!data.io_role.empty()) {
            facts.add(fact::ldom_domainrole_io, make_value<string_value>(data.io_role, true));
            role->add("io", make_value<string_value>(move(data.io_role)));
        }
        if (!data.service_role.empty()) {
            facts.add(fact::ldom_domainrole_service, make_value<string_value>(data.service_role, true));
            role->add("service", make_value<string_value>(move(data.service_role)));
        }
        if(!data.root_io_role.empty()) {
            facts.add(fact::ldom_domainrole_root, make_value<string_value>(data.root_io_role, true));
            role->add("root", make_value<string_value>(move(data.root_io_role)));
        }
        if (!data.domain_name.empty()) {
            facts.add(fact::ldom_domainname, make_value<string_value>(data.domain_name, true));
            ldom->add("name", make_value<string_value>(move(data.domain_name)));
        }
        if (!data.domain_uuid.empty()) {
            facts.add(fact::ldom_domainuuid, make_value<string_value>(data.domain_uuid, true));
            ldom->add("uuid", make_value<string_value>(move(data.domain_uuid)));
        }
        if (!data.domain_control_name.empty()) {
            facts.add(fact::ldom_domaincontrol, make_value<string_value>(data.domain_control_name, true));
            ldom->add("control_name", make_value<string_value>(move(data.domain_control_name)));
        }
        if (!data.chassis_serial_number.empty()) {
            facts.add(fact::ldom_domainchassis, make_value<string_value>(data.chassis_serial_number, true));
            ldom->add("chassis_serial_number", make_value<string_value>(move(data.chassis_serial_number)));
        }

        if (!role->empty()) {
            ldom->add("role", move(role));
        }

        if (!ldom->empty()) {
            facts.add(fact::ldom, move(ldom));
        }
    }

}}}  // namespace facter::facts
