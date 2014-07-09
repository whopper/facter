module Facter
  module Operatingsystem
    class Lsb
      def get_lsbdistcodename
        lsbdistcodename = Facter::Core::Execution.exec("lsb_release -c -s 2>/dev/null")
        unless lsbdistcodename == ""
          lsbdistcodename
        end
      end

      def get_lsbdistid
        lsbdistid = Facter::Core::Execution.exec("lsb_release -i -s 2>/dev/null")
        unless lsbdistid == ""
          lsbdistid
        end
      end

      def get_lsbdistdescription
        lsbdistdescription = Facter::Core::Execution.exec("lsb_release -d -s 2>/dev/null")
        begin
          lsbdistdescription.sub(/^"(.*)"$/,'\1')
        rescue NoMethodError
          nil
        end
      end

      def get_lsbdistrelease
        lsbdistrelease = Facter::Core::Execution.exec("lsb_release -r -s 2>/dev/null")
        unless lsbdistrelease == ""
          lsbdistrelease
        end
      end

      def get_lsbrelease
        lsbrelease = Facter::Core::Execution.exec("lsb_release -v -s 2>/dev/null")
        unless lsbrelease == ""
          lsbrelease
        end
      end

      def get_lsbmajdistrelease
        lsbdistrelease = get_lsbdistrelease
        if /(\d*)\./i =~ lsbdistrelease
          result = $1
        else
          result = lsbdistrelease
        end

        result
      end
    end
  end
end
