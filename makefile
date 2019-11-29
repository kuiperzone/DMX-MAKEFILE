#############################################################################
# PROJECT   : DMX-MAKEFILE
# COPYRIGHT : Andy Thomas (C) 2019
# WEB URL   : https://kuiper.zone
# LICENSE 	: MIT
#############################################################################

#############################################################################
# MAKE IMPLEMENTATION FILE - DO NOT MODIFY
# To configure the project, modify "make-main.conf" and set the option
# variables accordingly. For information, see "makefile.readme".
#############################################################################

ifndef MAKECMDGOALS
MAKECMDGOALS := all
endif

.DELETE_ON_ERROR:
#MAKEFLAGS += --warn-undefined-variables

##################################################
# 1. DMX CONSTANTS
##################################################

################################
# 1a. ABOUT DMX
################################
dmx_version := 7.0
dmx_major := 7
dmx_name := DMX-MAKEFILE
dmx_description := X-platform make system
dmx_copyright := Copyright (c) Andy Thomas 2016-19

################################
# 1b. COMMON TOOLS
################################

# Literal space
space :=
space +=

# Portable ASCII case conversions (must be on single line).
# NB. Use reference assignment for commands taking $1 variable
to-lowercase = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))
to-uppercase = $(subst a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst f,F,$(subst g,G,$(subst h,H,$(subst i,I,$(subst j,J,$(subst k,K,$(subst l,L,$(subst m,M,$(subst n,N,$(subst o,O,$(subst p,P,$(subst q,Q,$(subst r,R,$(subst s,S,$(subst t,T,$(subst u,U,$(subst v,V,$(subst w,W,$(subst x,X,$(subst y,Y,$(subst z,Z,$1))))))))))))))))))))))))))

################################
# 1c. MAKE ROOT
################################

# Derive fully qualified path to makefile (not the working directory).
_make_filename := $(lastword $(MAKEFILE_LIST))
make_root := $(dir $(abspath $(_make_filename)))

################################
# 1d. SYSTEM ARCHITECTURE
################################

# Automatically detect using ComSpec variable
# to distinguish between Windows and LINUX.
ifdef ComSpec

# WINDOWS
# Not set with MSYS in the path.
SHELL := $(ComSpec)

sys_os := win
sys_vos := msw
sys_los := windows

ifeq ($(PROCESSOR_ARCHITECTURE), AMD64)
sys_arch := 64
else ifeq ($(PROCESSOR_ARCHITECTURE), x86)
sys_arch := 32
endif # AMD64

# Detect MSVC cross-compiler variables
ifeq ($(Platform), x64)
sys_arch := 64
_def_msvc := 1
else ifeq ($(Platform), x86)
sys_arch := 32
_def_msvc := 1
endif # Platform

else

# LINUX
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

sys_os := nix
sys_vos := nix
sys_los := linux

_temp := $(shell uname -m)

ifeq ($(_temp), x86_64)
sys_arch := 64
endif # x86_64
ifeq ($(_temp), i386)
sys_arch := 32
endif # i386
ifeq ($(_temp), i686)
sys_arch := 32
endif # i686

endif # !ComSpec

# Default sys_arch to 64
ifndef sys_arch
sys_arch := 64
CONF_WARN := Could not detect system arch (default 64-bit) : $(PROCESSOR_ARCHITECTURE)
endif

################################
# 1c. INCLUDE DEFAULTS
################################

# Default overrides.
# Do this after sys_arch, but
# before we handle arg inputs.
include $(make_root)/make-defs.conf

################################
# 1e. TARGET
################################

# Provide default and case variants
ifndef TARG
TARG := debug
endif

targ_build := $(call to-lowercase,$(TARG))

# Multi-target
ifeq ($(targ_build), all)
_multi_target := 1
_recursive_make := 1
targ_build := debug
endif

# Abbreviated target
ifeq ($(targ_build), release)
abbr_build := rel
else ifeq ($(targ_build), debug)
abbr_build := dbg
else
CONF_ERROR := Invalid TARG value
_error_info := You must specify release, debug or all
endif

################################
# 1d. BUILD ARCH
################################

# Set default ARCH
# Also allow variant x64/x86 input
ifndef ARCH
ARCH := $(sys_arch)
endif

ifeq ($(ARCH), 64)
targ_arch := 64
else ifeq ($(ARCH), x64)
targ_arch := 64
else ifeq ($(ARCH), 32)
targ_arch := 32
else ifeq ($(ARCH), x86)
targ_arch := 32
else
targ_arch := $(call to-lowercase,$(ARCH))
endif

# Override for "all"
ifeq ($(targ_arch), all)
_multi_arch := 1
_recursive_make := 1
targ_arch := $(sys_arch)
endif

# Variant name
# NB. We check later if targ_xarch is defined
ifeq ($(targ_arch), 64)
targ_xarch := x64
else ifeq ($(targ_arch), 32)
targ_xarch := x86
else
CONF_ERROR := Invalid ARCH value
_error_info := You must specify 64, 32 or all
endif

################################
# 1d. BUILD CRT
################################

# Set default CRT
# Also allow variant d/s input
ifndef CRT
CRT := dynamic
endif

targ_crt := $(call to-lowercase,$(CRT))

ifeq ($(targ_crt), d)
targ_crt := dynamic
else ifeq ($(targ_crt), s)
targ_crt := static
else ifeq ($(targ_crt), all)
_multi_crt := 1
_recursive_make := 1
targ_crt := dynamic
endif

# Abbreviated name
ifeq ($(targ_crt), dynamic)
ms_crt := MD
else ifeq ($(targ_crt), static)
ms_crt := MT
else
CONF_ERROR := Invalid CRT value
_error_info := You must specify dynamic, static or all
endif

ifeq ($(targ_build), debug)
_temp := $(ms_crt)
ms_crt := $(_temp)d
endif

################################
# 1e. SELECT TOOL CHAIN
################################

# LINUX g++
ifeq ($(sys_os), nix)

comp_id := gpp

# Use dual arg to be sure of full version as changed between g++ releases
comp_version := $(shell g++ -dumpfullversion -dumpversion)
comp_desc := g++ $(comp_version)

endif # nix

# WINDOWS
ifeq ($(sys_os), win)

_temp := $(call to-lowercase,$(COMP))

ifeq ($(_temp), mingw)
comp_id := mingw
else ifeq ($(_temp), g++)
comp_id := mingw
else ifeq ($(_temp), gpp)
comp_id := mingw
else ifeq ($(_temp), msvc)
comp_id := msvc
else ifeq ($(_temp),)
comp_id := mingw
ifdef _def_msvc
comp_id := msvc
endif # _def_tcid
endif # _temp

# MINGW
ifeq ($(comp_id), mingw)
# Use dual arg to be sure of full version as changed between g++ releases
comp_version := $(shell g++.exe -dumpfullversion -dumpversion)
comp_desc := MinGW g++ $(comp_version)
else ifeq ($(comp_id), msvc)
comp_version := $(VSCMD_VER)
comp_desc := MSVC $(comp_version)
endif # mingw

endif # win

# Check defined
ifndef comp_id
CONF_ERROR := Invalid COMP value
_error_info := You must specify g++, mingw or msvc
endif

ifndef comp_version
CONF_WARN := Could not detect compiler version
comp_version := x
endif

# Derive major
_temp := $(subst .,$(space), $(comp_version))
comp_major := $(firstword $(_temp))

################################
# 1f. SHELL TOOLS
################################

ifeq ($(sys_os), nix)

# LINUX
build_host := $(shell hostname)

# Timestamp - parsed below
_timestamp := $(strip $(shell date -u "+%Y %m %d %H %M %S"))

# Internal (ref =)
_shell_rm = rm -f $1
_shell_md = mkdir -p $1
_shell_feed = echo

# Shell quote to wrap echo output on LINUX.
# Preserves multiples spaces and other characters.
_shqt := "

# No output. Use echo $(_null_out)
_null_out :=

endif # nix

ifeq ($(sys_os), win)

# WINDOWS
build_host := $(shell hostname)

