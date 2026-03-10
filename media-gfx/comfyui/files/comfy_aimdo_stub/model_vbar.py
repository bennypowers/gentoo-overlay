# Stub for non-CUDA systems
class ModelVBAR:
    def __init__(self, size, device_index): pass

def vbar_fault(v): return None
def vbar_signature_compare(sig, v): return False
def vbars_analyze(): return 0
def vbars_reset_watermark_limits(): pass
def vbar_unpin(v): pass
