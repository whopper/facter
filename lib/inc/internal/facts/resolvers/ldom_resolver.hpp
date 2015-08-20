/**
 * @file
 * Declares the base LDom (Logical Domain) fact resolver.
 */
#pragma once

#include <facter/facts/resolver.hpp>

namespace facter { namespace facts { namespace resolvers {

    /**
     * Responsible for resolving LDom facts.
     */
    struct ldom_resolver : resolver
    {
        /**
         * Constructs the ldom_resolver.
         */
        ldom_resolver();

        /**
         * Called to resolve all facts the resolver is responsible for.
         * @param facts The fact collection that is resolving facts.
         */
        virtual void resolve(collection& facts) override;

        protected:
            /**
             * Represents the resolver's data.
             */
            struct data
            {
                /**
                 * Stores the domain type.
                 */
                std::string domain_type;

                /**
                 * Stores whether the domain is a control domain.
                 */
                std::string control_role;

                /**
                 * Stores whether the domain is an I/O domain.
                 */
                std::string io_role;

                /**
                 * Stores whether the domain is a service domain.
                 */
                std::string service_role;

                /**
                 * Stores whether the domain is a root I/O domain.
                 */
                std::string root_io_role;

                /**
                 * Stores the domain name.
                 */
                std::string domain_name;

                /**
                 * Stores the domain UUID.
                 */
                std::string domain_uuid;

                /**
                 * Stores the network node name of the control domain.
                 */
                std::string domain_control_name;

                /**
                 * Stores the platform serial number.
                 */
                std::string chassis_serial_number;
            };

            /**
             * Collects the resolver data.
             * @param facts The fact collection that is resolving facts.
             * @return Returns the resolver data.
             */
            virtual data collect_data(collection& facts) = 0;
    };

}}}  // namespace facter::facts::resolvers