# Timestamp - parsed below
_timestamp := $(strip $(shell powershell Get-Date ([datetime]::UtcNow) -UFormat \"%Y %m %d %H %M %S\"))

# Internal (ref =)
_shell_rm = del $(subst /,\, $1)
_shell_md = mkdir $(subst /,\, $1)
_shell_feed = echo.

# Shell quote not needed on MSW
_shqt :=

# Blank line (or no line). Use echo $(_null_out)
# NB. We cannot use an empty string as it
# results in "ECHO OFF" message on Windows.
_null_out := off

endif # win

# Parse timestamp
ifeq ($(words $(_timestamp)),6)
build_year := $(word 1,$(_timestamp))
build_month := $(word 2,$(_timestamp))
build_day := $(word 3,$(_timestamp))
build_hour := $(word 4,$(_timestamp))
build_minute := $(word 5,$(_timestamp))
build_second := $(word 6,$(_timestamp))
build_date := $(build_year)-$(build_month)-$(build_day)
build_time := $(build_hour):$(build_minute):$(build_second)Z
endif # words _timestamp


##################################################
# 2. IMPORT USER CONFIGURATION
##################################################

################################
# 2a. IMPORT CONF FILE
################################

# Default if omitted
ifndef CONF
CONF := make-main.conf
endif

# Check if it exists in $(make_root), otherwise it
# may be relative to the work directory, or absolute.
_conf_path := $(make_root)$(CONF)
ifeq ($(wildcard $(_conf_path)),)
_conf_path := $(CONF)
endif

# Make real (must exist)
_conf_path := $(realpath $(_conf_path))

# Include if exists
ifeq ($(words $(_conf_path)), 1)

include $(_conf_path)

else

CONF_ERROR := Invalid CONF: $(CONF)
_error_info := File does not exist or is invalid filename

endif # _conf_path 1

################################
# 2b. ENSURE DIRECTORIES
################################
_obj_dir := $(abspath $(OBJ_DIR))/
_out_dir := $(abspath $(OUT_DIR))/
_src_root := $(abspath $(SRC_ROOT))/

################################
# 2b. SELECT FILE PATHS
################################

ifeq ($(sys_os), nix)

# LINUX
_inc_dirs := $(abspath $(INC_COMMON_DIRS)) $(abspath $(INC_NIX_DIRS))
_src_files := $(SRC_COMMON_FILES) $(SRC_NIX_FILES)
_res_files :=

_shell_prebuild := $(PREBUILD_NIX)
_shell_postbuild := $(POSTBUILD_NIX)
_shell_distbuild := $(DISTBUILD_NIX)

else

# WINDOWS
_inc_dirs := $(abspath $(INC_COMMON_DIRS)) $(abspath $(INC_WIN_DIRS))
_src_files := $(SRC_COMMON_FILES) $(SRC_WIN_FILES)
_res_files := $(RC_WIN_FILES)

_shell_prebuild := $(PREBUILD_WIN)
_shell_postbuild := $(POSTBUILD_WIN)
_shell_distbuild := $(DISTBUILD_WIN)

endif # nix

# Override source files with
# those given over command line
ifdef SRCS
_src_files := $(SRCS)
_res_files :=
endif

# Remove full path parts, leaving only relative
# from $(_src_root). We need this if a wildcard
# was used to define the files, and we need our
# files to be cleanly relative to $(_src_root).
_unique_part := _uNique7634_
_temp := $(subst //,/, $(_src_files))
_temp := $(_temp:%=$(_unique_part)%)
_temp := $(subst $(_unique_part)$(_src_root),, $(_temp))
_src_files := $(strip $(subst $(_unique_part),, $(_temp)))

_temp := $(subst //,/, $(_res_files))
_temp := $(_temp:%=$(_unique_part)%)
_temp := $(subst $(_unique_part)$(_src_root),, $(_temp))
_res_files := $(strip $(subst $(_unique_part),, $(_temp)))

################################
# 2c. CHECK FOR ERRORS
################################

# Check versions match
ifneq ($(dmx_major), $(dmx_confmajor))
CONF_ERROR := Invalid configuration file format
_error_info := Configuration file format is not version $(dmx_major)
endif # dmx_major

# Project type
ifndef CONF_ERROR
ifneq ($(BUILD_TYPE), exe)
ifneq ($(BUILD_TYPE), lib)
ifneq ($(BUILD_TYPE), so)
ifneq ($(BUILD_TYPE), mst)
CONF_ERROR := Invalid BUILD_TYPE: $(BUILD_TYPE)
_error_info := Specify "exe", "lib", "so" or "mst" only
endif # mst
endif # so
endif # lib
endif # exe
endif # !CONF_ERROR

# Look for multiple items in BUILD_BASENAME
ifndef CONF_ERROR
ifneq ($(words $(BUILD_BASENAME)), 1)
CONF_ERROR := Invalid BUILD_BASENAME: $(BUILD_BASENAME)
_error_info := The value is unspecified or contains multiple items
endif # dmx_confmajor
endif # !CONF_ERROR

# Look for multiple items in SRC_ROOT
ifndef CONF_ERROR
ifneq ($(BUILD_TYPE), mst)
ifneq ($(words $(_src_root)), 1)
CONF_ERROR := Invalid SRC_ROOT directory: $(_src_root)
_error_info := Either the value is unspecified or contains multiple items
endif # SRC_ROOT
endif # mst
endif # !CONF_ERROR

# Look for multiple items in OUT_DIR
ifndef CONF_ERROR
ifneq ($(BUILD_TYPE), mst)
ifneq ($(words $(_out_dir)), 1)
CONF_ERROR := Invalid OUT_DIR directory: $(_out_dir)
_error_info := Either the value is unspecified or contains multiple items
endif # OUT_DIR
endif # mst
endif # !CONF_ERROR

# Look for multiple items in OBJ_DIR
ifndef CONF_ERROR
ifneq ($(BUILD_TYPE), mst)
ifneq ($(words $(_obj_dir)), 1)
CONF_ERROR := Invalid OBJ_DIR directory: $(_obj_dir)
_error_info := Either the value is unspecified or contains multiple items
endif # OBJ_DIR
endif # mst
endif # !CONF_ERROR

# Source exists?
ifndef CONF_ERROR
ifneq ($(BUILD_TYPE), mst)
ifeq ($(wildcard $(_src_root)),)
CONF_ERROR := Invalid SRC_ROOT directory: $(_src_root)
_error_info := The directory does not exist
endif # SRC_ROOT
endif # mst
endif # !CONF_ERROR

# Prevent sources in master
ifndef CONF_ERROR
ifeq ($(BUILD_TYPE), mst)
ifneq ($(strip $(_src_files)$(_res_files)),)
CONF_ERROR := Master (mst) project cannot specify source or resource files
endif # _strip files
endif # mst
endif # !CONF_ERROR

# Prevent pre/post builds in master
ifndef CONF_ERROR
ifeq ($(BUILD_TYPE), mst)
ifneq ($(strip $(_shell_prebuild)$(_shell_postbuild)),)
CONF_ERROR := Master (mst) project cannot specify pre-build or post-build steps
endif # strip files
endif # mst
endif # !CONF_ERROR

# Check for non-existing source files.
ifndef CONF_ERROR
ifneq ($(BUILD_TYPE), mst)
_check_files := $(_src_files) $(_res_files)
_check_files := $(_check_files:%=$(_src_root)%)
_temp := $(wildcard $(_check_files))
_temp := $(filter-out $(_temp), $(_check_files))
ifneq ($(_temp),)
CONF_ERROR := Invalid source filename(s)
_error_info := Following files do not exist: $(_temp)
endif # _temp
endif # mst
endif # !CONF_ERROR

# Check we are not trying run a library
ifndef CONF_ERROR
ifneq ($(filter run, $(MAKECMDGOALS)),)
ifneq ($(BUILD_TYPE), exe)
CONF_ERROR := Cannot run a non-executing binary
_error_info := Project build type is: $(BUILD_TYPE)
endif # BUILD_TYPE
endif # run
endif # !CONF_ERROR

################################
# 2d. WARNINGS
################################
_cxx_temp := $(CXX_NIX_REL_FLAGS) $(CXX_NIX_DBG_FLAGS) $(CXX_MSW_REL_FLAGS) $(CXX_MSW_DBG_FLAGS)
_lnk_temp := $(LNK_NIX_REL_FLAGS) $(LNK_NIX_DBG_FLAGS) $(LNK_MSW_REL_FLAGS) $(LNK_MSW_DBG_FLAGS)

ifndef CONF_WARN
_temp := $(_cxx_temp) $(_lnk_temp)
ifneq ($(filter -m32,$(_temp)),)
CONF_WARN := Configuration overrides -m32 compiler flag
else ifneq ($(filter -m64,$(_temp)),)
CONF_WARN := Configuration overrides -m64 compiler flag
endif # filter
endif # !CONF_WARN

ifndef CONF_WARN
ifneq ($(filter -shared,$(_lnk_temp)),)
CONF_WARN := Configuration overrides -shared linker flag
else ifneq ($(filter -static,$(_lnk_temp)),)
CONF_WARN := Configuration overrides -static linker flag
endif # filter
endif # !CONF_WARN


##################################################
# 3. ASSEMBLE BUILD COMMANDS
##################################################

################################
# 3a. COMMON
################################
ifndef _recursive_make
ifneq ($(BUILD_TYPE), mst)

# Default does nothing - see MSVC
_to-wpath = $1

_temp := o

ifeq ($(comp_id), msvc)
_temp := obj
endif

# Object files extensions
# i.e. Source "main.cpp" -> "main.cpp.gpp-MTd32.o" etc
_obj_fext := .$(comp_id)-$(ms_crt)$(targ_arch).$(_temp)
_res_fext := .$(comp_id)-$(ms_crt)$(targ_arch).res.$(_temp)

# Final object files
_obj_files := $(_src_files:%=$(_obj_dir)%$(_obj_fext))
_obj_files += $(_res_files:%=$(_obj_dir)%$(_res_fext))

endif # !BUILD_TYPE mst

# Custom
_temp := $(wildcard $(CUSTOM_DIRS))
_mkdir_custom := $(filter-out $(_temp), $(CUSTOM_DIRS))

# We use a dummy rule to call dependencies
_dep_dummy_fext := _mkdep_dummy
_dep_makes := $(MAKECONF_DEPS:%=%$(_dep_dummy_fext))

endif # _recursive_make

################################
# 3b. g++
################################

ifeq ($(comp_id), gpp)

# Runtime
_debugger_exe := gdb

# Output extensions & prefix
_bin_ext :=
_lib_ext := .a
_lib_pfx := lib
_so_ext  := .so
_so_pfx  := lib

ifeq ($(targ_crt), static)
_lnk_crt := -static
endif

_macro_defs := $(MACRO_COMMON_DEFS) $(MACRO_GPP_DEFS)

# Need to add explicitly as %=-D% inserts between spaces
_about_defs :=

ifdef ABOUT_NAME
_about_defs += -DABOUT_NAME="\"$(ABOUT_NAME)\""
endif
ifdef ABOUT_VERSION
_about_defs += -DABOUT_VERSION="\"$(ABOUT_VERSION)\""
endif
ifdef ABOUT_VENDOR
_about_defs += -DABOUT_VENDOR="\"$(ABOUT_VENDOR)\""
endif
ifdef ABOUT_COPYRIGHT
_about_defs += -DABOUT_COPYRIGHT="\"$(ABOUT_COPYRIGHT)\""
endif

_extlib_dirs := $(abspath $(EXTLIB_COMMON_DIRS)) $(abspath $(EXTLIB_GPP_DIRS))
_extlib_names := $(EXTLIB_COMMON_NAMES) $(EXTLIB_GPP_NAMES)

ifeq ($(targ_build), release)
_cxx_flags := -m$(targ_arch) $(CXX_GPP_REL_FLAGS) $(_inc_dirs:%=-I%) $(_macro_defs:%=-D%) $(_about_defs)
_lnk_flags := -m$(targ_arch) $(_lnk_crt) $(LNK_GPP_REL_FLAGS) $(_extlib_dirs:%=-L%) $(_extlib_names:%=-l%)
else
_cxx_flags := -m$(targ_arch) $(CXX_GPP_DBG_FLAGS) $(_inc_dirs:%=-I%) $(_macro_defs:%=-D%) $(_about_defs)
_lnk_flags := -m$(targ_arch) $(_lnk_crt) $(LNK_GPP_DBG_FLAGS) $(_extlib_dirs:%=-L%) $(_extlib_names:%=-l%)
endif

# Compile command - to append output
_compile_cmd := g++ -c $(_cxx_flags) -o

# BINARY
ifeq ($(BUILD_TYPE), exe)
_targ_out := $(_out_dir)$(BUILD_BASENAME)$(_bin_ext)
_link_cmd := g++ $(_obj_files) $(_lnk_flags) -o $(_targ_out)
endif # exe

# STATIC LIB
ifeq ($(BUILD_TYPE), lib)
_targ_out := $(_out_dir)$(_lib_pfx)$(BUILD_BASENAME)$(_lib_ext)
_link_cmd := ar -rc $(_targ_out) $(_obj_files)
_ranlib_cmd := ranlib $(_targ_out)
endif # lib

# SHARED OBJECT (DLL)
ifeq ($(BUILD_TYPE), so)
_targ_out := $(_out_dir)$(_so_pfx)$(BUILD_BASENAME)$(_so_ext)
_link_cmd := g++ -shared $(_obj_files) $(_lnk_flags) -o $(_targ_out)
ifdef NIX_SONAME
_link_cmd += -Wl,-soname,$(NIX_SONAME)
endif # NIX_SONAME
endif # lib

endif # g++

################################
# 3c. MinGW
################################

ifeq ($(comp_id), mingw)

# Runtime
_debugger_exe := gdb.exe

# Output extensions & prefixes
_bin_ext := .exe
_lib_ext := .a
_lib_pfx := lib
_so_ext  := .dll
_so_pfx :=

ifeq ($(targ_crt), static)
_lnk_crt := -static
endif

_macro_defs := $(MACRO_COMMON_DEFS) $(MACRO_MINGW_DEFS)

# Need to add explicitly as %=-D% inserts between spaces
_about_defs :=

ifdef ABOUT_NAME
_about_defs += -DABOUT_NAME="\"$(ABOUT_NAME)\""
endif
ifdef ABOUT_VERSION
_about_defs += -DABOUT_VERSION="\"$(ABOUT_VERSION)\""
endif
ifdef ABOUT_VENDOR
_about_defs += -DABOUT_VENDOR="\"$(ABOUT_VENDOR)\""
endif
ifdef ABOUT_COPYRIGHT
_about_defs += -DABOUT_COPYRIGHT="\"$(ABOUT_COPYRIGHT)\""
endif

_extlib_dirs := $(abspath $(EXTLIB_COMMON_DIRS)) $(abspath $(EXTLIB_MINGW_DIRS))
_extlib_names := $(EXTLIB_COMMON_NAMES) $(EXTLIB_MINGW_NAMES)

ifeq ($(targ_build), release)
_cxx_flags := -m$(targ_arch) $(CXX_MINGW_REL_FLAGS) $(_inc_dirs:%=-I%) $(_macro_defs:%=-D%) $(_about_defs)
_lnk_flags := -m$(targ_arch) $(_lnk_crt) $(LNK_MINGW_REL_FLAGS) $(_extlib_dirs:%=-L%) $(_extlib_names:%=-l%)
_res_flags := $(RES_MINGW_REL_FLAGS)
else
_cxx_flags := -m$(targ_arch) $(CXX_MINGW_DBG_FLAGS) $(_inc_dirs:%=-I%) $(_macro_defs:%=-D%) $(_about_defs)
_lnk_flags := -m$(targ_arch) $(_lnk_crt) $(LNK_MINGW_DBG_FLAGS) $(_extlib_dirs:%=-L%) $(_extlib_names:%=-l%)
_res_flags := $(RES_MINGW_DBG_FLAGS)
endif

# Compile command - to append output
_compile_cmd := g++.exe -c $(_cxx_flags) -o
_windres_cmd := windres.exe -O coff $(_res_flags) -o

# BINARY
ifeq ($(BUILD_TYPE), exe)
_targ_out := $(_out_dir)$(BUILD_BASENAME)$(_bin_ext)
_link_cmd := g++ $(_obj_files) $(_lnk_flags) -o $(_targ_out)
endif # exe

# STATIC LIB
ifeq ($(BUILD_TYPE), lib)
_targ_out := $(_out_dir)$(_lib_pfx)$(BUILD_BASENAME)$(_lib_ext)
_link_cmd := ar -rc $(_targ_out) $(_obj_files)
_ranlib_cmd := ranlib $(_targ_out)
endif # lib

# SHARED OBJECT (DLL)
ifeq ($(BUILD_TYPE), so)
_targ_out := $(_out_dir)$(_so_pfx)$(BUILD_BASENAME)$(_so_ext)
_msw_import_lib := $(dir $(_targ_out))$(_lib_pfx)$(_so_pfx)$(BUILD_BASENAME)$(_lib_ext)
_link_cmd := g++ -shared $(_obj_files) $(_lnk_flags) -o $(_targ_out)
_link_cmd += -Wl,--out-implib,$(_msw_import_lib)
endif # lib

endif # mingw

################################
# 3d. MSVC
################################

ifeq ($(comp_id), msvc)

_to-wpath = $(subst /,\,$1)

# Runtime
_debugger_exe := cdb.exe

# Output extensions & prefixes
_bin_ext := .exe
_lib_ext := .lib
_lib_pfx :=
_so_ext  := .dll
_exp_ext  := .exp
_so_pfx :=

_macro_defs := $(MACRO_COMMON_DEFS) $(MACRO_MSVC_DEFS)

# Need to add explicitly as %=-D% inserts between spaces
_about_defs :=

ifdef ABOUT_NAME
_about_defs += /D ABOUT_NAME="\"$(ABOUT_NAME)\""
endif
ifdef ABOUT_VERSION
_about_defs += /D ABOUT_VERSION="\"$(ABOUT_VERSION)\""
endif
ifdef ABOUT_VENDOR
_about_defs += /D ABOUT_VENDOR="\"$(ABOUT_VENDOR)\""
endif
ifdef ABOUT_COPYRIGHT
_about_defs += /D ABOUT_COPYRIGHT="\"$(ABOUT_COPYRIGHT)\""
endif

# Must swap separators
_mvc_inc_dirs := $(subst /,\, $(_inc_dirs))
_mvc_obj_files := $(subst /,\, $(_obj_files))
_extlib_dirs := $(subst /,\, $(abspath $(EXTLIB_COMMON_DIRS)) $(abspath $(EXTLIB_MSVC_DIRS)))
_extlib_names := $(EXTLIB_COMMON_NAMES) $(EXTLIB_MSVC_NAMES)

ifeq ($(targ_build), release)
_cxx_flags :=  /c /nologo /$(ms_crt) $(CXX_MSVC_REL_FLAGS) $(_mvc_inc_dirs:%=/I%) $(_macro_defs:%=/D%) $(_about_defs)
_arc_flags := /NOLOGO /MACHINE:$(call to-lowercase,$(targ_xarch))
_lnk_flags := $(_arc_flags) $(LNK_MSVC_REL_FLAGS) $(_extlib_dirs:%=/LIBPATH:%) $(_extlib_names:%=%$(_lib_ext))
_res_flags := $(RES_MINGW_REL_FLAGS)
else
_cxx_flags :=  /c /nologo /$(ms_crt) $(CXX_MSVC_DBG_FLAGS) $(_mvc_inc_dirs:%=/I%) $(_macro_defs:%=/D%) $(_about_defs)
_arc_flags := /NOLOGO /MACHINE:$(call to-lowercase,$(targ_xarch))
_lnk_flags := $(_arc_flags) $(LNK_MSVC_DBG_FLAGS) $(_extlib_dirs:%=/LIBPATH:%) $(_extlib_names:%=%$(_lib_ext))
_res_flags := $(RES_MINGW_DBG_FLAGS)
endif


# Compile command - to append output
_compile_cmd := cl.exe $(_cxx_flags) /Fo
_windres_cmd := rc.exe $(_res_flags) /fo

# BINARY
ifeq ($(BUILD_TYPE), exe)
_targ_out := $(_out_dir)$(BUILD_BASENAME)$(_bin_ext)
_link_cmd := link.exe $(_mvc_obj_files) $(_lnk_flags) /OUT:$(subst /,\,$(_targ_out))
endif # exe

# STATIC LIB
ifeq ($(BUILD_TYPE), lib)
_targ_out := $(_out_dir)$(_lib_pfx)$(BUILD_BASENAME)$(_lib_ext)
_link_cmd := lib.exe $(_mvc_obj_files) $(_arc_flags) /OUT:$(subst /,\,$(_targ_out))
endif # lib

# SHARED OBJECT (DLL)
ifeq ($(BUILD_TYPE), so)
_targ_out := $(_out_dir)$(_so_pfx)$(BUILD_BASENAME)$(_so_ext)
_temp := $(dir $(_targ_out))$(_lib_pfx)$(_so_pfx)$(BUILD_BASENAME)
_msw_import_lib := $(_temp)$(_lib_ext) $(_temp)$(_exp_ext)
_link_cmd := link.exe /DLL $(_mvc_obj_files) $(_lnk_flags) /OUT:$(subst /,\,$(_targ_out))
endif # lib

endif # msvc


################################
# 3e. POST-PROCESS / CLEANING
################################

# Create list of directories to create, including
# output and object tree structure. Below, we sort and remove
# duplicates generated from the source list, then filter to
# leave only NON-EXISTING paths.
_temp := $(_src_files) $(_res_files)
_temp := $(_temp:%=$(_obj_dir)%)
_mkdir_objs := $(sort $(dir $(_temp)))

# Filter
_temp := $(wildcard $(_mkdir_objs))
_mkdir_objs := $(filter-out $(_temp), $(_mkdir_objs))

# Output to make
_temp := $(wildcard $(_out_dir))
_mkdir_output := $(filter-out $(_temp), $(_out_dir))

# Set clean object files that exist
_clean_objs := $(wildcard $(_obj_files))

# Clean existing output files, provided we are not
# using file list supplied over command line
ifndef SRCS
_clean_output := $(wildcard $(_targ_out) $(_msw_import_lib))
endif

##################################################
# 4. TOP LEVEL GOALS
##################################################

################################
# COMPILE AND LINK
################################

# ALL
.PHONY:all
all: impl_header_out impl_error_check impl_make_recursion $(_dep_makes) impl_submod_out \
makedirs prebuild impl_premaking_leader $(_obj_files) impl_postmaking_msg impl_linker postbuild

# COMPILE
# Does not link, or perform pre-build or post-build steps. Make obj directories only.
.PHONY:compile
compile: impl_header_out impl_error_check impl_make_recursion $(_dep_makes) impl_submod_out \
impl_mkdir_leader impl_mkdir_objs impl_postmkdir_msg impl_premaking_leader $(_obj_files) \
impl_postmaking_msg

# LINK
# Does not perform pre-build or post-build steps
.PHONY:link
link: impl_header_out impl_error_check impl_make_recursion $(_dep_makes) impl_submod_out \
impl_mkdir_output impl_linker

# REBUILD
.PHONY:rebuild
rebuild: clean all

################################
# CLEANING
################################

# CLEAN
.PHONY:clean
clean: impl_header_out impl_error_check impl_make_recursion $(_dep_makes) impl_submod_out \
impl_clean_leader impl_clean_objs impl_clean_output impl_postclean_msg

# MOSTLYCLEAN
# Does not clean output.
.PHONY:mostlyclean
clean: impl_header_out impl_error_check impl_make_recursion $(_dep_makes) impl_submod_out \
impl_clean_leader impl_clean_objs impl_postclean_msg

################################
# CREATE DIRECTORIES
################################

# MAKEDIRS
.PHONY:makedirs
makedirs: impl_header_out impl_error_check impl_make_recursion $(_dep_makes) impl_submod_out \
impl_mkdir_leader impl_mkdir_objs impl_mkdir_output impl_mkdir_custom impl_postmkdir_msg

################################
# BUILD STEPS
################################

# PREBUILD
.PHONY:prebuild
prebuild: impl_header_out impl_error_check impl_make_recursion impl_submod_out
ifdef _shell_prebuild
	@echo $(_shqt)PRE-BUILD STEP ...$(_shqt)
	$(_shell_prebuild)
	@$(_shell_feed)
endif #_prebuild_info

# POSTBUILD
.PHONY:postbuild
postbuild: impl_header_out impl_error_check impl_make_recursion impl_submod_out
ifdef _shell_postbuild
	@echo $(_shqt)POST-BUILD STEP ...$(_shqt)
	$(_shell_postbuild)
	@$(_shell_feed)
endif # _shell_postbuild

################################
# CREATE DISTRO
################################

# DIST
.PHONY:dist
dist: all
	@echo $(_shqt)BUILD DISTRIBUTION ...$(_shqt)
ifdef _shell_distbuild
	$(_shell_distbuild)
else
	@echo $(_shqt)None$(_shqt)
endif # _distbuild_info
	@$(_shell_feed)

################################
# RUN
################################

# RUN
.PHONY:run
run: impl_header_out impl_error_check impl_submod_out
	@echo $(_shqt)RUNNING BINARY ...$(_shqt)
	@echo $(_shqt)$(_targ_out) $(OPTS)$(_shqt)
ifneq ($(wildcard $(_targ_out)),)
	-@$(_targ_out) $(OPTS)
else
	@echo $(_shqt)ERROR: The target file does not exist!$(_shqt)
endif # _targ_out
	@$(_shell_feed)

# DBG
.PHONY:dbg
dbg: impl_header_out impl_error_check impl_submod_out
	@echo $(_shqt)DEBUGGING BINARY ...$(_shqt)
	@echo $(_shqt)$(_debugger_exe) $(_targ_out) $(OPTS)$(_shqt)
ifneq ($(wildcard $(_targ_out)),)
	-@$(_debugger_exe) $(_targ_out) $(OPTS)
else
	@echo $(_shqt)ERROR: The target file does not exist!$(_shqt)
endif # _targ_out
	@$(_shell_feed)

################################
# LIST VARS
################################

# CHECKCONF
.PHONY: checkconf
checkconf: impl_header_out impl_error_check impl_make_recursion $(_dep_makes) impl_submod_out
ifndef CONF_ERROR
	@echo $(_shqt)Configuration OK$(_shqt)
else ifndef DEPCALL_FLAG
	@$(_shell_feed)
	@echo $(_shqt)Hint: Use "listvars" to help find the problem$(_shqt)
endif # CONF_ERROR

# LISTVARS
.PHONY: listvars
listvars: impl_header_out impl_error_check impl_submod_out
	@echo $(_shqt)COMMAND ARGS:$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  MAKE                  : $(MAKE)$(_shqt)
	@echo $(_shqt)  MAKECMDGOALS          : $(MAKECMDGOALS)$(_shqt)
	@echo $(_shqt)  CONF                  : $(CONF)$(_shqt)
	@echo $(_shqt)  COMP                  : $(COMP)$(_shqt)
	@echo $(_shqt)  TARG                  : $(TARG)$(_shqt)
	@echo $(_shqt)  ARCH                  : $(ARCH)$(_shqt)
	@echo $(_shqt)  CRT                   : $(CRT)$(_shqt)
	@echo $(_shqt)  OPTS                  : $(OPTS)$(_shqt)
	@echo $(_shqt)  SRCS                  : $(SRCS)$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)DMX CONSTANTS:$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  dmx_version           : $(dmx_version)$(_shqt)
	@echo $(_shqt)  make_root             : $(make_root)$(_shqt)
	@echo $(_shqt)  targ_build            : $(targ_build)$(_shqt)
	@echo $(_shqt)  abbr_build            : $(abbr_build)$(_shqt)
	@echo $(_shqt)  targ_arch             : $(targ_arch)$(_shqt)
	@echo $(_shqt)  targ_xarch            : $(targ_xarch)$(_shqt)
	@echo $(_shqt)  targ_crt              : $(targ_crt)$(_shqt)
	@echo $(_shqt)  ms_crt                : $(ms_crt)$(_shqt)
	@echo $(_shqt)  sys_arch              : $(sys_arch)$(_shqt)
	@echo $(_shqt)  sys_os                : $(sys_os)$(_shqt)
	@echo $(_shqt)  sys_vos               : $(sys_vos)$(_shqt)
	@echo $(_shqt)  sys_los               : $(sys_los)$(_shqt)
	@echo $(_shqt)  comp_id               : $(comp_id)$(_shqt)
	@echo $(_shqt)  comp_version          : $(comp_version)$(_shqt)
	@echo $(_shqt)  comp_major            : $(comp_major)$(_shqt)
	@echo $(_shqt)  comp_desc             : $(comp_desc)$(_shqt)
	@echo $(_shqt)  build_host            : $(build_host)$(_shqt)
	@echo $(_shqt)  build_date            : $(build_date)$(_shqt)
	@echo $(_shqt)  build_time            : $(build_time)$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)PROJECT CONFIGURATION:$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  BUILD_BASENAME        : $(BUILD_BASENAME)$(_shqt)
	@echo $(_shqt)  BUILD_TYPE            : $(BUILD_TYPE)$(_shqt)
	@echo $(_shqt)  ABOUT_NAME            : $(ABOUT_NAME)$(_shqt)
	@echo $(_shqt)  ABOUT_VERSION         : $(ABOUT_VERSION)$(_shqt)
	@echo $(_shqt)  ABOUT_VENDOR          : $(ABOUT_VENDOR)$(_shqt)
	@echo $(_shqt)  NIX_SONAME            : $(NIX_SONAME)$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)PROJECT DIRECTORIES:$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  SRC_ROOT              : $(SRC_ROOT)$(_shqt)
	@echo $(_shqt)  OUT_DIR               : $(OUT_DIR)$(_shqt)
	@echo $(_shqt)  OBJ_DIR               : $(OBJ_DIR)$(_shqt)
	@echo $(_shqt)  INC_COMMON_DIRS       : $(INC_COMMON_DIRS)$(_shqt)
	@echo $(_shqt)  INC_NIX_DIRS          : $(INC_NIX_DIRS)$(_shqt)
	@echo $(_shqt)  INC_WIN_DIRS          : $(INC_WIN_DIRS)$(_shqt)
	@echo $(_shqt)  CUSTOM_DIRS           : $(CUSTOM_DIRS)$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)SOURCE FILES:$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  SRC_COMMON_FILES      : $(SRC_COMMON_FILES)$(_shqt)
	@echo $(_shqt)  SRC_NIX_FILES         : $(SRC_NIX_FILES)$(_shqt)
	@echo $(_shqt)  SRC_WIN_FILES         : $(SRC_WIN_FILES)$(_shqt)
	@echo $(_shqt)  RC_WIN_FILES          : $(RC_WIN_FILES)$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)COMPILER OPTIONS:$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  MINGW64_PATH          : $(MINGW64_PATH)$(_shqt)
	@echo $(_shqt)  MINGW32_PATH          : $(MINGW32_PATH)$(_shqt)
	@echo $(_shqt)  MACRO_COMMON_DEFS     : $(MACRO_COMMON_DEFS)$(_shqt)
	@echo $(_shqt)  MACRO_GPP_DEFS        : $(MACRO_GPP_DEFS)$(_shqt)
	@echo $(_shqt)  MACRO_MINGW_DEFS      : $(MACRO_MINGW_DEFS)$(_shqt)
	@echo $(_shqt)  MACRO_MSVC_DEFS       : $(MACRO_MSVC_DEFS)$(_shqt)
	@echo $(_shqt)  EXTLIB_COMMON_DIRS    : $(EXTLIB_COMMON_DIRS)$(_shqt)
	@echo $(_shqt)  EXTLIB_GPP_DIRS       : $(EXTLIB_GPP_DIRS)$(_shqt)
	@echo $(_shqt)  EXTLIB_MINGW_DIRS     : $(EXTLIB_MINGW_DIRS)$(_shqt)
	@echo $(_shqt)  EXTLIB_MSVC_DIRS      : $(EXTLIB_MSVC_DIRS)$(_shqt)
	@echo $(_shqt)  EXTLIB_COMMON_NAMES   : $(EXTLIB_COMMON_NAMES)$(_shqt)
	@echo $(_shqt)  EXTLIB_GPP_NAMES      : $(EXTLIB_GPP_NAMES)$(_shqt)
	@echo $(_shqt)  EXTLIB_MINGW_NAMES    : $(EXTLIB_MINGW_NAMES)$(_shqt)
	@echo $(_shqt)  EXTLIB_MSVC_NAMES     : $(EXTLIB_MSVC_NAMES)$(_shqt)
	@echo $(_shqt)  CXX_GPP_REL_FLAGS     : $(CXX_GPP_REL_FLAGS)$(_shqt)
	@echo $(_shqt)  CXX_GPP_DBG_FLAGS     : $(CXX_GPP_DBG_FLAGS)$(_shqt)
	@echo $(_shqt)  CXX_MINGW_REL_FLAGS   : $(CXX_MINGW_REL_FLAGS)$(_shqt)
	@echo $(_shqt)  CXX_MINGW_DBG_FLAGS   : $(CXX_MINGW_DBG_FLAGS)$(_shqt)
	@echo $(_shqt)  CXX_MSVC_REL_FLAGS    : $(CXX_MSVC_REL_FLAGS)$(_shqt)
	@echo $(_shqt)  CXX_MSVC_DBG_FLAGS    : $(CXX_MSVC_DBG_FLAGS)$(_shqt)
	@echo $(_shqt)  LNK_GPP_REL_FLAGS     : $(LNK_GPP_REL_FLAGS)$(_shqt)
	@echo $(_shqt)  LNK_GPP_DBG_FLAGS     : $(LNK_GPP_DBG_FLAGS)$(_shqt)
	@echo $(_shqt)  LNK_MINGW_REL_FLAGS   : $(LNK_MINGW_REL_FLAGS)$(_shqt)
	@echo $(_shqt)  LNK_MINGW_DBG_FLAGS   : $(LNK_MINGW_DBG_FLAGS)$(_shqt)
	@echo $(_shqt)  LNK_MSVC_REL_FLAGS    : $(LNK_MSVC_REL_FLAGS)$(_shqt)
	@echo $(_shqt)  LNK_MSVC_DBG_FLAGS    : $(LNK_MSVC_DBG_FLAGS)$(_shqt)
	@echo $(_shqt)  RES_MINGW_REL_FLAGS   : $(RES_MINGW_REL_FLAGS)$(_shqt)
	@echo $(_shqt)  RES_MINGW_DBG_FLAGS   : $(RES_MINGW_DBG_FLAGS)$(_shqt)
	@echo $(_shqt)  RES_MSVC_REL_FLAGS    : $(RES_MSVC_REL_FLAGS)$(_shqt)
	@echo $(_shqt)  RES_MSVC_DBG_FLAGS    : $(RES_MSVC_DBG_FLAGS)$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)BUILD STEPS:$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  MAKECONF_DEPS         : $(MAKECONF_DEPS)$(_shqt)
	@echo $(_shqt)  PREBUILD_NIX          : $(PREBUILD_NIX)$(_shqt)
	@echo $(_shqt)  POSTBUILD_NIX         : $(POSTBUILD_NIX)$(_shqt)
	@echo $(_shqt)  DISTBUILD_NIX         : $(DISTBUILD_NIX)$(_shqt)
	@echo $(_shqt)  PREBUILD_WIN          : $(PREBUILD_WIN)$(_shqt)
	@echo $(_shqt)  POSTBUILD_WIN         : $(POSTBUILD_WIN)$(_shqt)
	@echo $(_shqt)  DISTBUILD_WIN         : $(DISTBUILD_WIN)$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  OUTPUT:               : $(_targ_out)$(_shqt)
	@$(_shell_feed)

