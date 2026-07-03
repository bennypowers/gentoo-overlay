"""Stub comfy_angle that delegates to system mesa EGL/GLESv2."""

import ctypes.util
from pathlib import Path


def get_lib_dir():
    egl = ctypes.util.find_library("EGL")
    if egl:
        resolved = Path("/usr/lib64") / egl
        if resolved.exists():
            return str(resolved.parent)
    return "/usr/lib64"


def get_egl_path():
    name = ctypes.util.find_library("EGL")
    return name or "libEGL.so.1"


def get_glesv2_path():
    name = ctypes.util.find_library("GLESv2")
    return name or "libGLESv2.so.2"
