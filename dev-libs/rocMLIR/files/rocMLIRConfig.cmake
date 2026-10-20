# Hand-authored package config for rocMLIR shared builds.
#
# Upstream's export machinery (export_target / rocm_export_targets,
# which generate this config and the rocMLIR::rockCompiler target) lives
# entirely inside the BUILD_FAT_LIBROCKCOMPILER branch; a shared-only
# build installs libraries and binaries but nothing find_package can
# consume. This config defines the equivalent INTERFACE target against
# the shared libraries until upstream exports shared builds natively.
#
# DROP when rocMLIR ships package configs for shared builds.

if(NOT TARGET rocMLIR::rockCompiler)
    get_filename_component(_rocMLIR_prefix "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)

    add_library(rocMLIR::rockCompiler INTERFACE IMPORTED)
    set_target_properties(rocMLIR::rockCompiler PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${_rocMLIR_prefix}/include/rocmlir"
        # The MIGraphX C API (mlirMIGraphX* pipelines, rocmlirMIXR* types,
        # mlirGetKernel*/mlirGetBinary) lives in libMLIRCAPIMIGraphX; its
        # NEEDED chain pulls the rest of the rock/MLIR libraries.
        INTERFACE_LINK_LIBRARIES "MLIRCAPIMIGraphX")
    unset(_rocMLIR_prefix)
endif()