# LISTVARSALL
.PHONY: listvarsall
listvarsall: listvars
	@echo $(_shqt)INTERNAL VARIABLES$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  MAKEFILE_LIST         : $(MAKEFILE_LIST)$(_shqt)
	@echo $(_shqt)  _make_filename        : $(_make_filename)$(_shqt)
	@echo $(_shqt)  _conf_path            : $(_conf_path)$(_shqt)
	@echo $(_shqt)  _timestamp            : $(_timestamp)$(_shqt)
	@echo $(_shqt)  _recursive_make       : $(_recursive_make)$(_shqt)
	@echo $(_shqt)  _perform_make_link    : $(_perform_make_link)$(_shqt)
	@echo $(_shqt)  _show_submod          : $(_show_submod)$(_shqt)
	@echo $(_shqt)  _multi_target         : $(_multi_target)$(_shqt)
	@echo $(_shqt)  _multi_arch           : $(_multi_arch)$(_shqt)
	@echo $(_shqt)  _multi_crt            : $(_multi_crt)$(_shqt)
	@echo $(_shqt)  _mkdir_objs           : $(_mkdir_objs)$(_shqt)
	@echo $(_shqt)  _mkdir_output         : $(_mkdir_output)$(_shqt)
	@echo $(_shqt)  _mkdir_custom         : $(_mkdir_custom)$(_shqt)
	@echo $(_shqt)  _src_files            : $(_src_files)$(_shqt)
	@echo $(_shqt)  _res_files            : $(_res_files)$(_shqt)
	@echo $(_shqt)  _obj_files            : $(_obj_files)$(_shqt)
	@echo $(_shqt)  _clean_objs           : $(_clean_objs)$(_shqt)
	@echo $(_shqt)  _clean_output         : $(_clean_output)$(_shqt)
	@echo $(_shqt)  _cxx_flags            : $(_cxx_flags)$(_shqt)
	@echo $(_shqt)  _res_flags            : $(_res_flags)$(_shqt)
	@echo $(_shqt)  _lnk_flags            : $(_lnk_flags)$(_shqt)
	@echo $(_shqt)  _compile_cmd          : $(_compile_cmd)$(_shqt)
	@echo $(_shqt)  _windres_cmd          : $(_windres_cmd)$(_shqt)
	@echo $(_shqt)  _link_cmd             : $(_link_cmd)$(_shqt)
	@echo $(_shqt)  _ranlib_cmd           : $(_ranlib_cmd)$(_shqt)
	@echo $(_shqt)  _msw_import_lib       : $(_msw_import_lib)$(_shqt)
	@echo $(_shqt)  _dep_makes            : $(_dep_makes)$(_shqt)
	@$(_shell_feed)

