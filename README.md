# DMX-MAKEFILE #

## INTRODUCTION ## 
DMX is a lightweight, general purpose and reusable makefile targeting GNU
make g++ on LINUX, MinGW on Windows and MSVC. It provides a single makefile
implementation, which utilises one or more user configuration (*.conf) files.

It has the following features:

  - Clean design, comprising entirely a makefile based implementation.
  - Able to build binaries, libraries and shared objects (DLLs on Windows).
  - Does not depend on other tools, such as MSYS, GMSL, Perl etc.
  - Can auto-detect build the platform, including 64 and 32 bit architectures.
  - Provides release and debug targets, and a comprehensive range of build goals.
  - Supports Windows resource compilation.
  - Pre-build, post-build, distribution and install steps.

NOTE. Although compilation with the MSVC toolchain is supported, GNU make
is still needed (the solution does not use NMake).

To call make to build a project, you would use something like:

	`make rebuild CONF=make-main.conf TARG=debug ARCH=64`

NOTE. Use mingw32-make under Windows.

This will call GNU make with the file "makefile", which will be supplied with
the list of options specified.

Or, even just the following will work:

	`make`

In this case, GNU make will use "makefile" as its default, while other options will
use default values (where "make-main.conf" is the default configuration filename).

Source and build directories are expected to reside relative to the makefile,
and would typically include: "src", "obj" and "out" (the names are configurable).
Additionally, external include directories and library search paths can be
specified. NOTE. Pathnames containing spaces are not supported.


## MAKEFILE COMPONENTS ## 
Components include:

* **makefile** : This is the default name of the makefile implementation, and the file to be
called using make (or mingw32-make.exe). This file should NOT be modified. Instead,
a configuration filename should be supplied using the command line variable "CONF".

* **make-main.conf** : This is the name of the default configuration file. This file should be
used as a basis for any project--it is where the build options are specified (it includes
detailed documentation for each option). The file can be re-named, but in this case the
CONF command option must be used to explicitly provide the filename. A complex build
project may comprise multiple instance of these configuration files.

* **make-vars.conf** : An additional file which supplies common values to multiple configurations
within the project, such as the application version number.

* **make-defs.conf** : An additional file allow command arguments to be overridden in order to
modify default behaviour. For example, this can be used to set the default TARG value to
"release" rather than "debug".

Complex projects, comprising multiple modules, may utilise several configuration files with
dependencies. For example, building a binary file may necessitate that a library it links to
is built first.

A typical project may comprise the following makefiles:

  - makefile
  - make-main.conf  (master - make all binaries)
  - make-app.conf   (executable binary)
  - make-lib.conf   (static lib binary)
  - make-so.conf    (shared lib binary - a DLL under MSW)
  - make-vars.conf  (common variables)

The "app" configuration, for example, may also trigger the building of of the lib and so files.
Common variables, such as an application version number, can be specified in make-vars.conf.


## COMMAND USAGE ## 

### Usage: ###

	`make -f makefile [GOALS] CONF=[makeconf] TARG=[release/debug/all] COMP=[gpp/mingw/msvc] ARCH=[64/32/all] CRT=[static/dynamic/all] OPTS=["custom opts"] SRCS=[files]`

### Goals: ###
* all           - DEFAULT. Make and link the output. Calls pre and post-build steps.
* compile       - Make sources but does NOT link or call pre or post-build steps.
* link          - Link (or archive) object files, but does NOT call pre or post-build steps.
* clean         - Clean intermediary object files and output binaries.
* mostlyclean   - Clean intermediary object files, but leave output binaries.
* rebuild       - Equivalent to: clean all.
* dist          - Make and link the output (same as all), then run the create distribution shell script.
* makedirs      - Create object, output and custom directories, but do not compile.
* prebuild      - Perform the pre-build step only.
* postbuild     - Perform the post-build step only.
* run           - Execute the binary output. The OPTS value is used to supply run arguments.
* dbg           - Execute the binary under the debugger. The OPTS value is used to supply run arguments.
* checkconf     - Check the configuration file for errors, otherwise does nothing.
* listvars      - Output important configuration variables.
* listvarsall   - Output all configuration variables, plus internal variables.
* help          - Display usage options.
* version       - Display $(dmx_name) version.
* about         - Display $(dmx_name) about information.

### Target Variables: ###
* CONF : The make configuration filename. If omitted, defaults to: "make-main.conf".
Only, a single value can be supplied, but multiple configurations can be built
by creating a "master" project with multiple dependencies.

* TARG : Build target as either "release" or "debug", or a case variation of.
Use "all" to build both. The default value is "debug".

* COMP : Compiler tool chain. Specify "mingw", "gpp" or "msvc". Under Windows, "gpp"
and "mingw" are equivalent. Ignored under LINUX as always "gpp".

* ARCH : Target architecture, either "32" or "64". Use "all" to build both. The
default is that of the build machine. Although the bit architecture will usually
be detected automatically from the build machine, it may be useful to specify
it explicitly for projects targeting multiple architectures. The value will
automatically be supplied to the compiler using the -m64 and -m32 options.

* CRT : The C runtime library, either "dynamic" or "static". Use "all" to build for
both. The default is dynamic.

* OPTS : Custom options used to select additional custom configuration sections
within a conf file. They are passed during recursive make calls and when calling
dependencies. Additionally, they are supplied as the command arguments when
launching an output binary using the "run" or "dbg" goal.

