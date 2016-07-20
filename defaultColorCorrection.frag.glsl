#include "include/common.glsl"
#include "include/uniforms.glsl"

qf_varying vec2 v_TexCoord;

uniform sampler2D u_BaseTexture;

#ifdef APPLY_LUT
uniform sampler2D u_ColorLUT;
#endif

#ifdef APPLY_BLOOM
uniform sampler2D u_BloomTexture;
#endif

#ifdef APPLY_HDR

uniform myhalf u_HDRGamma;
uniform myhalf u_HDRExposure;

const float W = 0.90; // the white point

vec3 ACESFilm(vec3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    vec3 s = ((x*(a*x+b))/(x*(c*x+d)+e));
	return s;
}

vec3 ToneMap(vec3 c)
{
	return ACESFilm(c / 2.0) / ACESFilm(vec3(W) / 2.0);
}

#endif

#ifdef APPLY_LUT

vec3 ColorMap(vec3 c)
{
	vec3 coords = c;
	coords.rg = coords.rg * vec2(0.9375) + vec2(0.03125);
	coords *= vec3(1.0, 0.0625, 15.0);
	float blueMix = fract(coords.b);
	vec2 blueOffset = vec2(0.0, floor(coords.b) * 0.0625);
	vec3 color1 = qf_texture(u_ColorLUT, coords.rg + blueOffset).rgb;
	blueOffset.y = min(blueOffset.y + 0.0625, 0.9375);
	vec3 color2 = qf_texture(u_ColorLUT, coords.rg + blueOffset).rgb;
	coords = mix(color1, color2, blueMix);
	return coords;
}

#endif

void main(void)
{
	vec3 coords = qf_texture(u_BaseTexture, v_TexCoord).rgb;

#ifdef APPLY_HDR
	coords = ToneMap(coords * u_HDRExposure);
#endif

#ifdef APPLY_SRGB_COLORS

#ifdef APPLY_HDR
	coords = pow(coords, vec3(1.0 / u_HDRGamma));
#else
	coords = pow(coords, vec3(1.0 / 2.2));
#endif

#endif

#ifdef APPLY_OUT_BLOOM

	qf_FragColor = vec4(coords, 1.0);
	qf_BrightColor = vec4(coords.rgb - clamp(coords.rgb, 0.0, W), 1.0);
	
#else

#if defined(APPLY_LUT) && defined(APPLY_HDR)
	coords = clamp(coords, 0.0, 1.0);
#endif

#ifdef APPLY_LUT
	coords = ColorMap(coords);

#ifdef APPLY_BLOOM
	coords += ColorMap(qf_texture(u_BloomTexture, v_TexCoord).rgb);
#endif // APPLY_BLOOM

#else

#ifdef APPLY_BLOOM
	coords += qf_texture(u_BloomTexture, v_TexCoord).rgb * vec3(4.0);
#endif // APPLY_BLOOM

#endif // APPLY_LUT

	qf_FragColor = vec4(coords, 1.0);
#endif // APPLY_OUT_BLOOM
}