################################
# HELP AND VERSION
################################

# HELP
.PHONY:help
help:
	@$(_shell_feed)
	@echo $(_shqt)Usage: $(MAKE) -f makefile [GOALS] CONF=[makeconf] TARG=[release/debug/all]$(_shqt)
	@echo $(_shqt)       ARCH=[64/32/all] OPTS=[custom] SRCS=[files]$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)GOALS :$(_shqt)
	@echo $(_shqt)  all           - DEFAULT. Make and link the output. Calls pre and post-build steps.$(_shqt)
	@echo $(_shqt)  compile       - Make sources but does NOT link or call pre or post-build steps.$(_shqt)
	@echo $(_shqt)  link          - Link (or archive) object files, but does NOT call pre or$(_shqt)
	@echo $(_shqt)                  post-build steps.$(_shqt)
	@echo $(_shqt)  clean         - Clean intermediary object files and output binaries.$(_shqt)
	@echo $(_shqt)  mostlyclean   - Clean intermediary object files, but leave output binaries.$(_shqt)
	@echo $(_shqt)  rebuild       - Equivalent to: clean all.$(_shqt)
	@echo $(_shqt)  dist          - Make and link the output (same as all), then run the create$(_shqt)
	@echo $(_shqt)                  distribution shell script.$(_shqt)
	@echo $(_shqt)  makedirs      - Create object, output and custom directories, but do not compile.$(_shqt)
	@echo $(_shqt)  prebuild      - Perform the pre-build step only.$(_shqt)
	@echo $(_shqt)  postbuild     - Perform the post-build step only.$(_shqt)
	@echo $(_shqt)  run           - Execute the binary output. The OPTS value is used to supply$(_shqt)
	@echo $(_shqt)                  run arguments.$(_shqt)
	@echo $(_shqt)  dbg           - Execute the binary under the debugger. The OPTS value is used to$(_shqt)
	@echo $(_shqt)                  supply run arguments.$(_shqt)
	@echo $(_shqt)  checkconf     - Check the configuration file for errors, otherwise does nothing.$(_shqt)
	@echo $(_shqt)  listvars      - Output important configuration variables.$(_shqt)
	@echo $(_shqt)  listvarsall   - Output all configuration variables, plus internal variables.$(_shqt)
	@echo $(_shqt)  help          - Display usage options.$(_shqt)
	@echo $(_shqt)  version       - Display $(dmx_name) version.$(_shqt)
	@echo $(_shqt)  about         - Display $(dmx_name) about information.$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)TARGET VARIABLES :$(_shqt)
	@echo $(_shqt)  CONF : The make configuration filename. If omitted, defaults to: "make-main.conf".$(_shqt)
	@echo $(_shqt)  Only, a single value can be supplied, but multiple configurations can be built$(_shqt)
	@echo $(_shqt)  by creating a "master" project with multiple dependencies.$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  TARG : Build target as either "release" or "debug", or a case variation of.$(_shqt)
	@echo $(_shqt)  Use "all" to build both. The default value is "debug".$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  COMP : Compiler tool chain. Specify "mingw", "gpp" or "msvc". Under Windows, "gpp"$(_shqt)
	@echo $(_shqt)  and "mingw" are equivalent. Ignored under LINUX as always "gpp".$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  ARCH : Target architecture, either "32" or "64". Use "all" to build both. The$(_shqt)
	@echo $(_shqt)  default is that of the build machine. Although the bit architecture will usually$(_shqt)
	@echo $(_shqt)  be detected automatically from the build machine, it may be useful to specify$(_shqt)
	@echo $(_shqt)  it explicitly for projects targeting multiple architectures. The value will$(_shqt)
	@echo $(_shqt)  automatically be supplied to the compiler using the -m64 and -m32 options.$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  CRT : The C runtime library, either "dynamic" or "static". Use "all" to build for$(_shqt)
	@echo $(_shqt)  both. The default is dynamic.$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  OPTS : Custom options used to select additional custom configuration sections$(_shqt)
	@echo $(_shqt)  within a conf file. They are passed during recursive make calls and when calling$(_shqt)
	@echo $(_shqt)  dependencies. Additionally, they are supplied as the command arguments when$(_shqt)
	@echo $(_shqt)  launching an output binary using the "run" or "dbg" goal.$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)  SRCS : Specific source file(s) to make. Used only with the "compile" command.$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)EXAMPLES :$(_shqt)
	@echo $(_shqt)  make all$(_shqt)
	@echo $(_shqt)  make all CONF=makelib.conf TARG=debug ARCH=64$(_shqt)
	@echo $(_shqt)  mingw32-make rebuild CONF=makeapp.conf COMP=msvc CRT=static OPTS="trace test"$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)See "makefile.readme" for further information.$(_shqt)
	@$(_shell_feed)