* SRCS : Specific source file(s) to make. Used only with the "compile" command.

### Examples ###
`make all`
`make all CONF=makelib.conf TARG=debug ARCH=64`
`mingw32-make rebuild CONF=makeapp.conf COMP=msvc CRT=static OPTS="trace test"`


## CONFIGURATION SECTIONS ## 
The following sections outline key areas within the configuration (i.e. make-main.conf).
See the configuration file itself for further information (each parameter is documented).

### Project Configuration ###
This section defines key project information, such as the build name (BUILD_BASENAME)
and build type, which can be a binary file (exe), static library (lib), shared
object (so) or master (mst) type. A shared object build will create an "so" file under LINUX,
and a "DLL" with a corresponding import library under Windows. A master build type
is simply used to build multiple configurations (it generates nothing itself).

### Directory Locations ###
This is where build and source locations are provided, such as the "src", "bin",
"obj" and include directories.

### Source Files ###
Source files are given in this section, and may be expressed in terms of wildcards,
so that new source files are automatically included as they are created. Platform
specific sources, i.e. for LINUX and Windows, can be specified separately. (Note that
the approach is to specify source files, i.e. *.cpp, rather than object output files --
object filenames are derived from their sources).

### Compiler/Linker Options ###
Compiler and linker options are broken down into sections for convenience and
portability. Macro definitions, library dependencies and compiler optimisation flags
are given here.

### Pre/post Build Steps ###
This is where makefile dependencies, along with pre and post build steps are specified.
Additional install and distribution steps may also be given.

### Miscellaneous ###
Finally, a few minor options live here.

See the default "make-main.conf" file for further information.


## PRE-DEFINED VARIABLES ##
The following constants are pre-defined by DMX and are available for use with the configuration
settings below. Do not override. For example, $(targ_arch) can be used to specify an output
directory or filename with a "32" or "64" component according to the target architecture.

* $(OPTS)               - If defined, used to specify multiple options allowing the selection
                        of custom configuration sections.
* $(make_root)          - Fully qualified directory of makefile. Note that this may be different
                        from the working directory.
* $(targ_build)         - Build target derived from TARG input argument. Unlike $(TARG), the
                        value is lowercase and always one of: "release" or "debug" (never "all").
                        Defaults to "debug" if TARG was unspecified.
* $(abbr_build)         - Abbreviation of $(targ_build). Always "rel" or "dbg". For convenience
                        in forming filenames.
* $(targ_arch)          - Target architecture (bits) derived from ARCH input argument. Unlike
                        $(ARCH), the value is always one of: "64" or "32". Defaults to
                        $(sys_arch) if ARCH was unspecified.
* $(targ_xarch)         - A synonym of $(targ_arch). Always "x64" or "x86". For convenience in
                        forming filenames.
* $(targ_crt)           - C runtime target derived from CRT input argument. Always one of: "static"
                        or "dynamic". Defaults to "dynamic" if CRT was unspecified.
* $(ms_crt)             - An MS-style variant of $(targ_crt). Additionally, it is suffixed with
                        "d" for debug target. Possible values: "MT", "MD", "MTd" and "MDd".
* $(sys_arch)           - System architecture. May differ from $(targ_arch). Always "64" or "32".
* $(sys_os)             - System OS type, always "win" or "nix".
* $(sys_vos)            - A variant (synonym) of $(sys_os), always "msw" or "nix".
* $(sys_los)            - Long equivalent of $(sys_os), always "windows" or "linux".
* $(comp_id)            - Compiler toolchain ID. Always one of: "gpp", "mingw" or "msvc".
* $(comp_version)       - Compiler/toolchain version, i.e. "7.1.0".
* $(comp_major)         - Compiler/toolchain major version, i.e. "7".
* $(comp_desc)          - Friendly name for compiler toolchain. I.e. "MinGW g++ 7.1.0".
* $(build_host)         - Hostname of the build platform.
* $(build_date)         - UTC date in ISO-8601 form (i.e. "2018-01-30"). The value is defined
                        when the makefile executes is constant. On Windows, this requires
                        that PowerShell is installed otherwise the value is empty. The value
                        is undefined if the call fails.
* $(build_time)         - UTC time in ISO-8601 form (i.e. "18:41:52Z"). The value is defined
                        when the makefile executes is constant. On Windows, this requires
                        that PowerShell is installed otherwise the value is empty. The value
                        is undefined if the call fails.
* $(build_year)         - Year value extracted from $(build_date).
* $(build_month)        - Month value extracted from $(build_date).
* $(build_day)          - Day value extracted from $(build_date).
* $(build_hour)         - Hour value extracted from $(build_time).
* $(build_minute)       - Minute value extracted from $(build_time).
* $(build_second)       - Second value extracted from $(build_time).
* $(space)              - Literal space character.

### Tool Variables ###
The following "call tools" are available for use in this conf file:

* to-lowercase          - Convert string to lowercase (ASCII only).
                        Example: str_out := $(call to-lowercase,$(str_in))
* to-uppercase          - Convert


## COMMON VARIABLES ## 
An additional configuration file (make-vars.conf) is used to provide a common place to set
custom application name and version variables for your application, along with any other
variables you may wish to declare.
