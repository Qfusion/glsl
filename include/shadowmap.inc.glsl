#include "rgbdepth.glsl"

// the following code is built around by Lee 'eihrul' Salzman
// shadowmapping enhancements by Lee 'eihrul' Salzman\n

#ifdef APPLY_SHADOW_SAMPLERS
# define dshadow2D(t,v) float(qf_shadow(t,v))
#else
# ifdef APPLY_RGB_SHADOW_24BIT
#  define dshadow2D(t,v) step(v.z, decodedepthmacro24(qf_texture(t, v.xy)))
# else
#  define dshadow2D(t,v) step(v.z, decodedepthmacro16(qf_texture(t, v.xy)))
# endif
#endif

// the following function comes from darkplaces source code
// authored by Forest 'LordHavoc' Hale along with Lee 'eihrul' Salzman
vec3 GetShadowMapTC2D(in vec3 dir, in vec4 params)
{
	vec3 adir = abs(dir);
	float m; vec4 proj;
	if (adir.x > adir.y) { m = adir.x; proj = vec4(dir.zyx, 0.5); } else { m = adir.y; proj = vec4(dir.xzy, 1.5); }
	if (adir.z > m) { m = adir.z; proj = vec4(dir, 2.5); }
	vec2 mparams = params.xy / m;
	return vec3(proj.xy * mparams.x + vec2(proj.z < 0.0 ? 1.5 : 0.5, proj.w) * params.z, mparams.y + params.w);
}

myhalf ShadowmapFilter(in SHADOW_SAMPLER shadowmapTex, in vec3 shadowmaptc, in vec2 shadowmapScale)
{
	float f;

	# define texval(tc) dshadow2D(shadowmapTex, vec3(tc, shadowmaptc.z))
	# define texval_off(off) dshadow2D(shadowmapTex, vec3((shadowmaptc.xy + off)*shadowmapScale.xy, shadowmaptc.z))

#ifdef APPLY_SHADOW_DITHER

# ifdef APPLY_SHADOW_PCF

	// this method can be described as a 'dithered pinwheel' (4 texture lookups)
	// which is a combination of the 'pinwheel' filter suggested by eihrul and dithered 4x4 PCF,
	// described here: http://http.developer.nvidia.com/GPUGems/gpugems_ch11.html 

	vec2 offset_dither = mod(floor(gl_FragCoord.xy), 2.0);
	offset_dither.y += offset_dither.x;  // y ^= x in floating point
	offset_dither.y *= step(offset_dither.y, 1.1);

	float group1 = texval_off(offset_dither.xy + vec2(-0.4,  1.0));
	float group2 = texval_off(offset_dither.xy + vec2(-1.0, -0.4));
	float group3 = texval_off(offset_dither.xy + vec2( 0.4, -1.0));
	float group4 = texval_off(offset_dither.xy + vec2( 1.0,  0.4));

	f = dot(vec4(0.25), vec4(group1, group2, group3, group4));
	# else
	f = texval(shadowmaptc.xy * shadowmapScale.xy);
	# endif // APPLY_SHADOW_PCF

#else

	// an essay by eihrul:
	// now think of bilinear filtering as a 1x1 weighted box filter
	// that is, it's sampling over a 2x2 area, but only collecting the portion of each pixel it actually steps on
	// with a linear shadowmap filter, you are getting that, like normal bilinear sampling
	// only its doing the shadowmap test on each pixel first, to generate a new little 2x2 area, then its doing
	// the bilinear filtering on that
	// so now if you consider your 2x2 filter you have
	// each of those taps is actually using linear filtering as you've configured it
	// so you are literally sampling almost 16 pixels as is and all you are getting for it is 2x2
	// the trick is to realize that in essence you could instead be sampling a 4x4 area of pixels
	// and running a 3x3 weighted box filter on it
	// but you would need some way to get the shadowmap to simply return the 4 pixels covered by each
	// tap, rather than the filtered result
	// which is what the ARB_texture_gather extension is for
	// NOTE: we're using emulation of texture_gather now

# ifdef APPLY_SHADOW_PCF

#  ifdef APPLY_SHADOW_SAMPLERS
	vec2 offset = fract(shadowmaptc.xy - 0.5);
	vec4 size = vec4(offset + 1.0, 2.0 - offset);
#   if APPLY_SHADOW_PCF > 1
	vec2 center = (shadowmaptc.xy - offset + 0.5)*shadowmapScale.xy;
	vec4 weight = (vec4(-1.5, -1.5, 2.0, 2.0) + (shadowmaptc.xy - 0.5*offset).xyxy)*shadowmapScale.xyxy;
	f = (1.0/25.0)*dot(size.zxzx*size.wwyy, vec4(texval(weight.xy), texval(weight.zy), texval(weight.xw), texval(weight.zw))) +
		(2.0/25.0)*dot(size, vec4(texval(vec2(weight.z, center.y)), texval(vec2(center.x, weight.w)), texval(vec2(weight.x, center.y)), texval(vec2(center.x, weight.y)))) +
		(4.0/25.0)*texval(center);
#   else
	vec4 weight = (vec4(2.0 - 1.0 / size.xy, 1.0 / size.zw - 1.0) + (shadowmaptc.xy - offset).xyxy)*shadowmapScale.xyxy;
	f = (1.0/9.0)*dot(size.zxzx*size.wwyy, vec4(texval(weight.zw), texval(weight.xw), texval(weight.zy), texval(weight.xy)));
#   endif
#  else
	vec2 origin = floor(shadowmaptc.xy) * shadowmapScale.xy;
	vec4 offsets = shadowmapScale.xyxy * vec4(-0.5, -0.5, 0.5, 0.5);
	float texNN = texval(origin + offsets.xy);
	float texPN = texval(origin + offsets.zy);
	float texNP = texval(origin + offsets.xw);
	float texPP = texval(origin + offsets.zw);
	vec2 mixFactors = fract(shadowmaptc.xy);
	f = mix(mix(texNN, texPN, mixFactors.x), mix(texNP, texPP, mixFactors.x), mixFactors.y);
#  endif // APPLY_SHADOW_SAMPLERS

# else
	f = texval(shadowmaptc.xy*shadowmapScale.xy);
# endif // APPLY_SHADOW_PCF

#endif // APPLY_SHADOW_DITHER

	# undef texval
	# undef texval_off

	return f;
}