# VERSION
.PHONY:version
version:
	@echo $(_shqt)$(dmx_version)$(_shqt)

# ABOUT
.PHONY:about
about:
	@$(_shell_feed)
	@echo $(_shqt)$(dmx_name) $(dmx_version)$(_shqt)
	@echo $(_shqt)$(dmx_description)$(_shqt)
	@echo $(_shqt)$(dmx_copyright)$(_shqt)
	@$(_shell_feed)
	@echo $(_shqt)TOOLCHAIN: $(comp_desc)$(_shqt)


##################################################
# 5. INTERNAL IMPLEMENTATION RULES
##################################################

# Nothing done messages we output when nothing to do.
# We clear these, using a hack, in the implicit build rules.
# This was found to be the only way of getting the feature to
# work as expected, as it is difficult to share data out
# from a rule. For some reason checking the variable (using ifeq)
# does not provide the same result as when we echo to screen.
_mkdirs_nothing_msg := Already exist
_clean_nothing_msg := Nothing to clean
_makefiles_nothing_msg := Nothing to be done

# Perform make, link and clean?
ifndef CONF_ERROR
ifndef _recursive_make
ifneq ($(BUILD_TYPE), mst)
_perform_make_link := 1
endif # !BUILD_TYPE mst
endif # !_recursive_make
endif # !CONF_ERROR

