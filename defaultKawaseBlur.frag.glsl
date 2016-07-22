#include "include/common.glsl"
#include "include/uniforms.glsl"
#include "include/kawase.glsl"

qf_varying vec2 v_TexCoord;

uniform sampler2D u_BaseTexture;

void main(void)
{
	qf_FragColor = vec4(KawaseBlurFilter(u_BaseTexture, v_TexCoord, u_TextureParams.xy, u_TextureParams.z), 1.0);
	//qf_FragColor = qf_texture(u_BaseTexture, v_TexCoord);
}
