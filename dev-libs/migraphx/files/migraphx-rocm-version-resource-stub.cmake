# Gentoo's rocm-cmake (classic ROCmCMakeBuildTools) does not provide
# rocm_add_version_resource, which upstream rocm-cmake added later.
# The upstream implementation only generates a Windows .rc version
# resource and is a no-op on other platforms.
if(NOT COMMAND rocm_add_version_resource)
    function(rocm_add_version_resource TARGET NAME DESCRIPTION)
    endfunction()
endif()
