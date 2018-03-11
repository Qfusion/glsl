#include "include/common.glsl"
#include "include/uniforms.glsl"
#include "include/rgbdepth.glsl"

#if !defined(APPLY_SHADOW_SAMPLERS)
qf_varying float v_Depth;
#endif

#ifdef QF_ALPHATEST
uniform sampler2D u_BaseTexture;
qf_varying vec2 v_TexCoord;
#endif

void main(void)
{
#ifdef QF_ALPHATEST
	QF_ALPHATEST(myhalf4(qf_texture(u_BaseTexture, v_TexCoord)).a);
#endif

#if !defined(APPLY_SHADOW_SAMPLERS)
# if defined(APPLY_RGB_SHADOW_24BIT)
	qf_FragColor = encodedepthmacro24(v_Depth);
# else
	qf_FragColor = encodedepthmacro16(v_Depth);
# endif
#endif
}
