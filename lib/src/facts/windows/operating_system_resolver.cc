#include <internal/facts/windows/operating_system_resolver.hpp>
#include <internal/util/regex.hpp>
#include <internal/util/windows/system_error.hpp>
#include <internal/util/windows/wmi.hpp>
#include <internal/util/windows/windows.hpp>
#include <facter/facts/collection.hpp>
#include <leatherman/logging/logging.hpp>
#include <intrin.h>
#include <winnt.h>
#include <Shlobj.h>
#include <map>
#include <boost/filesystem.hpp>

using namespace std;
using namespace facter::util;
using namespace facter::util::windows;
using namespace boost::filesystem;

namespace facter { namespace facts { namespace windows {

    static string get_hardware()
    {
        // IsWow64Process is not available on all supported versions of Windows.
        // Use GetModuleHandle to get a handle to the DLL that contains the function
        // and GetProcAddress to get a pointer to the function if available.
        typedef BOOL (WINAPI *LPFN_ISWOW64PROCESS) (HANDLE, PBOOL);

        BOOL isWow64 = FALSE;
        LPFN_ISWOW64PROCESS fnIsWow64Process = (LPFN_ISWOW64PROCESS)
                GetProcAddress(GetModuleHandleW(L"kernel32"), "IsWow64Process");
        if (nullptr != fnIsWow64Process) {
            if (!fnIsWow64Process(GetCurrentProcess(), &isWow64)) {
                LOG_DEBUG("failure determining whether current process is WOW64, defaulting to false"
                        ": %1%", system_error());
            }
        }

        SYSTEM_INFO sysInfo;
        GetNativeSystemInfo(&sysInfo);

        // The cryptic windows cpu architecture models are documented in these places:
        //   http://source.winehq.org/source/include/winnt.h#L568
        //   http://msdn.microsoft.com/en-us/library/windows/desktop/aa394373(v=vs.85).aspx
        //   http://msdn.microsoft.com/en-us/library/windows/desktop/windows.system.processorarchitecture.aspx
        //   http://linux.derkeiler.com/Mailing-Lists/Kernel/2008-05/msg12924.html (anything over 6 is still i686)
        // Also, arm and neutral are included because they are valid for the upcoming
        // windows 8 release.  --jeffweiss 23 May 2012
        auto archLevel = (sysInfo.wProcessorLevel > 5) ? 6 : sysInfo.wProcessorLevel;
        switch (sysInfo.wProcessorArchitecture) {
            case PROCESSOR_ARCHITECTURE_NEUTRAL:        return "neutral";
            case PROCESSOR_ARCHITECTURE_IA32_ON_WIN64:  return "i686";
            case PROCESSOR_ARCHITECTURE_AMD64:          return isWow64 ? "i" + to_string(archLevel) + "86" : "x64";
            case PROCESSOR_ARCHITECTURE_MSIL:           return "msil";
            case PROCESSOR_ARCHITECTURE_ALPHA64:        return "alpha64";
            case PROCESSOR_ARCHITECTURE_IA64:           return "ia64";
            case PROCESSOR_ARCHITECTURE_ARM:            return "arm";
            case PROCESSOR_ARCHITECTURE_SHX:            return "shx";
            case PROCESSOR_ARCHITECTURE_PPC:            return "powerpc";
            case PROCESSOR_ARCHITECTURE_ALPHA:          return "alpha";
            case PROCESSOR_ARCHITECTURE_MIPS:           return "mips";
            case PROCESSOR_ARCHITECTURE_INTEL:          return "i" + to_string(archLevel) + "86";
            default: return "unknown";  // PROCESSOR_ARCHITECTURE_UNKNOWN
        }
    }

    static string get_architecture(string const& hardware)
    {
        // For most, the architecture is the same as the model.
        // For others /(i[3456]86|pentium)/, use x86
        if (re_search(hardware, boost::regex("i[3456]86|pentium"))) {
            return "x86";
        }
        return hardware;
    }

    static string get_system32()
    {
        // When facter is a 32-bit process running on 64-bit windows (such as in a 32-bit puppet installation that
        // includes native facter), system32 points to 32-bit executables; Windows invisibly redirects it. It also
        // provides a link at %SYSTEMROOT%\sysnative for the 64-bit versions. Return the system path where OS-native
        // executables can be found.
        TCHAR szPath[MAX_PATH];
        if (!SUCCEEDED(SHGetFolderPath(NULL, CSIDL_WINDOWS, NULL, 0, szPath))) {
            LOG_DEBUG("error finding SYSTEMROOT: %1%", system_error());
        }

        auto pathNative = path(szPath) / "sysnative";
        boost::system::error_code ec;
        if (is_directory(pathNative, ec)) {
            return pathNative.string();
        }

        LOG_TRACE("sysnative path does not exist");
        auto path32 = path(szPath) / "system32";
        return path32.string();
    }

    operating_system_resolver::operating_system_resolver(shared_ptr<wmi> wmi_conn) :
        resolvers::operating_system_resolver(),
        _wmi(move(wmi_conn))
    {
    }

    operating_system_resolver::data operating_system_resolver::collect_data(collection& facts)
    {
        // Default to the base implementation
        data result = resolvers::operating_system_resolver::collect_data(facts);

        result.hardware = get_hardware();
        result.architecture = get_architecture(result.hardware);
        result.win.system32 = get_system32();

        auto lastDot = result.release.rfind('.');
        if (lastDot == string::npos) {
            return result;
        }

        auto vals = _wmi->query(wmi::operatingsystem, {wmi::producttype, wmi::othertypedescription});
        if (vals.empty()) {
            return result;
        }

        // Override default release with Windows release names
        auto version = result.release.substr(0, lastDot);
        bool consumerrel = (wmi::get(vals, wmi::producttype) == "1");
        if (version == "6.4") {
            result.release = consumerrel ? "10" : result.release;
        } else if (version == "6.3") {
            result.release = consumerrel ? "8.1" : "2012 R2";
        } else if (version == "6.2") {
            result.release = consumerrel ? "8" : "2012";
        } else if (version == "6.1") {
            result.release = consumerrel ? "7" : "2008 R2";
        } else if (version == "6.0") {
            result.release = consumerrel ? "Vista" : "2008";
        } else if (version == "5.2") {
            if (consumerrel) {
                result.release = "XP";
            } else {
                result.release = (wmi::get(vals, wmi::othertypedescription) == "R2") ? "2003 R2" : "2003";
            }
        }

        return result;
    }

    tuple<string, string> operating_system_resolver::parse_release(string const& name, string const& release) const
    {
        return make_tuple(release, string());
    }

}}}  // namespace facter::facts::windows