################################
# HEADERS
################################

# Logic - show sub-module
ifndef CONF_ERROR
ifndef _recursive_make
_show_submod := $(strip $(_perform_make_link)$(CUSTOM_DIRS)$(_shell_distbuild))
endif # !_recursive_make
endif # !CONF_ERROR

_submod_spacer := $(space)
ifeq ($(targ_build),debug)
_submod_spacer := $(space)$(space)$(space)
endif

# Write header and quit if configuration error was detected
.PHONY:impl_header_out
impl_header_out:
ifndef DEPCALL_FLAG
	@$(_shell_feed)
	@echo $(_shqt)=======================================================$(_shqt)
	@echo $(_shqt)PROJECT    : $(BUILD_BASENAME)$(_shqt)
ifdef ABOUT_VERSION
	@echo $(_shqt)VERSION    : $(ABOUT_VERSION)$(_shqt)
endif
	@echo $(_shqt)TOOLCHAIN  : $(comp_desc)$(_shqt)
	@echo $(_shqt)SYSTEM OS  : $(call to-uppercase,$(sys_los)) $(sys_arch)-bit$(_shqt)
	@echo $(_shqt)=======================================================$(_shqt)
	@$(_shell_feed)
endif # !DEPCALL_FLAG

# Sub-module header
.PHONY:impl_submod_out
impl_submod_out:
ifdef _show_submod
	@$(_shell_feed)
	@echo $(_shqt)-------------------------------------------------------$(_shqt)
