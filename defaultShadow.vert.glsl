#include "include/common.glsl"
#include "include/uniforms.glsl"
#include "include/rgbdepth.glsl"
#include "include/attributes.glsl"

#if !defined(APPLY_SHADOW_SAMPLERS)
qf_varying float v_Depth;
#endif

#ifdef QF_ALPHATEST
qf_varying vec2 v_TexCoord;
#endif

void main(void)
{
	vec4 Position = a_Position;
	vec3 Normal = a_Normal.xyz;
	vec2 TexCoord = a_TexCoord;

	QF_TransformVerts(Position, Normal, TexCoord);
	
#ifdef QF_ALPHATEST
	v_TexCoord = TextureMatrix2x3Mul(u_TextureMatrix, TexCoord);
#endif

	gl_Position = u_ModelViewProjectionMatrix * Position;

#if !defined(APPLY_SHADOW_SAMPLERS)
	v_Depth = gl_Position.z;
#endif
}
