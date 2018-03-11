#include_if(APPLY_REALTIME_SHADOWS) "shadowmap.inc.glsl"

#include "dlights_overload.glsl"

#define DLIGHTS_LIGHTBITS_IN
#include "dlights_overload.glsl"