ifeq ($(BUILD_TYPE), mst)
	@echo $(_shqt)$(call to-uppercase,$(targ_build))-$(targ_arch)\
$(_submod_spacer): MASTER$(_shqt)
else
	@echo $(_shqt)$(call to-uppercase,$(targ_build))-$(targ_arch)\
$(_submod_spacer): $(notdir $(_targ_out))$(_shqt)
endif # BUILD_TYPE
	@echo $(_shqt)CONF FILE  : $(CONF)$(_shqt)
	@echo $(_shqt)C-RUNTIME  : $(targ_crt)$(_shqt)
	@echo $(_shqt)-------------------------------------------------------$(_shqt)
	@$(_shell_feed)
endif # _show_submod

################################
# ERROR CHECK
################################

# Warning
.PHONY:impl_error_check
impl_error_check:
ifdef CONF_WARN
	@echo $(_shqt)WARNING: $(CONF_WARN)$(_shqt)
	@$(_shell_feed)
endif # CONF_WARN

# Output error and quit
ifdef CONF_ERROR
	@echo $(_shqt)ERROR: $(CONF_ERROR)$(_shqt)
ifdef _error_info
	@echo $(_shqt)$(_error_info)$(_shqt)
endif # _error_info
	@$(_shell_feed)
# Allow to continue only if a diagnostic goal
ifneq ($(MAKECMDGOALS), listvars)
ifneq ($(MAKECMDGOALS), listvarsall)
ifneq ($(MAKECMDGOALS), checkconf)
	@exit 1
