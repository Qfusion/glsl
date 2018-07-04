myhalf3 DynamicLightsColor(in vec4 Position, in myhalf3 surfaceNormalModelspace)
{
	myhalf3 dir;
	myhalf3 Color = myhalf3(u_DlightDiffuseAndInvRadius.xyz);
	vec3 cubeVec;

#if defined(APPLY_DLIGHT_DIRECTIONAL)
	dir = myhalf3(u_DlightVector);
#else
	dir = myhalf3(u_DlightVector - Position.xyz);
#endif

	myhalf scale = myhalf(dot(dir, surfaceNormalModelspace));
	if( scale <= 0.0 ) {
		discard;
	}

#if !defined(APPLY_DLIGHT_DIRECTIONAL)
	myhalf dist = myhalf(length(dir));
	myhalf falloff = myhalf(1.0) - dist * u_DlightDiffuseAndInvRadius.w;

	falloff = clamp(falloff, 0.0, 1.0);
	falloff *= falloff;

	scale *= myhalf(1.0) / dist; // norm the dot product with surface normal
	scale *= falloff;
#endif

#ifdef APPLY_REALTIME_SHADOWS
	vec3 shadowmaptc;

#ifdef APPLY_DLIGHT_DIRECTIONAL
	myhalf3 cascadeColors[MAX_SHADOW_CASCADES] = {
		myhalf3(1.5f, 0.0f, 0.0f),
		myhalf3(0.0f, 1.5f, 0.0f),
		myhalf3(0.0f, 0.0f, 5.5f),
		myhalf3(1.5f, 0.0f, 5.5f)
	};
	bool foundTc = false;
	vec2 offsetTc = vec2(0.0);
	vec2 pad = u_DlightShadowmapParams.xy;

	shadowmaptc = vec3(-1.0);

	int numCascades = min(u_DlightShadowmapNumCascades, MAX_SHADOW_CASCADES);
	for (uint i = 0; i < numCascades && !foundTc; i++) {
		vec3 base = vec3(u_DlightShadowmapCascadeMatrix[i] * Position);

		if (base.z > 0.0 && base.z < 1.0) {
			if (min(base.x, base.y) > pad.x && max(base.x, base.y) < pad.y) {
				foundTc = true;
				shadowmaptc.xyz = vec3(base.xy + offsetTc, base.z);
				Color = mix(Color, cascadeColors[i], u_DlightShadowmapParams.w);
			}
		}
		offsetTc.x += u_DlightShadowmapParams.z;
	}

	if( shadowmaptc.z < 0.0 || shadowmaptc.z > 1.0 ) {
		discard;
	}
#else
	cubeVec = vec3(u_DlightMatrix * Position);
	shadowmaptc = GetShadowMapTC2D(cubeVec, u_DlightShadowmapParams);
#endif

	scale *= ShadowmapFilter(u_ShadowmapTexture, shadowmaptc + vec3(u_DlightShadowmapTextureScale.zw, 0.0f), u_DlightShadowmapTextureScale.xy);
#else

#ifdef APPLY_DLIGHT_CUBEFILTER
	cubeVec = vec3(u_DlightMatrix * Position);
#endif

#endif

	Color *= scale;

#ifdef APPLY_DLIGHT_CUBEFILTER
	Color *= myhalf3(qf_textureCube(u_CubeFilter, cubeVec));
#endif

	return Color;
}