float ShadowmapCascadedBlendFrac(in vec3 tc) 
{
	if (u_ShadowmapCascadesBlendArea < 0.01) {
		return 1.0;
	}
	return min(min(1.0f - tc.x, 1.0f - tc.y), min(tc.x, tc.y)) / u_ShadowmapCascadesBlendArea;
}

#define shadowtex(tex) ShadowmapFilter(shadowmapTex, tex + vec3(texscale.zw, 0.0f), texscale.xy)

myhalf ShadowmapOrthoFilter(in SHADOW_SAMPLER shadowmapTex, in mat4 shadowMatrix, in vec4 pos, in vec4 texscale, in vec4 params) 
{
	myhalf f;
	vec2 pad = params.xy;
	vec3 shadowmaptc = vec3(shadowMatrix * pos);

	if (min(shadowmaptc.x, shadowmaptc.y) < pad.x || max(shadowmaptc.x, shadowmaptc.y) > pad.y) {
		discard;
	}
	if (shadowmaptc.z < 0.0 || shadowmaptc.z > 1.0) {
		discard;
	}

	f = shadowtex(shadowmaptc);

	return f;
}

myhalf ShadowmapOrthoFilterCSM(in SHADOW_SAMPLER shadowmapTex, int numCascades, in mat4 cascadeMatrix[MAX_SHADOW_CASCADES], in vec4 pos, in out myhalf3 Color, in vec4 texscale, in vec4 params) 
{
	myhalf f;
	myhalf3 cascadeColors[MAX_SHADOW_CASCADES] = myhalf3[](
		myhalf3(1.5f, 0.0f, 0.0f),
		myhalf3(0.0f, 1.5f, 0.0f),
		myhalf3(0.0f, 0.0f, 5.5f),
		myhalf3(1.5f, 0.0f, 5.5f)
	);
	int cascadeIndex = -1;
	vec2 pad = params.xy;
	vec3 shadowmaptc = vec3(-1.0);

	numCascades = min(numCascades, MAX_SHADOW_CASCADES);
	for (int i = 0; i < numCascades && cascadeIndex < 0; i++) {
		shadowmaptc = vec3(cascadeMatrix[i] * pos);
		if (shadowmaptc.z > 0.0 && shadowmaptc.z < 1.0) {
			if (min(shadowmaptc.x, shadowmaptc.y) > pad.x && max(shadowmaptc.x, shadowmaptc.y) < pad.y) {
				cascadeIndex = i;
				Color = mix(Color, cascadeColors[i], params.w);
			}
		}
	}

	if (cascadeIndex < 0 || shadowmaptc.z < 0.0 || shadowmaptc.z > 1.0) {
		discard;
	}

	float frac = ShadowmapCascadedBlendFrac(shadowmaptc / params.z);
	if (cascadeIndex < numCascades - 1 && frac < 1.0f) {
		vec3 shadowmaptc2 = vec3(cascadeMatrix[cascadeIndex+1] * pos);

		shadowmaptc.x += float(cascadeIndex) * params.z;
		shadowmaptc2.x += float(cascadeIndex+1) * params.z;

		myhalf shadow1 = shadowtex(shadowmaptc);
		myhalf shadow2 = shadowtex(shadowmaptc2);

		frac = 1.0f - frac;
		f = mix(shadow1, shadow2, frac);
		Color = mix(Color, cascadeColors[cascadeIndex+1], frac * params.w);
	} else {
		shadowmaptc.x += float(cascadeIndex) * params.z;
		f = shadowtex(shadowmaptc);
	}

	return f;
}

#undef shadowtex