endif # checkconf
endif # listvarsall
endif # listvars
endif # CONF_ERROR

################################
# CREATE DIRECTORIES
################################

# Logic
_show_makedir_info := $(_perform_make_link)

ifndef _recursive_make
ifdef CUSTOM_DIRS
_show_makedir_info := 1
endif # CUSTOM_DIRS
endif # !_recursive_make

# Write action leader
.PHONY:impl_mkdir_leader
impl_mkdir_leader:
ifdef _show_makedir_info
	@echo $(_shqt)CREATE DIRS ...$(_shqt)
endif

# Write no action message
.PHONY:impl_postmkdir_msg
impl_postmkdir_msg:
ifdef _show_makedir_info
	@echo $(_shqt)$(_mkdirs_nothing_msg)$(_shqt)
	@$(_shell_feed)
endif

# Make object directories
# The directory variable will already be
# filtered for those that do not exist.
# NB. Clear _mkdirs_nothing_msg on invocation.
.PHONY:impl_mkdir_custom
impl_mkdir_custom:
ifndef _recursive_make
ifneq ($(strip $(_mkdir_custom)),)
	-$(call _shell_md, $(_mkdir_custom))
	$(eval _mkdirs_nothing_msg := $(_null_out))
endif # !strip _mkdir_custom
endif # !_recursive_make

.PHONY:impl_mkdir_objs
impl_mkdir_objs:
ifdef _perform_make_link
ifneq ($(strip $(_mkdir_objs)),)
	-$(call _shell_md, $(_mkdir_objs))
	$(eval _mkdirs_nothing_msg := $(_null_out))
endif # _mkdir_objs
endif # _perform_makedirs

# Make output and custom directories
.PHONY:impl_mkdir_output
impl_mkdir_output:
ifdef _perform_make_link
ifneq ($(strip $(_mkdir_output)),)
	-$(call _shell_md, $(_mkdir_output))
	$(eval _mkdirs_nothing_msg := $(_null_out))
endif # !strip _mkdir_output
endif # _perform_make_link

################################
# CLEAN IMPLEMENTATION
################################

# Write action leader
.PHONY:impl_clean_leader
impl_clean_leader:
ifdef _perform_make_link
	@echo $(_shqt)CLEANING FILES ...$(_shqt)
endif

# Write no action message
.PHONY:impl_postclean_msg
impl_postclean_msg:
ifdef _perform_make_link
	@echo $(_shqt)$(_clean_nothing_msg)$(_shqt)
	@$(_shell_feed)
endif

# Clean object directories
# The clean files variable will already be
# filtered for those that exist.
# NB. Clear _clean_nothing_msg on invocation.
.PHONY:impl_clean_objs
impl_clean_objs:
ifdef _perform_make_link
ifneq ($(strip $(_clean_objs)),)
	@echo $(_shqt)$(call _shell_rm, $(_clean_objs))$(_shqt)
	-@$(call _shell_rm, $(_clean_objs))
	$(eval _clean_nothing_msg := $(_null_out))
endif # _clean_objs
endif # _perform_make_link

# Clean output directory
# NB. Clear _clean_nothing_msg on invocation
.PHONY:impl_clean_output
impl_clean_output:
ifdef _perform_make_link
ifneq ($(_clean_output),)
	@echo $(_shqt)$(call _shell_rm, $(_clean_output))$(_shqt)
	-@$(call _shell_rm, $(_clean_output))
	$(eval _clean_nothing_msg := $(_null_out))
endif # _clean_output
endif # _perform_make_link

################################
# MAKE MESSAGE
################################

# Write action leader
.PHONY:impl_premaking_leader
impl_premaking_leader:
ifdef _perform_make_link
	@echo $(_shqt)MAKING FILES ...$(_shqt)
endif

# Write no action message
.PHONY:impl_postmaking_msg
impl_postmaking_msg:
ifdef _perform_make_link
	@echo $(_shqt)$(_makefiles_nothing_msg)$(_shqt)
	@$(_shell_feed)
endif

################################
# OUTPUT MESSAGE
################################

# Link output
.PHONY:impl_linker
impl_linker:
ifdef _perform_make_link
	@echo $(_shqt)OUTPUT: $(_targ_out)$(_shqt)
	$(_link_cmd)
ifdef _ranlib_cmd
	$(_ranlib_cmd)
endif # _ranlib_cmd
	@$(_shell_feed)
endif # _perform_make_link


################################
# RECURSIVE MAKES
################################

# Implement multiple TARG or ARCH is builds
.PHONY:impl_make_recursion
impl_make_recursion:
ifdef _multi_target
	@$(MAKE) --no-print-directory -f $(_make_filename) $(MAKECMDGOALS) CONF=$(CONF) TARG=debug \
ARCH=$(ARCH) CRT=$(CRT) OPTS=$(OPTS) SRCS=$(SRCS) DEPCALL_FLAG=1
	@$(MAKE) --no-print-directory -f $(_make_filename) $(MAKECMDGOALS) CONF=$(CONF) TARG=release \
ARCH=$(ARCH) CRT=$(CRT) OPTS=$(OPTS) SRCS=$(SRCS) DEPCALL_FLAG=1
endif # _multi_target

ifdef _multi_arch
ifndef _multi_target
	@$(MAKE) --no-print-directory -f $(_make_filename) $(MAKECMDGOALS) CONF=$(CONF) TARG=$(TARG) \
ARCH=32 CRT=$(CRT) OPTS=$(OPTS) SRCS=$(SRCS) DEPCALL_FLAG=1
	@$(MAKE) --no-print-directory -f $(_make_filename) $(MAKECMDGOALS) CONF=$(CONF) TARG=$(TARG) \
ARCH=64 CRT=$(CRT) OPTS=$(OPTS) SRCS=$(SRCS) DEPCALL_FLAG=1
endif # !_multi_target
endif # _multi_arch

ifdef _multi_crt
ifndef _multi_target
ifndef _multi_arch
	@$(MAKE) --no-print-directory -f $(_make_filename) $(MAKECMDGOALS) CONF=$(CONF) TARG=$(TARG) \
ARCH=$(ARCH) CRT=dynamic OPTS=$(OPTS) SRCS=$(SRCS) DEPCALL_FLAG=1
	@$(MAKE) --no-print-directory -f $(_make_filename) $(MAKECMDGOALS) CONF=$(CONF) TARG=$(TARG) \
ARCH=$(ARCH) CRT=static OPTS=$(OPTS) SRCS=$(SRCS) DEPCALL_FLAG=1
endif # !_multi_crt
endif # !_multi_target
endif # _multi_arch

# Done OK
ifdef _recursive_make
	@exit 0
endif

##################################################
# 7. IMPLICIT BUILD RULES
##################################################

# Object rule.
# NB. Clear _makefiles_nothing_msg on invocation
$(_obj_dir)%$(_obj_fext): $(_src_root)%
ifdef _perform_make_link
	$(_compile_cmd)$(call _to-wpath,$@) $(call _to-wpath,$(_src_root)$*)
	$(eval _makefiles_nothing_msg := $(_null_out))
endif # _perform_make_link

# Resource rule
# NB. Clear _makefiles_nothing_msg on invocation
$(_obj_dir)%$(_res_fext): $(_src_root)%
ifdef _perform_make_link
ifdef _windres_cmd
	$(_windres_cmd)$(call _to-wpath,$@) $(call _to-wpath,$(_src_root)$*)
	$(eval _makefiles_nothing_msg := $(_null_out))
endif # _windres_cmd
endif # _perform_make_link

# Call dependencies
%$(_dep_dummy_fext): %
ifndef CONF_ERROR
ifndef _recursive_make
	@$(MAKE) --no-print-directory -f $(_make_filename) $(MAKECMDGOALS) CONF=$* TARG=$(TARG) \
ARCH=$(ARCH) CRT=$(CRT) OPTS=$(OPTS) SRCS=$(SRCS) DEPCALL_FLAG=1
endif # !_recursive_make
endif # !CONF_ERROR

#############################################################################
# EOF
#############################################################################
