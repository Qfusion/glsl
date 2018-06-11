myhalf3 DynamicLightsColor(in vec4 Position, in myhalf3 surfaceNormalModelspace)
{
	myhalf3 dir;
	myhalf3 Color = myhalf3(u_DlightDiffuseAndInvRadius.xyz);

#if defined(APPLY_DLIGHT_ORTHO)
	dir = myhalf3(u_DlightVector);
#else
	dir = myhalf3(u_DlightVector - Position.xyz);
#endif

	myhalf scale = myhalf(dot(dir, surfaceNormalModelspace));
	if( scale <= 0.0 ) {
		discard;
	}

#if !defined(APPLY_DLIGHT_ORTHO)
	myhalf dist = myhalf(length(dir));
	myhalf falloff = myhalf(1.0) - dist * u_DlightDiffuseAndInvRadius.w;

	falloff = clamp(falloff, 0.0, 1.0);
	falloff *= falloff;

	scale *= myhalf(1.0) / dist; // norm the dot product with surface normal
	scale *= falloff;
#endif

#if defined(APPLY_REALTIME_SHADOWS) || defined(APPLY_DLIGHT_CUBEFILTER)
	vec3 cubeVec = vec3(u_DlightMatrix * Position);
#endif

#ifdef APPLY_REALTIME_SHADOWS
	vec3 shadowmaptc;

#ifdef APPLY_DLIGHT_ORTHO
	shadowmaptc = cubeVec;

	shadowmaptc.xyz = shadowmaptc.xyz * 0.5 + vec3(0.5);
	if( shadowmaptc.z < 0.0 || shadowmaptc.z > 1.0 ) {
		discard;
	}
	float b05 = u_DlightShadowmapParams.z * 0.5 - u_DlightShadowmapParams.x;
	shadowmaptc.xy *= vec2(u_DlightShadowmapParams.zz);
	shadowmaptc.xy = min(vec2(u_DlightShadowmapParams.zz - vec2(b05)), shadowmaptc.xy);
	shadowmaptc.xy = max(vec2(b05), shadowmaptc.xy);
#else
	shadowmaptc = GetShadowMapTC2D(cubeVec, u_DlightShadowmapParams);
#endif

	scale *= ShadowmapFilter(u_ShadowmapTexture, shadowmaptc + vec3(u_DlightShadowmapTextureScale.zw, 0.0f), u_DlightShadowmapTextureScale.xy);
#endif

	Color *= scale;

#ifdef APPLY_DLIGHT_CUBEFILTER
	Color *= myhalf3(qf_textureCube(u_CubeFilter, cubeVec));
#endif

	return Color;
}
